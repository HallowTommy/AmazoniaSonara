import Foundation
import AVFoundation
import Combine

@MainActor
final class AudioEngine: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var snapshot: SoundscapeSnapshot = .empty
    @Published private(set) var timerEnd: Date?
    @Published private(set) var timerProgress: Double = 0

    private let engine = AVAudioEngine()
    private var nodes: [SoundKey: AVAudioPlayerNode] = [:]
    private var buffers: [SoundKey: AVAudioPCMBuffer] = [:]
    private var journal: SoundscapeJournal?
    private var timerTask: Task<Void, Never>?

    init() {
        prepareNodes()
        attachAndConnect()
        prepareBuffers()
        print("[engine] init buffers loaded: \(buffers.count)/\(SoundKey.allCases.count)")
    }

    private func activateSessionIfNeeded() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])
        } catch {
            print("[engine] session error: \(error)")
        }
    }

    func bind(journal: SoundscapeJournal) async {
        self.journal = journal
        await refresh()
    }

    func refresh() async {
        guard let journal else { return }
        let next = await journal.snapshot()
        snapshot = next
        applyMix()
    }

    func toggle(_ key: SoundKey) async {
        guard let journal else { return }
        await journal.toggleSound(key)
        await refresh()
        ensurePlaybackForActiveSounds()
    }

    func setVolume(_ key: SoundKey, value: Float) async {
        guard let journal else { return }
        await journal.setVolume(key, value: value)
        await refresh()
        ensurePlaybackForActiveSounds()
    }

    func setMaster(_ value: Float) async {
        guard let journal else { return }
        await journal.setMasterVolume(value)
        await refresh()
    }

    func loadPreset(_ mix: SoundMix) async {
        guard let journal else {
            print("[engine] loadPreset: journal not bound yet")
            return
        }
        print("[engine] loadPreset: \(mix.name) active=\(mix.activeKeys.map { $0.rawValue })")
        await journal.loadPreset(mix)
        await refresh()
        ensurePlaybackForActiveSounds()
    }

    func playPause() {
        switch isPlaying {
        case true:
            stopAll()
        case false:
            ensurePlaybackForActiveSounds()
        }
    }

    func startTimer(minutes: Int, fade: Bool) {
        timerTask?.cancel()
        let totalSeconds = Double(minutes * 60)
        let end = Date().addingTimeInterval(totalSeconds)
        timerEnd = end
        timerProgress = 0
        ensurePlaybackForActiveSounds()
        timerTask = Task { [weak self] in
            guard let self else { return }
            let started = Date()
            while !Task.isCancelled {
                let elapsed = Date().timeIntervalSince(started)
                let progress = min(1, elapsed / totalSeconds)
                await MainActor.run { self.timerProgress = progress }
                if elapsed >= totalSeconds { break }
                let fadeWindow: TimeInterval = 30
                if fade, totalSeconds - elapsed <= fadeWindow {
                    let coef = max(0, (totalSeconds - elapsed) / fadeWindow)
                    await MainActor.run { self.applyFadeCoefficient(Float(coef)) }
                }
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
            await MainActor.run {
                self.stopAll()
                self.timerEnd = nil
                self.timerProgress = 0
                self.applyFadeCoefficient(1)
            }
        }
    }

    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
        timerEnd = nil
        timerProgress = 0
        applyFadeCoefficient(1)
    }

    private func prepareNodes() {
        for key in SoundKey.allCases {
            let node = AVAudioPlayerNode()
            nodes[key] = node
        }
    }

    private func attachAndConnect() {
        let mainMixer = engine.mainMixerNode
        for key in SoundKey.allCases {
            guard let node = nodes[key] else { continue }
            engine.attach(node)
            engine.connect(node, to: mainMixer, format: nil)
        }
    }

    

    private func prepareBuffers() {
        // note: Audio/ — folder reference в bundle, lookup через subdirectory
        for key in SoundKey.allCases {
            let url = locateAsset(named: key.fileName)
            guard let resolved = url else { continue }
            do {
                let file = try AVAudioFile(forReading: resolved)
                guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                                   frameCapacity: AVAudioFrameCount(file.length)) else { continue }
                try file.read(into: buffer)
                buffers[key] = buffer
            } catch {
                // note: пропускаем — этот звук не озвучится
            }
        }
    }

    private func locateAsset(named base: String) -> URL? {
        let extensions = ["caf", "m4a", "mp3", "wav"]
        for ext in extensions {
            if let url = Bundle.main.url(forResource: base, withExtension: ext, subdirectory: "Audio") {
                return url
            }
            if let url = Bundle.main.url(forResource: base, withExtension: ext) {
                return url
            }
        }
        return nil
    }

    private func ensurePlaybackForActiveSounds() {
        guard !buffers.isEmpty else {
            print("[engine] play: no buffers loaded")
            isPlaying = false
            return
        }
        startEngineIfNeeded()
        var anyActive = false
        for key in SoundKey.allCases {
            guard let node = nodes[key] else { continue }
            let level = snapshot.current.level(for: key) * snapshot.masterVolume
            switch level {
            case 0:
                if node.isPlaying { node.pause() }
            default:
                anyActive = true
                node.volume = level
                if !node.isPlaying { scheduleLoop(for: key, node: node) }
            }
        }
        isPlaying = anyActive
    }

    private func startEngineIfNeeded() {
        activateSessionIfNeeded()
        guard !engine.isRunning else { return }
        do {
            try engine.start()
            print("[engine] started")
        } catch {
            print("[engine] start error: \(error)")
        }
    }

    private func scheduleLoop(for key: SoundKey, node: AVAudioPlayerNode) {
        guard let buffer = buffers[key] else { return }
        node.scheduleBuffer(buffer, at: nil, options: [.loops], completionHandler: nil)
        node.play()
    }

    func stopAll() {
        for (_, node) in nodes {
            node.stop()
        }
        if engine.isRunning { engine.pause() }
        isPlaying = false
    }

    private func applyMix() {
        for key in SoundKey.allCases {
            guard let node = nodes[key] else { continue }
            node.volume = snapshot.current.level(for: key) * snapshot.masterVolume
        }
    }

    private func applyFadeCoefficient(_ coef: Float) {
        for key in SoundKey.allCases {
            guard let node = nodes[key] else { continue }
            node.volume = snapshot.current.level(for: key) * snapshot.masterVolume * coef
        }
    }
}

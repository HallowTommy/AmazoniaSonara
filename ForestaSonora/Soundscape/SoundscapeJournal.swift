import Foundation

actor SoundscapeJournal {
    private(set) var presets: [SoundMix] = []
    private(set) var current: SoundMix = .empty
    private(set) var timerMinutes: Int = 30
    private(set) var masterVolume: Float = 0.8
    private(set) var isLooping: Bool = true
    private(set) var isFading: Bool = true
    private(set) var defaultDuration: Int = 30
    private(set) var selectedMode: String = "sonno"

    private let store = UserDefaults.standard

    private enum Key {
        static let mixerPresets = "mixerPresets"
        static let audioMix = "audioMix"
        static let nightTimer = "nightTimer"
        static let masterVolume = "masterVolume"
        static let isLooping = "loopingFlag"
        static let isFading = "fadingFlag"
        static let defaultDuration = "defaultDuration"
        static let selectedMode = "selectedMode"
    }

    func hydrate() async {
        if let data = store.data(forKey: Key.mixerPresets),
           let decoded = try? JSONDecoder().decode([SoundMix].self, from: data) {
            presets = decoded
        }
        if let data = store.data(forKey: Key.audioMix),
           let decoded = try? JSONDecoder().decode(SoundMix.self, from: data) {
            current = decoded
        }
        let storedTimer = store.integer(forKey: Key.nightTimer)
        if storedTimer > 0 { timerMinutes = storedTimer }
        let storedVolume = store.float(forKey: Key.masterVolume)
        if storedVolume > 0 { masterVolume = storedVolume }
        let storedDefault = store.integer(forKey: Key.defaultDuration)
        if storedDefault > 0 { defaultDuration = storedDefault }
        if let mode = store.string(forKey: Key.selectedMode) { selectedMode = mode }
        if store.object(forKey: Key.isLooping) != nil { isLooping = store.bool(forKey: Key.isLooping) }
        if store.object(forKey: Key.isFading) != nil { isFading = store.bool(forKey: Key.isFading) }
    }

    func commit() async {
        if let data = try? JSONEncoder().encode(presets) {
            store.set(data, forKey: Key.mixerPresets)
        }
        if let data = try? JSONEncoder().encode(current) {
            store.set(data, forKey: Key.audioMix)
        }
        store.set(timerMinutes, forKey: Key.nightTimer)
        store.set(masterVolume, forKey: Key.masterVolume)
        store.set(defaultDuration, forKey: Key.defaultDuration)
        store.set(selectedMode, forKey: Key.selectedMode)
        store.set(isLooping, forKey: Key.isLooping)
        store.set(isFading, forKey: Key.isFading)
    }

    func savePreset(_ mix: SoundMix, name: String) async {
        var renamed = mix
        renamed.name = name
        renamed.createdAt = .now
        if let idx = presets.firstIndex(where: { $0.id == mix.id }) {
            presets[idx] = renamed
        } else {
            presets.insert(renamed, at: 0)
        }
        await commit()
    }

    func removePreset(_ id: UUID) async {
        presets.removeAll { $0.id == id }
        await commit()
    }

    func loadPreset(_ mix: SoundMix) async {
        current = mix
        await commit()
    }

    func setVolume(_ key: SoundKey, value: Float) async {
        var levels = current.levels
        let clamped = max(0, min(1, value))
        switch clamped {
        case 0: levels.removeValue(forKey: key)
        default: levels[key] = clamped
        }
        current.levels = levels
        await commit()
    }

    func toggleSound(_ key: SoundKey) async {
        let level = current.level(for: key)
        switch level {
        case 0: await setVolume(key, value: 0.65)
        default: await setVolume(key, value: 0)
        }
    }

    func setMasterVolume(_ value: Float) async {
        masterVolume = max(0, min(1, value))
        await commit()
    }

    func setTimerMinutes(_ value: Int) async {
        timerMinutes = value
        await commit()
    }

    func setSelectedMode(_ value: String) async {
        selectedMode = value
        await commit()
    }

    func setFading(_ value: Bool) async {
        isFading = value
        await commit()
    }

    func setDefaultDuration(_ value: Int) async {
        defaultDuration = value
        await commit()
    }

    func clearCurrent() async {
        current = .empty
        await commit()
    }

    func snapshot() async -> SoundscapeSnapshot {
        SoundscapeSnapshot(
            presets: presets,
            current: current,
            timerMinutes: timerMinutes,
            masterVolume: masterVolume,
            isLooping: isLooping,
            isFading: isFading,
            defaultDuration: defaultDuration,
            selectedMode: selectedMode
        )
    }
}

struct SoundscapeSnapshot: Equatable {
    var presets: [SoundMix]
    var current: SoundMix
    var timerMinutes: Int
    var masterVolume: Float
    var isLooping: Bool
    var isFading: Bool
    var defaultDuration: Int
    var selectedMode: String

    static let empty = SoundscapeSnapshot(
        presets: [],
        current: .empty,
        timerMinutes: 30,
        masterVolume: 0.8,
        isLooping: true,
        isFading: true,
        defaultDuration: 30,
        selectedMode: "sonno"
    )
}

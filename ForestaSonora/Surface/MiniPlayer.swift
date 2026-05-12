import SwiftUI

struct MiniPlayer: View {
    @Environment(\.soundscape) private var journal
    @EnvironmentObject private var engine: AudioEngine
    @AppStorage("startTab") private var startTabRaw: String = "home"

    var body: some View {
        if shouldShow {
            playerCard
                .padding(.horizontal, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var playerCard: some View {
        HStack(spacing: 10) {
            Button {
                startTabRaw = RootTab.mixer.rawValue
            } label: {
                HStack(spacing: 10) {
                    albumThumb
                    VStack(alignment: .leading, spacing: 2) {
                        Text(displayedTitle)
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(Palette.textLight)
                            .lineLimit(1)
                        Text(displayedSubtitle)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Palette.textSecondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.plain)

            playButton
            closeButton
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Palette.panelMid)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Palette.aqua.opacity(0.45), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 14, y: 6)
        .frame(maxWidth: .infinity)
    }

    private var shouldShow: Bool {
        engine.isPlaying || engine.timerEnd != nil || !engine.snapshot.current.activeKeys.isEmpty
    }

    private var albumThumb: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(LinearGradient(colors: [Palette.aqua, Palette.azure],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 36, height: 36)
            Image(systemName: "leaf.fill")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(Palette.gold)
                .rotationEffect(.degrees(-15))
        }
    }

    private var playButton: some View {
        Button {
            engine.playPause()
        } label: {
            ZStack {
                Circle().fill(Palette.aqua).frame(width: 34, height: 34)
                Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Palette.backgroundDeep)
                    .offset(x: engine.isPlaying ? 0 : 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var closeButton: some View {
        Button {
            engine.stopAll()
            engine.stopTimer()
            Task { await journal.clearCurrent(); await engine.refresh() }
        } label: {
            ZStack {
                Circle()
                    .fill(Palette.panelHigh)
                    .overlay(Circle().stroke(Palette.coral.opacity(0.55), lineWidth: 1))
                    .frame(width: 30, height: 30)
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(Palette.coral)
            }
        }
        .buttonStyle(.plain)
    }

    private var displayedTitle: String {
        let mix = engine.snapshot.current
        switch mix.name.isEmpty {
        case true: return "Paesaggio sonoro"
        case false: return mix.name
        }
    }

    private var displayedSubtitle: String {
        let count = engine.snapshot.current.activeKeys.count
        switch engine.timerEnd {
        case .some(let end):
            let mins = max(0, Int(ceil(end.timeIntervalSinceNow / 60)))
            return "\(count) suoni · timer \(mins) min"
        case .none:
            switch engine.isPlaying {
            case true:  return "\(count) suoni in riproduzione"
            case false: return "\(count) suoni · in pausa"
            }
        }
    }
}

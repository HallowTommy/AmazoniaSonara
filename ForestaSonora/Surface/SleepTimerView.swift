import SwiftUI

struct SleepTimerView: View {
    @Environment(\.soundscape) private var journal
    @EnvironmentObject private var engine: AudioEngine
    @State private var minutes: Int = 30
    @State private var fade: Bool = true

    private let options = [15, 30, 45, 60, 90]

    var body: some View {
        ZStack {
            Palette.heroGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    ringView
                        .padding(.top, 8)
                    chipRow
                    statusCard
                    fadeToggle
                    actionButton
                    Spacer(minLength: 140)
                }
                .padding(.horizontal, 18)
                .padding(.top, 4)
            }
        }
        .navigationTitle("timer.title")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await engine.refresh()
            minutes = engine.snapshot.timerMinutes
            fade = engine.snapshot.isFading
        }
    }

    private var ringView: some View {
        ZStack {
            Circle()
                .stroke(Palette.panelMid, lineWidth: 14)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Palette.buttonAccent,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(Animation.timingCurve(0.25, 0.1, 0.25, 1, duration: 0.6), value: progress)

            VStack(spacing: 4) {
                Image(systemName: engine.timerEnd == nil ? "moon.zzz.fill" : "hourglass")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(Palette.gold)
                Text(displayedNumber)
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Palette.textLight)
                Text("timer.minutes")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.textSecondary)
                    .textCase(.uppercase)
                    .tracking(2)
            }
        }
        .frame(width: 220, height: 220)
        .padding(.vertical, 8)
    }

    private var chipRow: some View {
        HStack(spacing: 6) {
            ForEach(options, id: \.self) { value in
                let active = minutes == value
                Button {
                    minutes = value
                    Task { await journal.setTimerMinutes(value); await engine.refresh() }
                } label: {
                    VStack(spacing: 0) {
                        Text("\(value)")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .monospacedDigit()
                        Text("min")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .textCase(.uppercase)
                            .tracking(1)
                            .opacity(0.85)
                    }
                    .foregroundStyle(active ? Palette.backgroundDeep : Palette.textLight)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(active ? AnyShapeStyle(Palette.buttonAccent) : AnyShapeStyle(Palette.panelMid))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var statusCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Palette.aqua.opacity(0.22)).frame(width: 38, height: 38)
                Image(systemName: engine.timerEnd == nil ? "leaf.fill" : "waveform")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(Palette.aqua)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(statusTitle)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.textLight)
                Text(statusDetail)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Palette.panelMid.opacity(0.7))
        )
    }

    private var fadeToggle: some View {
        Toggle(isOn: Binding(
            get: { fade },
            set: { value in
                fade = value
                Task { await journal.setFading(value); await engine.refresh() }
            }
        )) {
            VStack(alignment: .leading, spacing: 2) {
                Text("timer.fade_label")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.textLight)
                Text("timer.fade_hint")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(Palette.turquoise)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Palette.panelMid.opacity(0.7))
        )
    }

    private var actionButton: some View {
        Button {
            switch engine.timerEnd {
            case .none: engine.startTimer(minutes: minutes, fade: fade)
            case .some: engine.stopTimer()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: engine.timerEnd == nil ? "play.fill" : "stop.fill")
                Text(engine.timerEnd == nil ? "timer.start" : "timer.stop")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryPillStyle(gradient: engine.timerEnd == nil ? Palette.buttonPlay : Palette.buttonAccent))
    }

    private var progress: CGFloat {
        switch engine.timerEnd {
        case .none: return 0
        case .some: return CGFloat(engine.timerProgress)
        }
    }

    private var displayedNumber: String {
        switch engine.timerEnd {
        case .none:
            return "\(minutes)"
        case .some(let end):
            let remaining = max(0, end.timeIntervalSinceNow)
            return "\(Int(ceil(remaining / 60)))"
        }
    }

    private var statusTitle: String {
        switch engine.timerEnd {
        case .none:
            return engine.snapshot.current.activeKeys.isEmpty
                ? "Pronto al riposo"
                : "Atmosfera attiva"
        case .some:
            return "Timer in corso"
        }
    }

    private var statusDetail: String {
        let count = engine.snapshot.current.activeKeys.count
        switch engine.timerEnd {
        case .none:
            switch count {
            case 0:  return "Avvia un paesaggio dal mixer per addormentarti"
            default: return "\(count) suoni · pronti a sfumare"
            }
        case .some(let end):
            let remaining = max(0, end.timeIntervalSinceNow)
            let mins = Int(ceil(remaining / 60))
            return fade ? "\(mins) min · dissolvenza alla fine" : "\(mins) min · stop secco"
        }
    }
}

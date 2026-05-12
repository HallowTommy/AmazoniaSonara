import SwiftUI

struct MixerView: View {
    @Environment(\.soundscape) private var journal
    @EnvironmentObject private var engine: AudioEngine
    @State private var presetName: String = ""
    @State private var showSavePrompt = false

    private let columns = [GridItem(.flexible(), spacing: 16),
                           GridItem(.flexible(), spacing: 16),
                           GridItem(.flexible(), spacing: 16),
                           GridItem(.flexible(), spacing: 16)]

    var body: some View {
        ZStack {
            Palette.heroGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 22) {
                    soundGrid
                    actionRow
                    sliderList
                    masterRow
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
            }
        }
        .navigationTitle("mixer.title")
        .navigationBarTitleDisplayMode(.inline)
        .alert("mixer.save_preset", isPresented: $showSavePrompt) {
            TextField("mixer.preset_name_prompt", text: $presetName)
            Button("common.save") {
                Task { await savePreset() }
            }
            Button("common.cancel", role: .cancel) { presetName = "" }
        }
        .task { await engine.refresh() }
    }

    private var soundGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(SoundKey.allCases) { key in
                soundButton(for: key)
            }
        }
    }

    private func soundButton(for key: SoundKey) -> some View {
        let level = engine.snapshot.current.level(for: key)
        let active = level > 0
        return Button {
            Task { await engine.toggle(key) }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(active ? key.hue.opacity(0.85) : Palette.panelMid)
                        .overlay(
                            Circle().stroke(active ? Palette.gold : Palette.inactive.opacity(0.5), lineWidth: 2)
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: active ? key.hue.opacity(0.6) : .clear, radius: 14)

                    Image(systemName: key.iconSymbol)
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(active ? Palette.backgroundDeep : Palette.textSecondary)
                }
                Text(key.localizedName)
                    .font(.fsCaption)
                    .foregroundStyle(active ? Palette.textLight : Palette.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var actionRow: some View {
        HStack(spacing: 22) {
            actionButton(symbol: "heart.fill", tint: Palette.coral) { showSavePrompt = true }
            playButton
            actionButton(symbol: "shuffle", tint: Palette.lime) {
                Task { await loadRandomScene() }
            }
        }
        .padding(.vertical, 8)
    }

    private var playButton: some View {
        Button {
            engine.playPause()
        } label: {
            ZStack {
                Circle()
                    .fill(Palette.buttonPlay)
                    .frame(width: 84, height: 84)
                    .shadow(color: Palette.turquoise.opacity(0.6), radius: 18, y: 8)
                Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(Palette.backgroundDeep)
            }
        }
        .buttonStyle(.plain)
    }

    private func actionButton(symbol: String, tint: Color, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(Palette.panelMid.opacity(0.85))
                    .frame(width: 56, height: 56)
                    .overlay(Circle().stroke(tint.opacity(0.55), lineWidth: 1.5))
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(tint)
                    .shadow(color: tint.opacity(0.45), radius: 8)
            }
        }
        .buttonStyle(.plain)
    }

    private var sliderList: some View {
        VStack(spacing: 10) {
            ForEach(SoundKey.allCases) { key in
                sliderRow(for: key)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Palette.panelMid.opacity(0.6))
        )
    }

    private func sliderRow(for key: SoundKey) -> some View {
        let level = engine.snapshot.current.level(for: key)
        return HStack(spacing: 10) {
            Image(systemName: key.iconSymbol)
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(key.hue)
                .frame(width: 22)
            Text(key.localizedName)
                .font(.fsCaption)
                .foregroundStyle(Palette.textLight)
                .frame(width: 76, alignment: .leading)
            Slider(value: Binding(
                get: { Double(level) },
                set: { newValue in
                    Task { await engine.setVolume(key, value: Float(newValue)) }
                }
            ), in: 0...1)
            .tint(key.hue)
            Text("\(Int(level * 100))%")
                .font(.fsChip)
                .foregroundStyle(Palette.textSecondary)
                .frame(width: 38, alignment: .trailing)
                .monospacedDigit()
        }
        .animation(.linear(duration: 0.3), value: level)
    }

    private var masterRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.wave.3.fill")
                .foregroundStyle(Palette.gold)
            Text("mixer.master_volume")
                .font(.fsChip)
                .foregroundStyle(Palette.textLight)
            Slider(value: Binding(
                get: { Double(engine.snapshot.masterVolume) },
                set: { newValue in
                    Task { await engine.setMaster(Float(newValue)) }
                }
            ), in: 0...1)
            .tint(Palette.gold)
            Text("\(Int(engine.snapshot.masterVolume * 100))%")
                .font(.fsChip)
                .foregroundStyle(Palette.textSecondary)
                .frame(width: 38, alignment: .trailing)
                .monospacedDigit()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Palette.panelHigh.opacity(0.85))
        )
    }

    private func savePreset() async {
        let name = presetName.trimmingCharacters(in: .whitespaces)
        switch name.isEmpty {
        case true: return
        case false:
            let mix = engine.snapshot.current
            let renamed = SoundMix(id: UUID(), name: name, levels: mix.levels)
            await journal.savePreset(renamed, name: name)
            await engine.refresh()
            presetName = ""
        }
    }

    private func loadRandomScene() async {
        guard let scene = SoundMix.builtinScenes.randomElement() else { return }
        await engine.loadPreset(scene)
    }
}

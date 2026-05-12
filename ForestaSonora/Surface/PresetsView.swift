import SwiftUI

struct PresetsView: View {
    @Environment(\.soundscape) private var journal
    @EnvironmentObject private var engine: AudioEngine

    var body: some View {
        ZStack {
            Palette.heroGradient.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    builtinSection
                    userSection
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
            }
        }
        .navigationTitle("presets.title")
        .navigationBarTitleDisplayMode(.inline)
        .task { await engine.refresh() }
    }

    private var builtinSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("presets.builtin")
                .font(.fsSection)
                .foregroundStyle(Palette.textLight)
            VStack(spacing: 10) {
                ForEach(SoundMix.builtinScenes) { mix in
                    presetRow(mix, deletable: false)
                }
            }
        }
    }

    private var userSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("home.my_mixes")
                .font(.fsSection)
                .foregroundStyle(Palette.textLight)
            switch engine.snapshot.presets.isEmpty {
            case true:
                emptyState
            case false:
                VStack(spacing: 10) {
                    ForEach(engine.snapshot.presets) { mix in
                        presetRow(mix, deletable: true)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "tray")
                .font(.system(size: 38, weight: .heavy))
                .foregroundStyle(Palette.gold.opacity(0.7))
            Text("presets.empty")
                .font(.fsBody)
                .foregroundStyle(Palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Palette.panelMid.opacity(0.6))
        )
    }

    private func presetRow(_ mix: SoundMix, deletable: Bool) -> some View {
        HStack(spacing: 14) {
            iconCluster(for: mix)
            VStack(alignment: .leading, spacing: 4) {
                Text(mix.name)
                    .font(.fsSection)
                    .foregroundStyle(Palette.textLight)
                Text("\(mix.activeKeys.count) suoni")
                    .font(.fsCaption)
                    .foregroundStyle(Palette.textSecondary)
            }
            Spacer()
            Button {
                Task { await engine.loadPreset(mix) }
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(Palette.gold)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Palette.panelMid.opacity(0.95)))
                    .overlay(Circle().stroke(Palette.gold.opacity(0.6), lineWidth: 1))
            }
            .buttonStyle(.plain)
            switch deletable {
            case true:
                Button {
                    Task { await journal.removePreset(mix.id); await engine.refresh() }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Palette.coral)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Palette.panelMid.opacity(0.85)))
                }
                .buttonStyle(.plain)
            case false:
                EmptyView()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Palette.panelMid.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Palette.turquoise.opacity(0.2), lineWidth: 1)
        )
    }

    private func iconCluster(for mix: SoundMix) -> some View {
        let active = mix.activeKeys.prefix(4)
        return ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Palette.backgroundDeep)
                .frame(width: 60, height: 60)
            HStack(spacing: 4) {
                VStack(spacing: 4) {
                    iconChip(at: 0, in: Array(active))
                    iconChip(at: 2, in: Array(active))
                }
                VStack(spacing: 4) {
                    iconChip(at: 1, in: Array(active))
                    iconChip(at: 3, in: Array(active))
                }
            }
        }
    }

    @ViewBuilder
    private func iconChip(at index: Int, in keys: [SoundKey]) -> some View {
        switch index < keys.count {
        case true:
            let key = keys[index]
            Image(systemName: key.iconSymbol)
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(key.hue)
                .frame(width: 22, height: 22)
                .background(Circle().fill(key.hue.opacity(0.18)))
        case false:
            Color.clear.frame(width: 22, height: 22)
        }
    }
}

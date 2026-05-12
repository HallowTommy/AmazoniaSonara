import SwiftUI

struct SoundCreditsView: View {
    private struct Credit {
        let key: SoundKey
        let title: String
        let source: String
        let license: String
        let url: String
    }

    private let credits: [Credit] = [
        Credit(key: .pioggia,
               title: "Light Rain — Overcast Day",
               source: "Internet Archive · Relaxing Sounds (GenreFan)",
               license: "Public Domain",
               url: "https://archive.org/details/relaxingsounds"),
        Credit(key: .fiume,
               title: "Rainforest Bubbling River",
               source: "Internet Archive · Relaxing Sounds",
               license: "Public Domain",
               url: "https://archive.org/details/relaxingsounds"),
        Credit(key: .cascata,
               title: "Mountain Stream Waterfall",
               source: "Internet Archive · Relaxing Sounds",
               license: "Public Domain",
               url: "https://archive.org/details/relaxingsounds"),
        Credit(key: .uccelli,
               title: "Birdsong (Sound Therapy)",
               source: "Internet Archive · Nature Sounds",
               license: "CC0 1.0 Universal",
               url: "https://archive.org/details/naturesounds-soundtheraphy"),
        Credit(key: .vento,
               title: "Gentle Wind — Low Pitch",
               source: "Internet Archive · Relaxing Sounds",
               license: "Public Domain",
               url: "https://archive.org/details/relaxingsounds"),
        Credit(key: .foglie,
               title: "Light Rain — Drips on Trees",
               source: "Internet Archive · Relaxing Sounds",
               license: "Public Domain",
               url: "https://archive.org/details/relaxingsounds"),
        Credit(key: .tuono,
               title: "Distant Thunder — Low Rumble",
               source: "Internet Archive · Relaxing Sounds",
               license: "Public Domain",
               url: "https://archive.org/details/relaxingsounds"),
        Credit(key: .cicale,
               title: "Cicadas — Locust Swells",
               source: "Internet Archive · Relaxing Sounds (RGD)",
               license: "Public Domain",
               url: "https://archive.org/details/relaxingsounds")
    ]

    var body: some View {
        ZStack {
            Palette.heroGradient.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    intro
                    ForEach(credits, id: \.key) { credit in
                        creditRow(credit)
                    }
                    fullCollections
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("profile.credits")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tutti i suoni sono royalty-free e in pubblico dominio o licenza CC0.")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.textLight)
            Text("Possono essere usati anche in contesto commerciale, senza attribuzione obbligatoria. Riportati qui per trasparenza.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Palette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Palette.panelMid.opacity(0.7))
        )
    }

    private func creditRow(_ credit: Credit) -> some View {
        Button {
            if let url = URL(string: credit.url) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle().fill(credit.key.hue.opacity(0.22)).frame(width: 40, height: 40)
                    Image(systemName: credit.key.iconSymbol)
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(credit.key.hue)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(credit.key.localizedName)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(Palette.textLight)
                        Text(credit.license)
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundStyle(Palette.backgroundDeep)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Palette.aqua))
                    }
                    Text(credit.title)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.textSecondary)
                    Text(credit.source)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.textSecondary.opacity(0.75))
                }
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(Palette.gold)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Palette.panelMid.opacity(0.65))
            )
        }
        .buttonStyle(.plain)
    }

    private var fullCollections: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Raccolte sorgente")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.textLight)
                .padding(.top, 8)
            VStack(alignment: .leading, spacing: 4) {
                Text("• Internet Archive — Relaxing Sounds (GenreFan)")
                Text("• Internet Archive — Nature Sounds Sound Therapy")
            }
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(Palette.textSecondary)

            Text("Le tracce originali sono state tagliate (60 s) e ottimizzate per la riproduzione in loop.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Palette.textSecondary.opacity(0.75))
                .padding(.top, 6)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Palette.panelMid.opacity(0.55))
        )
    }
}

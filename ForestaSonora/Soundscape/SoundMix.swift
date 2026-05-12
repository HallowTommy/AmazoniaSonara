import Foundation

struct SoundMix: Codable, Hashable, Identifiable {
    var id: UUID
    var name: String
    var levels: [SoundKey: Float]
    var createdAt: Date

    init(id: UUID = UUID(), name: String, levels: [SoundKey: Float], createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.levels = levels
        self.createdAt = createdAt
    }

    static let empty = SoundMix(name: "", levels: [:])

    var activeKeys: [SoundKey] {
        SoundKey.allCases.filter { (levels[$0] ?? 0) > 0.01 }
    }

    func level(for key: SoundKey) -> Float {
        levels[key] ?? 0
    }

    static let builtinScenes: [SoundMix] = [
        SoundMix(name: "Pioggia tropicale", levels: [.pioggia: 0.85, .cicale: 0.35, .tuono: 0.25]),
        SoundMix(name: "Riposo accanto al fiume", levels: [.fiume: 0.80, .uccelli: 0.55, .vento: 0.40]),
        SoundMix(name: "Sera nella giungla", levels: [.foglie: 0.70, .cicale: 0.65, .pioggia: 0.30]),
        SoundMix(name: "Cascata Serena", levels: [.cascata: 0.90, .uccelli: 0.30]),
        SoundMix(name: "Alba nella Foresta", levels: [.uccelli: 0.85, .foglie: 0.40, .vento: 0.25]),
        SoundMix(name: "Focus Tropicale", levels: [.pioggia: 0.45, .foglie: 0.55])
    ]
}

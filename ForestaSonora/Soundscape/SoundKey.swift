import Foundation
import SwiftUI

enum SoundKey: String, CaseIterable, Codable, Hashable, Identifiable {
    case pioggia, fiume, cascata, uccelli, vento, foglie, tuono, cicale

    var id: String { rawValue }

    var localizedName: LocalizedStringKey {
        switch self {
        case .pioggia: return "sound.pioggia"
        case .fiume:   return "sound.fiume"
        case .cascata: return "sound.cascata"
        case .uccelli: return "sound.uccelli"
        case .vento:   return "sound.vento"
        case .foglie:  return "sound.foglie"
        case .tuono:   return "sound.tuono"
        case .cicale:  return "sound.cicale"
        }
    }

    var fileName: String {
        switch self {
        case .pioggia: return "pioggia"
        case .fiume:   return "fiume"
        case .cascata: return "cascata"
        case .uccelli: return "uccelli"
        case .vento:   return "vento"
        case .foglie:  return "foglie"
        case .tuono:   return "tuono"
        case .cicale:  return "cicale"
        }
    }

    var iconSymbol: String {
        switch self {
        case .pioggia: return "cloud.rain.fill"
        case .fiume:   return "water.waves"
        case .cascata: return "drop.fill"
        case .uccelli: return "bird.fill"
        case .vento:   return "wind"
        case .foglie:  return "leaf.fill"
        case .tuono:   return "bolt.fill"
        case .cicale:  return "ant.fill"
        }
    }

    var hue: Color {
        switch self {
        case .pioggia: return Palette.azure
        case .fiume:   return Palette.aqua
        case .cascata: return Palette.turquoise
        case .uccelli: return Palette.coral
        case .vento:   return Palette.aqua
        case .foglie:  return Palette.lime
        case .tuono:   return Palette.gold
        case .cicale:  return Palette.pink
        }
    }
}

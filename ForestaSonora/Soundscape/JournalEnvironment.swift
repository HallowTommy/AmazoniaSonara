import SwiftUI

private struct SoundscapeKey: EnvironmentKey {
    static let defaultValue: SoundscapeJournal = SoundscapeJournal()
}

extension EnvironmentValues {
    var soundscape: SoundscapeJournal {
        get { self[SoundscapeKey.self] }
        set { self[SoundscapeKey.self] = newValue }
    }
}

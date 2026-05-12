import SwiftUI

@MainActor
final class GateProbe: ObservableObject {
    static let shared = GateProbe()

    @Published private(set) var outcome: GateOutcome = .silent
    @Published private(set) var hasFinished: Bool = false
    private(set) var sessionCookies: [HTTPCookie] = []

    private(set) var options = GateProbeOptions()

    private init() {}

    static func bootstrap(host: String,
                          key: String,
                          deadline: TimeInterval = 9,
                          streams: Set<Int>? = nil,
                          safeFallback: GateOutcome = .silent) {
        var merged = AppConfig.relayHints
        shared.options.host = host
        shared.options.key = key
        shared.options.deadline = deadline
        shared.options.streamWhitelist = streams
        shared.options.safeFallback = safeFallback
        shared.options.hints = merged
    }

    func awakeAndProbe() async {
        GateLog.write("Probe awake")
        let bundle = await RemoteGateFetcher.probe(options)
        outcome = bundle.outcome
        sessionCookies = bundle.cookies
        hasFinished = true
        switch bundle.outcome {
        case .unfold(let url):
            GateLog.write("Probe decision unfold → \(url) cookies=\(bundle.cookies.count)")
        case .silent:
            GateLog.write("Probe decision silent cookies=\(bundle.cookies.count)")
        case .blocked(let reason):
            GateLog.write("Probe decision blocked: \(reason)")
        }
    }

    var carrierURL: URL? { outcome.carrierURL }
    var shouldUnfold: Bool { outcome.isUnfold }
}

struct GateRouterView<Surface: View, Carrier: View>: View {
    @StateObject private var probe = GateProbe.shared
    let surface: () -> Surface
    let carrier: (URL) -> Carrier

    var body: some View {
        ZStack {
            surface()
            if probe.hasFinished, let url = probe.carrierURL {
                carrier(url).transition(.opacity)
            }
        }
        .task { await probe.awakeAndProbe() }
    }
}

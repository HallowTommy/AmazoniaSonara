import SwiftUI
@preconcurrency import WebKit

@MainActor
final class BridgeNavigator: NSObject, ObservableObject {
    @Published private(set) var canRetreat: Bool = false
    @Published private(set) var canAdvance: Bool = false
    @Published private(set) var isFetching: Bool = false
    @Published private(set) var fetchProgress: Double = 0

    let canvas: WKWebView
    let homeURL: URL

    private var watches: [NSKeyValueObservation] = []
    private var reloadAttempts = 0
    private let reloadCeiling = 4

    init(homeURL: URL, agent: String, sessionCookies: [HTTPCookie] = []) {
        self.homeURL = homeURL

        let conf = WKWebViewConfiguration()
        conf.allowsInlineMediaPlayback = true
        conf.mediaTypesRequiringUserActionForPlayback = []
        conf.websiteDataStore = .default()

        let canvas = WKWebView(frame: .zero, configuration: conf)
        canvas.allowsBackForwardNavigationGestures = true
        canvas.scrollView.bounces = true
        canvas.isOpaque = false
        canvas.backgroundColor = .clear
        canvas.scrollView.backgroundColor = .clear
        canvas.customUserAgent = agent
        self.canvas = canvas

        super.init()

        canvas.navigationDelegate = self
        watches = [
            canvas.observe(\.canGoBack, options: [.initial, .new]) { [weak self] cv, _ in
                Task { @MainActor in self?.canRetreat = cv.canGoBack }
            },
            canvas.observe(\.canGoForward, options: [.initial, .new]) { [weak self] cv, _ in
                Task { @MainActor in self?.canAdvance = cv.canGoForward }
            },
            canvas.observe(\.isLoading, options: [.initial, .new]) { [weak self] cv, _ in
                Task { @MainActor in self?.isFetching = cv.isLoading }
            },
            canvas.observe(\.estimatedProgress, options: [.initial, .new]) { [weak self] cv, _ in
                Task { @MainActor in self?.fetchProgress = cv.estimatedProgress }
            }
        ]

        GateLog.write("Bridge init target=\(homeURL.absoluteString) cookies=\(sessionCookies.count)")
        if sessionCookies.isEmpty {
            canvas.load(URLRequest(url: homeURL))
        } else {
            let store = canvas.configuration.websiteDataStore.httpCookieStore
            Task { @MainActor [weak self] in
                for cookie in sessionCookies {
                    GateLog.write("Bridge set cookie \(cookie.name) domain=\(cookie.domain)")
                    await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                        store.setCookie(cookie) { cont.resume() }
                    }
                }
                GateLog.write("Bridge cookies set, loading")
                self?.canvas.load(URLRequest(url: homeURL))
            }
        }
    }

    deinit {
        watches.forEach { $0.invalidate() }
    }

    func retreat() { canvas.goBack() }
    func advance() { canvas.goForward() }
    func reload() { canvas.reload() }
    func returnHome() { canvas.load(URLRequest(url: homeURL)) }

    nonisolated static func isRetryable(_ err: NSError) -> Bool {
        guard err.domain == NSURLErrorDomain else { return false }
        switch err.code {
        case NSURLErrorTimedOut,
             NSURLErrorNetworkConnectionLost,
             NSURLErrorNotConnectedToInternet,
             NSURLErrorDNSLookupFailed,
             NSURLErrorCannotConnectToHost,
             NSURLErrorCannotFindHost,
             NSURLErrorInternationalRoamingOff,
             NSURLErrorDataNotAllowed:
            return true
        default:
            return false
        }
    }

    private func scheduleRelaunch(reason: String) async {
        guard reloadAttempts < reloadCeiling else {
            GateLog.write("Bridge reload limit \(reloadAttempts)/\(reloadCeiling)")
            return
        }
        reloadAttempts += 1
        let waitSec = min(8, 1 << (reloadAttempts - 1))
        GateLog.write("Bridge reload #\(reloadAttempts) in \(waitSec)s — \(reason)")
        try? await Task.sleep(nanoseconds: UInt64(waitSec) * 1_000_000_000)
        if canvas.url == nil {
            canvas.load(URLRequest(url: homeURL))
        } else {
            canvas.reload()
        }
    }
}

extension BridgeNavigator: WKNavigationDelegate {
    func webView(_ canvas: WKWebView, decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
        guard let target = action.request.url else { return .cancel }
        switch target.scheme ?? "" {
        case "tel", "mailto", "itms-apps", "itms-appss":
            await UIApplication.shared.open(target)
            return .cancel
        default:
            return .allow
        }
    }

    nonisolated func webView(_ canvas: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        GateLog.write("Bridge start nav → \(canvas.url?.absoluteString ?? "nil")")
    }

    nonisolated func webView(_ canvas: WKWebView, didFinish navigation: WKNavigation!) {
        GateLog.write("Bridge finish nav → \(canvas.url?.absoluteString ?? "nil")")
        Task { @MainActor [weak self] in self?.reloadAttempts = 0 }
    }

    nonisolated func webView(_ canvas: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let nsErr = error as NSError
        GateLog.write("Bridge didFail \(nsErr.domain) \(nsErr.code)")
        switch (nsErr.domain, nsErr.code) {
        case (NSURLErrorDomain, NSURLErrorCancelled): return
        default: break
        }
        guard Self.isRetryable(nsErr) else { return }
        Task { @MainActor [weak self] in
            await self?.scheduleRelaunch(reason: "didFail \(nsErr.code)")
        }
    }

    nonisolated func webView(_ canvas: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let nsErr = error as NSError
        GateLog.write("Bridge provisional \(nsErr.domain) \(nsErr.code)")
        switch (nsErr.domain, nsErr.code) {
        case (NSURLErrorDomain, NSURLErrorCancelled): return
        default: break
        }
        guard Self.isRetryable(nsErr) else { return }
        Task { @MainActor [weak self] in
            await self?.scheduleRelaunch(reason: "provisional \(nsErr.code)")
        }
    }
}

private struct CanvasHost: UIViewRepresentable {
    let canvas: WKWebView
    func makeUIView(context: Context) -> WKWebView { canvas }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct BridgeWebView: View {
    @StateObject private var navigator: BridgeNavigator

    init(url: URL) {
        _navigator = StateObject(wrappedValue: BridgeNavigator(
            homeURL: url,
            agent: GateProbe.shared.options.headerAgent,
            sessionCookies: GateProbe.shared.sessionCookies
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                CanvasHost(canvas: navigator.canvas)
                    .ignoresSafeArea(edges: [.top, .horizontal])

                if navigator.isFetching {
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Palette.aqua)
                            .frame(width: geo.size.width * navigator.fetchProgress, height: 2)
                            .animation(.easeInOut(duration: 0.2), value: navigator.fetchProgress)
                    }
                    .frame(height: 2)
                    .ignoresSafeArea(edges: [.top, .horizontal])
                }
            }

            BridgeDeck(navigator: navigator)
        }
        .background(Palette.jungleDeep.ignoresSafeArea())
    }
}

private struct BridgeDeck: View {
    @ObservedObject var navigator: BridgeNavigator

    var body: some View {
        HStack(spacing: 0) {
            deckButton(symbol: "chevron.left", enabled: navigator.canRetreat) { navigator.retreat() }
            deckButton(symbol: "chevron.right", enabled: navigator.canAdvance) { navigator.advance() }
            deckButton(symbol: "house.fill", enabled: true, weight: .semibold) { navigator.returnHome() }
            deckButton(symbol: "arrow.clockwise", enabled: true) { navigator.reload() }
        }
        .padding(.top, 10)
        .padding(.bottom, 4)
        .background(
            Palette.jungleDeep.ignoresSafeArea(edges: .bottom)
        )
        .overlay(
            Rectangle().fill(Palette.aqua.opacity(0.08)).frame(height: 0.5),
            alignment: .top
        )
    }

    @ViewBuilder
    private func deckButton(symbol: String, enabled: Bool, weight: Font.Weight = .regular, action: @escaping () -> Void) -> some View {
        Button {
            switch enabled {
            case true:
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                action()
            case false:
                break
            }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: weight))
                .foregroundStyle(enabled ? Palette.textLight.opacity(0.92) : Palette.textLight.opacity(0.25))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .contentShape(Rectangle())
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
    }
}

import Foundation

actor RemoteGateFetcher {
    static let shared = RemoteGateFetcher()

    private let session: URLSession
    private let attempts = 3
    private let pauses: [UInt64] = [800_000_000, 2_000_000_000]

    init() {
        let conf = URLSessionConfiguration.ephemeral
        conf.waitsForConnectivity = false
        conf.urlCache = nil
        conf.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        self.session = URLSession(configuration: conf)
    }

    static func probe(_ options: GateProbeOptions) async -> GateBundle {
        await shared.runProbe(options)
    }

    private enum Step {
        case ok(Data)
        case retry(String)
        case stop(String)
    }

    private func runProbe(_ options: GateProbeOptions) async -> GateBundle {
        let idle = GateBundle(outcome: options.safeFallback, cookies: [])
        GateLog.write("probe ready=\(options.isLooping) host=\(options.host)")
        guard options.isLooping else { return idle }
        guard let url = options.makeProbeURL() else { return idle }
        GateLog.write("GET \(url.absoluteString)")

        let request = makeRequest(target: url, options: options)

        for attempt in 1...attempts {
            switch await singleShot(request, attempt: attempt) {
            case .ok(let data):
                return decode(payload: data, options: options)
            case .stop(let reason):
                GateLog.write("terminal: \(reason)")
                if reason.hasPrefix("auth") {
                    return GateBundle(outcome: .blocked(reason: "invalid_token"), cookies: [])
                }
                if reason.hasPrefix("disabled") {
                    return GateBundle(outcome: .blocked(reason: "click_api_disabled"), cookies: [])
                }
                return idle
            case .retry(let reason):
                GateLog.write("transient: \(reason) #\(attempt)/\(attempts)")
                if attempt < attempts {
                    let nanos = pauses[min(attempt - 1, pauses.count - 1)]
                    try? await Task.sleep(nanoseconds: nanos)
                    continue
                }
                GateLog.write("retries exhausted")
                return idle
            }
        }
        return idle
    }

    private func makeRequest(target: URL, options: GateProbeOptions) -> URLRequest {
        var request = URLRequest(url: target, timeoutInterval: options.deadline)
        request.httpMethod = "GET"
        request.setValue(options.headerAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let lang = Locale.preferredLanguages.first {
            request.setValue(lang, forHTTPHeaderField: "Accept-Language")
        }
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return request
    }

    private func singleShot(_ request: URLRequest, attempt: Int) async -> Step {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { return .retry("no-http") }
            GateLog.write("HTTP \(http.statusCode) #\(attempt)")
            switch http.statusCode {
            case 200...299:
                return .ok(data)
            case 401, 403:
                return .stop("auth \(http.statusCode)")
            case 409:
                return .stop("disabled \(http.statusCode)")
            case 404, 410:
                return .stop("not-found \(http.statusCode)")
            case 408, 425, 429, 500, 502, 503, 504:
                return .retry("retryable \(http.statusCode)")
            case 400...499:
                return .stop("client \(http.statusCode)")
            default:
                return .retry("status \(http.statusCode)")
            }
        } catch {
            let nsErr = error as NSError
            if nsErr.domain == NSURLErrorDomain {
                switch nsErr.code {
                case NSURLErrorCancelled, NSURLErrorBadURL, NSURLErrorUnsupportedURL,
                     NSURLErrorAppTransportSecurityRequiresSecureConnection:
                    return .stop("nsurl \(nsErr.code)")
                default:
                    return .retry("nsurl \(nsErr.code)")
                }
            }
            return .retry("error")
        }
    }

    private func decode(payload: Data, options: GateProbeOptions) -> GateBundle {
        guard let answer = try? JSONDecoder().decode(RemoteGateAnswer.self, from: payload) else {
            GateLog.write("decode failed")
            return GateBundle(outcome: options.safeFallback, cookies: [])
        }
        let jar = answer.sessionCookies(host: options.host)
        GateLog.write("decoded streamId=\(answer.info?.streamId.map(String.init) ?? "nil") tokenPresent=\(answer.info?.offerToken?.isEmpty == false) cookies=\(jar.count)")

        if let bot = answer.info?.isBot, bot {
            return GateBundle(outcome: options.safeFallback, cookies: jar)
        }
        if let allowed = options.streamWhitelist,
           let sid = answer.info?.streamId,
           !allowed.contains(sid) {
            return GateBundle(outcome: options.safeFallback, cookies: jar)
        }
        if let resolved = answer.resolveURL() {
            return GateBundle(outcome: .unfold(resolved), cookies: jar)
        }
        if let token = answer.info?.offerToken,
           !token.isEmpty,
           let built = options.makeOfferURL(legacyToken: token) {
            return GateBundle(outcome: .unfold(built), cookies: jar)
        }
        return GateBundle(outcome: options.safeFallback, cookies: jar)
    }
}

enum GateLog {
    static func write(_ message: String) {
        #if DEBUG
        print("[Gate] \(message)")
        #endif
    }
}

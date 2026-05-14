import Foundation
import UIKit

enum AppConfig {
    static let relayHost = "tracker.foresta-sonora.app"
    static let relayKey = "REPLACE_WITH_CAMPAIGN_TOKEN"
    static let relayDeadline: TimeInterval = 9
    static let relayTargets: Set<Int>? = nil

    static let privacyPolicyURL = URL(string: "https://www.termsfeed.com/live/0cb91029-c334-4a5f-9941-c0183818f288")!
    static let supportEmail = "jelegafa@icloud.com"

    static var marketingVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    static var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    static var relayHints: [String: String] {
        var bag: [String: String] = [:]
        bag["sub_id_1"] = Bundle.main.bundleIdentifier ?? "unknown"
        bag["sub_id_2"] = "\(marketingVersion)-\(buildNumber)"
        bag["sub_id_3"] = Locale.preferredLanguages.first ?? "en"
        if let idfv = UIDevice.current.identifierForVendor?.uuidString {
            bag["sub_id_4"] = idfv
        }
        bag["sub_id_5"] = "ios"
        return bag
    }
}

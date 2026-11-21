import Foundation

/// The public name lives here so a later rename is one Swift change,
/// plus the matching home-screen string in Info.plist.
enum AppIdentity {
    static let displayName = "FabricStash"
    static let bundleIdentifier = "com.ashleyneale.fabricstash"
    static let unlockProductID = "com.ashleyneale.fabricstash.unlock"
    static let publisher = "Ashley Neale"
    static var csvFilename: String { "\(displayName).csv" }
}

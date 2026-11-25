import Foundation

nonisolated enum E2EFeature {
    #if DEBUG
    static let isEnabled: Bool = {
        let arguments = ProcessInfo.processInfo.arguments
        return zip(arguments, arguments.dropFirst()).contains { $0 == "-E2EEnabled" && $1 == "YES" }
    }()
    #else
    static let isEnabled = false
    #endif

    static let allowNewActivations = true
}

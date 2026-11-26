import Foundation

nonisolated enum E2EFeature {
    #if DEBUG
    static let isEnabled = isEnabled(arguments: ProcessInfo.processInfo.arguments)

    static func isEnabled(arguments: [String]) -> Bool {
        zip(arguments, arguments.dropFirst()).contains { $0 == "-E2EEnabled" && $1 == "YES" }
    }
    #else
    static let isEnabled = true
    #endif

    static let allowNewActivations = true
}

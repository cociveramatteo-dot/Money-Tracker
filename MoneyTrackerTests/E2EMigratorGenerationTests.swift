import Foundation
import Testing
@testable import MoneyTracker

@MainActor
struct E2EMigratorGenerationTests {
    private struct Interrupted: Error {}

    @Test func aDeviceThatLosesItsGenerationCannotResumeOrCancel() async throws {
        let f = try LifecycleFixture()
        await #expect(throws: Interrupted.self) {
            try await f.enable { if $0 == .a3 { throw Interrupted() } }
        }
        let original = try #require(f.remote.e2eRows[f.user])
        let firstMarker = try #require(E2EMigrator.marker(in: f.defaults, userId: f.user))
        let suite = "E2EMigratorGenerationTests.\(f.user)"
        let otherDefaults = try #require(UserDefaults(suiteName: suite))
        defer { otherDefaults.removePersistentDomain(forName: suite) }
        otherDefaults.set(f.user.uuidString, forKey: "syncService.lastUserId")
        let other = SyncService(remote: f.remote, userId: f.user, defaults: otherDefaults,
                                e2eLaunchArguments: ["-E2EEnabled", "YES"],
                                e2eBackupDirectory: f.root.appending(path: "other-backup"))

        await #expect(throws: Interrupted.self) {
            try await other.withE2EMigrator(context: f.context, authenticationReason: "",
                                            checkpoint: { if $0 == .a4 { throw Interrupted() } }) {
                try await $0.unlock(.passphrase(LifecycleFixture.phrase))
            }
        }
        let claimed = try #require(f.remote.e2eRows[f.user])
        let secondMarker = try #require(E2EMigrator.marker(in: otherDefaults, userId: f.user))
        #expect(secondMarker.owns(claimed))
        #expect(!firstMarker.owns(claimed))
        #expect(claimed.state == .migrating)

        await #expect(throws: E2EMigrator.Failure.stateChanged) {
            try await f.service.withE2EMigrator(context: f.context, authenticationReason: "") {
                try await $0.resume(firstMarker, row: original)
            }
        }
        await #expect(throws: E2EMigrator.Failure.stateChanged) {
            try await f.service.withE2EMigrator(context: f.context, authenticationReason: "") {
                try await $0.cancelEnable()
            }
        }
        #expect(f.remote.e2eRows[f.user]?.updatedAt == claimed.updatedAt)
    }

    @Test func generationComparisonKeepsPostgresMicroseconds() {
        #expect(E2EServerRow.sameGeneration("2026-11-26T09:00:00.123456Z",
                                            "2026-11-26T09:00:00.123456+00:00"))
        #expect(!E2EServerRow.sameGeneration("2026-11-26T09:00:00.123456Z",
                                             "2026-11-26T09:00:00.123457+00:00"))
    }
}

import Foundation

struct SyncBaseline: Codable {
    static let key = "syncService.baseline"

    let user: UUID
    var tables: [String: Set<UUID>] = [:]
    // A push can run again before a pull removes these rows from the local store.
    var deletedElsewhere: [String: Set<UUID>]? = nil

    static func load(from defaults: UserDefaults, user: UUID) -> Self {
        if let data = defaults.data(forKey: key),
           let baseline = try? JSONDecoder().decode(Self.self, from: data), baseline.user == user {
            return baseline
        }
        return Self(user: user)
    }

    func save(to defaults: UserDefaults) throws {
        defaults.set(try JSONEncoder().encode(self), forKey: Self.key)
    }

    struct Plan {
        let upload: Set<UUID>
        let deleteRemote: Set<UUID>
        let deletedElsewhere: Set<UUID>
        let newBase: Set<UUID>
    }

    static func plan(local: Set<UUID>, remote: Set<UUID>, base: Set<UUID>?,
                     dirty: Set<UUID> = [], fullUpsert: Bool) -> Plan {
        let common = local.intersection(remote)
        let deletedElsewhere = local.subtracting(remote).intersection(base ?? [])
        var upload = fullUpsert ? local : local.intersection(dirty)
        if let base {
            upload.formUnion(local.subtracting(remote).subtracting(base))
        }
        upload.subtract(deletedElsewhere)
        return Plan(upload: upload, deleteRemote: remote.subtracting(local).intersection(base ?? []),
                    deletedElsewhere: deletedElsewhere, newBase: common.union(upload))
    }

    func base(for table: SyncTable, local: Set<UUID>? = nil) -> Set<UUID>? {
        let pending = deletedElsewhere?[table.kind] ?? []
        return tables[table.kind]?.union(pending.intersection(local ?? pending))
    }

    mutating func recordPush(_ plan: Plan, table: SyncTable) {
        tables[table.kind] = plan.newBase
        var pending = deletedElsewhere ?? [:]
        pending[table.kind] = plan.deletedElsewhere.isEmpty ? nil : plan.deletedElsewhere
        deletedElsewhere = pending.isEmpty ? nil : pending
    }
}

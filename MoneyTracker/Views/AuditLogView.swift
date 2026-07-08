import SwiftUI

// MARK: - AuditLogView (PROP-02)
//
// Vista di sola lettura sul registro immutabile delle modifiche — rende visibile
// all'utente il valore di AuditLogger, che altrimenti sarebbe invisibile plumbing.

struct AuditLogView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var entries: [AuditLogger.Entry] = []

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "Nessuna modifica registrata",
                        subtitle: "Ogni modifica ai tuoi dati finanziari apparirà qui."
                    )
                } else {
                    List(entries) { entry in
                        HStack(spacing: DS.Space.m) {
                            Image(systemName: icon(for: entry.action))
                                .font(.system(size: 14))
                                .foregroundStyle(DS.smoke)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.summary == "—" ? entityLabel(entry.entityType) : entry.summary)
                                    .font(.system(size: 14))
                                    .foregroundStyle(DS.ink)
                                Text("\(actionLabel(entry.action)) · \(entry.timestamp.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.system(size: 11))
                                    .foregroundStyle(DS.smoke)
                            }
                        }
                        .listRowBackground(DS.paper)
                        .listRowSeparatorTint(DS.fog)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(DS.paper)
            .navigationTitle("Cronologia modifiche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    GhostButton(title: "Chiudi") { dismiss() }
                }
            }
            .onAppear { entries = AuditLogger.shared.readAll() }
        }
    }

    private func icon(for action: String) -> String {
        switch action {
        case "created": return "plus.circle"
        case "deleted": return "trash"
        default:        return "pencil.circle"
        }
    }

    private func actionLabel(_ action: String) -> String {
        switch action {
        case "created": return String(localized: "Creato")
        case "deleted": return String(localized: "Eliminato")
        default:        return String(localized: "Modificato")
        }
    }

    private func entityLabel(_ entityType: String) -> String {
        switch entityType {
        case "Transaction": return String(localized: "Movimento")
        case "Account":     return String(localized: "Conto")
        case "Budget":      return String(localized: "Budget")
        case "Goal":        return String(localized: "Obiettivo")
        default:            return entityType
        }
    }
}

import SwiftUI

struct SegmentedPill<Selection: Hashable>: View {
    struct Option: Identifiable {
        let id: Selection
        let title: Text
    }
    let options: [Option]
    @Binding var selection: Selection

    var body: some View {
        HStack(spacing: DS.Space.xs) {
            ForEach(options) { option in
                Button { selection = option.id } label: {
                    option.title.font(DS.Typo.rowName)
                        .foregroundStyle(selection == option.id ? DS.ink : DS.smoke)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background {
                            if selection == option.id {
                                Capsule().fill(DS.surface)
                                    .shadow(color: DS.ink.opacity(0.08), radius: 3, y: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == option.id ? [.isSelected] : [])
            }
        }
        .padding(DS.Space.xs)
        .background(DS.fog, in: Capsule())
    }
}

#Preview("Light") {
    @Previewable @State var selection = 0
    SegmentedPill(options: [.init(id: 0, title: Text("Mese")), .init(id: 1, title: Text("Anno"))], selection: $selection)
        .padding().background(DS.paper).environment(\.colorScheme, .light)
}
#Preview("Dark") {
    @Previewable @State var selection = 0
    SegmentedPill(options: [.init(id: 0, title: Text("Mese")), .init(id: 1, title: Text("Anno"))], selection: $selection)
        .padding().background(DS.paper).environment(\.colorScheme, .dark)
}

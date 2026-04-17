import SwiftUI

struct GameSettingsView: View {
    @AppStorage("quarterLengthChoice") private var quarterLengthChoice: String = "medium"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Quarter Length", selection: $quarterLengthChoice) {
                        Text("Short (2-3 min)").tag("short")
                        Text("Medium (4-6 min)").tag("medium")
                        Text("Long (5-8 min)").tag("long")
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Quarter Length")
                } footer: {
                    Text("Controls how long each quarter lasts. Applies to playable games only.")
                }
            }
            .navigationTitle("Game Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

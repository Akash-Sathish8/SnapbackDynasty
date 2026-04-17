import SwiftUI
import SwiftData

/// Stub screen for the transfer portal. Wire up in Phase E.5.
struct TransferPortalView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Card {
                    SectionLabel("Transfer Portal")
                    Text("Portal cycle opens after Early Signing Day. Incoming transfers, outgoing retention, and AI reassignment will show up here.")
                        .font(.lora(11))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
        }
        .background(Color(hex: "#FAF8F4"))
    }
}

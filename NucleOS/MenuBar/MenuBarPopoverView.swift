//
//  MenuBarPopoverView.swift
//  NucleOS
//
//  Placeholder popover shown when the menu bar icon is clicked.
//  Business logic will be added in subsequent issues (NUC-30+).
//

import SwiftUI

/// Placeholder content for the menu bar popover.
///
/// This scaffold satisfies NUC-29: a working popover that launches from the
/// menu bar icon. No data access or business logic lives here yet.
struct MenuBarPopoverView: View {

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.accentLavender)

            Text("NucleOS")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.textPrimary)

            Text("Quick access coming soon.")
                .font(.system(size: 12))
                .foregroundColor(.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(width: 240)
        .background(Color.backgroundCard)
    }
}

#Preview {
    MenuBarPopoverView()
}

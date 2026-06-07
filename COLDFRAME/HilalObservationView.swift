//
//  HilalObservationView.swift
//  COLDFRAME
//

import SwiftUI

struct HilalObservationView: View {
    let visibility: HilalVisibility

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack(spacing: DesignSystem.Spacing.small) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.blue)
                Text("Observation du Hilal ce soir")
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(.blue)
            }

            HStack(spacing: DesignSystem.Spacing.medium) {
                Image(systemName: visibility.icon)
                    .font(.title)
                    .foregroundStyle(visibility.color)

                Text(visibility.rawValue)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
        }
        .padding(DesignSystem.Spacing.normal)
        .background(.thinMaterial)
        .clipShape(.rect(cornerRadius: DesignSystem.Layout.cornerRadius))
    }
}

//
//  MoonPhaseView.swift
//  COLDFRAME
//

import SwiftUI

struct MoonPhaseView: View {
    var moonName: String
    var moonIcon: String
    var illumination: Double

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: moonIcon)
                .font(.system(size: 20))
                .foregroundStyle(.blue)
            Text("\(moonName) • \(illumination.formatted(.percent.precision(.fractionLength(0))))")
                .font(.footnote)
                .bold()
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, DesignSystem.Spacing.normal)
        .padding(.vertical, DesignSystem.Spacing.small)
        .background(.thinMaterial)
        .clipShape(.rect(cornerRadius: DesignSystem.Layout.cornerRadius))
    }
}

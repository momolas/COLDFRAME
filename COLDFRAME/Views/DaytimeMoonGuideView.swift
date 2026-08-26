//
//  DaytimeMoonGuideView.swift
//  COLDFRAME
//

import SwiftUI

struct DaytimeMoonGuideView: View {
    let position: LiveMoonPosition

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            // En-tête
            HStack(spacing: DesignSystem.Spacing.small) {
                Image(systemName: "sun.and.horizon.fill")
                    .foregroundStyle(.yellow)
                Text("Repérer la Lune en plein jour")
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(.yellow)

                Spacer()

                Text(position.isAboveHorizon ? "Dans le ciel" : "Sous l'horizon")
                    .font(.caption2)
                    .bold()
                    .foregroundStyle(position.isAboveHorizon ? .cyan : .secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(position.isAboveHorizon ? Color.cyan.opacity(0.2) : Color.white.opacity(0.1))
                    .clipShape(.capsule)
            }

            // Repères visuels
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: DesignSystem.Spacing.small) {
                    Image(systemName: "safari.fill")
                        .font(.caption)
                        .foregroundStyle(.cyan)
                    Text("Direction : ")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    + Text(position.formattedAzimuth)
                        .font(.caption).bold()
                        .foregroundStyle(.white)
                }

                HStack(spacing: DesignSystem.Spacing.small) {
                    Image(systemName: "arrow.up.and.down.and.sparkles")
                        .font(.caption)
                        .foregroundStyle(.cyan)
                    Text("Élévation : ")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    + Text("\(position.formattedAltitude) • \(position.elevationHandGuideText)")
                        .font(.caption).bold()
                        .foregroundStyle(.white)
                }

                HStack(alignment: .top, spacing: DesignSystem.Spacing.small) {
                    Image(systemName: "sun.max.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                    Text(position.relativeSunPositionText)
                        .font(.caption2)
                        .foregroundStyle(.yellow.opacity(0.9))
                }
            }
            .padding(DesignSystem.Spacing.small)
            .background(.black.opacity(0.2))
            .clipShape(.rect(cornerRadius: DesignSystem.Layout.cornerRadius / 1.5))

            // Conseil pratique
            HStack(spacing: 4) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                Text("Basculez le téléphone en mode paysage pour voir la Lune et sa trajectoire en réalité augmentée.")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(DesignSystem.Spacing.normal)
        .background(.thinMaterial)
        .clipShape(.rect(cornerRadius: DesignSystem.Layout.cornerRadius))
    }
}

//
//  HilalObservationView.swift
//  COLDFRAME
//

import SwiftUI

struct HilalObservationView: View {
    let data: HilalObservationData
    @State private var isTerrainExpanded: Bool = false

    init(data: HilalObservationData) {
        self.data = data
    }

    init(visibility: HilalVisibility) {
        self.data = HilalObservationData(visibility: visibility)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            // En-tête
            HStack(spacing: DesignSystem.Spacing.small) {
                if data.isAnalyzingTerrain {
                    ProgressView()
                        .controlSize(.mini)
                }
            }

            // Statut principal
            HStack(spacing: DesignSystem.Spacing.medium) {
                Image(systemName: data.visibility.icon)
                    .font(.title)
                    .foregroundStyle(data.visibility.color)

                Text(data.visibility.rawValue)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }

            // Données d'orientation (Azimut, Altitude Lune, Altitude Observateur)
            if data.azimuthDegrees > 0 {
                HStack(spacing: DesignSystem.Spacing.small) {
                    HilalMetricBadge(
                        title: "Cap (Azimut)",
                        value: data.formattedAzimuth,
                        icon: "safari.fill"
                    )

                    HilalMetricBadge(
                        title: "Élévation Lune",
                        value: data.formattedMoonAltitude,
                        icon: "arrow.up.right"
                    )

                    HilalMetricBadge(
                        title: "Altitude GPS",
                        value: "\(data.observerAltitudeMeters.formatted(.number.precision(.fractionLength(0)))) m",
                        icon: "mountain.2.fill"
                    )
                }
            }

            // Profil altimétrique 3D (Dépliable)
            if let profile = data.terrainProfile {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isTerrainExpanded.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: "mountain.2")
                                .foregroundStyle(profile.isObstructed ? .orange : .green)
                            Text(profile.summaryText)
                                .font(.caption2)
                                .bold()
                                .foregroundStyle(profile.isObstructed ? .orange : .green)
                            Spacer()
                            Image(systemName: isTerrainExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Détails du profil altimétrique 3D")
                    .accessibilityValue(isTerrainExpanded ? "Déplié" : "Replié")

                    if isTerrainExpanded {
                        ElevationProfileView(profile: profile)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            } else if !data.isAnalyzingTerrain {
                HStack(spacing: DesignSystem.Spacing.small) {
                    Image(systemName: "info.circle")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("Privilégiez un point d'observation en hauteur face à l'Ouest.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(DesignSystem.Spacing.normal)
        .background(.thinMaterial)
        .clipShape(.rect(cornerRadius: DesignSystem.Layout.cornerRadius))
    }
}

private struct HilalMetricBadge: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.caption2)
                .bold()
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(6)
        .background(.black.opacity(0.2))
        .clipShape(.rect(cornerRadius: 6))
    }
}

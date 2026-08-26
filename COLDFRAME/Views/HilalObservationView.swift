//
//  HilalObservationView.swift
//  COLDFRAME
//
//  Created by Mo on 26/08/2026.
//

import SwiftUI

struct HilalObservationView: View {
    let data: HilalObservationData
    @State private var isTerrainExpanded: Bool = false
    @State private var isScientificExpanded: Bool = false

    init(data: HilalObservationData) {
        self.data = data
    }

    init(visibility: HilalVisibility) {
        self.data = HilalObservationData(visibility: visibility)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            // Statut principal & Badge Yallop
            HStack(spacing: DesignSystem.Spacing.medium) {
                Image(systemName: data.visibility.icon)
                    .font(.title2)
                    .foregroundStyle(data.visibility.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(data.visibility.rawValue)
                        .font(.footnote)
                        .bold()
                        .foregroundStyle(.white.opacity(0.95))
                        .fixedSize(horizontal: false, vertical: true)

                    if data.odehZone != "D" && data.visibility != .notObservationDay {
                        Text("Critère Odeh (2004) : Zone \(data.odehZone) (V = \(data.odehVValue.formatted(.number.precision(.fractionLength(2)))))")
                            .font(.caption2)
                            .foregroundStyle(.cyan.opacity(0.9))
                    }
                }

                Spacer()

                if data.isAnalyzingTerrain || data.isFetchingWeather {
                    ProgressView()
                        .controlSize(.mini)
                }
            }

            // Ligne 1 : Fenêtre d'Observation Optimale & Moon Lag
            if data.moonLagMinutes > 0 || data.bestObservationTime != nil {
                HStack(spacing: DesignSystem.Spacing.small) {
                    HilalMetricBadge(
                        title: "Heure Optimale",
                        value: data.formattedBestObservationTime,
                        icon: "clock.badge.checkmark"
                    )

                    HilalMetricBadge(
                        title: "Moon Lag (Retard)",
                        value: "\(Int(data.moonLagMinutes.rounded())) min",
                        icon: "timer"
                    )

                    HilalMetricBadge(
                        title: "Élongation",
                        value: "\(data.elongationDegrees.formatted(.number.precision(.fractionLength(1))))°",
                        icon: "arrow.left.and.right"
                    )
                }
            }

            // Ligne 2 : Orientation & Position (Azimut, Altitude Lune, Altitude Observateur)
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

            // Ligne 3 : Conditions Météo Crépusculaires
            if let weather = data.weatherConditions {
                HStack(spacing: DesignSystem.Spacing.small) {
                    Image(systemName: weather.seeingIcon)
                        .font(.caption)
                        .foregroundStyle(weather.seeingScore >= 70 ? .green : (weather.seeingScore >= 40 ? .orange : .red))

                    Text("Clarté ciel : \(weather.seeingScore)% (\(weather.seeingDescription)) • Nuages : \(weather.cloudCoverTotalPercent)%")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.85))

                    Spacer()
                }
                .padding(8)
                .background(.black.opacity(0.25))
                .clipShape(.rect(cornerRadius: 6))
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
            }

            // Volet dépliable : Données astronomiques scientifiques
            if data.crescentWidthArcminutes > 0 {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isScientificExpanded.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: "function")
                                .foregroundStyle(.cyan)
                            Text("Détails scientifiques (Yallop / ARCV / W)")
                                .font(.caption2)
                                .bold()
                                .foregroundStyle(.cyan)
                            Spacer()
                            Image(systemName: isScientificExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    if isScientificExpanded {
                        ScientificDetailsGrid(data: data)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.normal)
        .background(.thinMaterial)
        .clipShape(.rect(cornerRadius: DesignSystem.Layout.cornerRadius))
    }
}

private struct ScientificDetailsGrid: View {
    let data: HilalObservationData

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
            GridRow {
                Text("Odeh V (2004):")
                    .font(.caption2)
                    .foregroundStyle(.cyan)
                Text("\(data.odehVValue.formatted(.number.precision(.fractionLength(2)))) (Zone \(data.odehZone))")
                    .font(.caption2)
                    .bold()
                    .foregroundStyle(.cyan)

                Text("Yallop q (1997):")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(data.yallopQValue.formatted(.number.precision(.fractionLength(2)))) (Zone \(data.yallopZone))")
                    .font(.caption2)
                    .bold()
                    .foregroundStyle(.white)
            }

            GridRow {
                Text("Arc of Vision (ARCV):")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(data.arcOfVisionDegrees.formatted(.number.precision(.fractionLength(2))))°")
                    .font(.caption2)
                    .bold()
                    .foregroundStyle(.white)

                Text("Diff. Azimut (DAZ):")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(data.azimuthDifferenceDegrees.formatted(.number.precision(.fractionLength(2))))°")
                    .font(.caption2)
                    .bold()
                    .foregroundStyle(.white)
            }

            GridRow {
                Text("Largeur croissant (W):")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(data.crescentWidthArcminutes.formatted(.number.precision(.fractionLength(2))))'")
                    .font(.caption2)
                    .bold()
                    .foregroundStyle(.white)

                Text("Âge de la Lune:")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(data.moonAgeHours.formatted(.number.precision(.fractionLength(1)))) h")
                    .font(.caption2)
                    .bold()
                    .foregroundStyle(.white)
            }
        }
        .padding(8)
        .background(.black.opacity(0.3))
        .clipShape(.rect(cornerRadius: 6))
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

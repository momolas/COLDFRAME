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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                    Text(data.visibility.localizedTitle)
                        .font(.footnote)
                        .bold()
                        .foregroundStyle(.white.opacity(0.95))
                        .fixedSize(horizontal: false, vertical: true)

                    if data.odehZone != "D" && data.visibility != .notObservationDay {
                        let vStr = data.odehVValue.formatted(.number.precision(.fractionLength(2)))
                        Text("odeh_criterion_format \(data.odehZone) \(vStr)")
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
                        titleKey: "metric_best_time",
                        value: data.formattedBestObservationTime,
                        icon: "clock.badge.checkmark"
                    )

                    HilalMetricBadge(
                        titleKey: "metric_moon_lag",
                        value: "\(Int(data.moonLagMinutes.rounded())) min",
                        icon: "timer"
                    )

                    HilalMetricBadge(
                        titleKey: "metric_elongation",
                        value: "\(data.elongationDegrees.formatted(.number.precision(.fractionLength(1))))°",
                        icon: "arrow.left.and.right"
                    )
                }
            }

            // Ligne 2 : Orientation & Position (Azimut, Altitude Lune, Altitude Observateur)
            if data.azimuthDegrees > 0 {
                HStack(spacing: DesignSystem.Spacing.small) {
                    HilalMetricBadge(
                        titleKey: "metric_bearing",
                        value: data.formattedAzimuth,
                        icon: "safari.fill"
                    )

                    HilalMetricBadge(
                        titleKey: "metric_moon_altitude",
                        value: data.formattedMoonAltitude,
                        icon: "arrow.up.right"
                    )

                    HilalMetricBadge(
                        titleKey: "metric_gps_altitude",
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

                    let seeingScoreInt = Int64(weather.seeingScore)
                    let cloudsInt = Int64(weather.cloudCoverTotalPercent)
                    Text("weather_sky_clarity \(seeingScoreInt) \(weather.seeingDescription) \(cloudsInt)")
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
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
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
                    .accessibilityLabel("terrain_accessibility_label")
                    .accessibilityValue(isTerrainExpanded ? String(localized: "state_expanded") : String(localized: "state_collapsed"))

                    if isTerrainExpanded {
                        ElevationProfileView(profile: profile)
                            .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
                    }
                }
            }

            // Volet dépliable : Données astronomiques scientifiques
            if data.crescentWidthArcminutes > 0 {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    Button(action: {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                            isScientificExpanded.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: "function")
                                .foregroundStyle(.cyan)
                            Text("scientific_details_button")
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
                            .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
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
                Text("scientific_odeh")
                    .font(.caption2)
                    .foregroundStyle(.cyan)
                Text("\(data.odehVValue.formatted(.number.precision(.fractionLength(2)))) (Zone \(data.odehZone))")
                    .font(.caption2)
                    .bold()
                    .foregroundStyle(.cyan)

                Text("scientific_yallop")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(data.yallopQValue.formatted(.number.precision(.fractionLength(2)))) (Zone \(data.yallopZone))")
                    .font(.caption2)
                    .bold()
                    .foregroundStyle(.white)
            }

            GridRow {
                Text("scientific_arcv")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(data.arcOfVisionDegrees.formatted(.number.precision(.fractionLength(2))))°")
                    .font(.caption2)
                    .bold()
                    .foregroundStyle(.white)

                Text("scientific_daz")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(data.azimuthDifferenceDegrees.formatted(.number.precision(.fractionLength(2))))°")
                    .font(.caption2)
                    .bold()
                    .foregroundStyle(.white)
            }

            GridRow {
                Text("scientific_crescent_width")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(data.crescentWidthArcminutes.formatted(.number.precision(.fractionLength(2))))'")
                    .font(.caption2)
                    .bold()
                    .foregroundStyle(.white)

                Text("scientific_moon_age")
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
    let titleKey: LocalizedStringKey
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                Text(titleKey)
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

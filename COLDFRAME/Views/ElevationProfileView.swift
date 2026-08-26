//
//  ElevationProfileView.swift
//  COLDFRAME
//

import SwiftUI

struct ElevationProfileView: View {
    let profile: TerrainProfile

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack {
                Label("Profil Topographique 3D", systemImage: "mountain.2")
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.secondary)

                Spacer()

                Text(profile.summaryText)
                    .font(.caption2)
                    .bold()
                    .foregroundStyle(profile.isObstructed ? .orange : .green)
            }

            // Canvas de rendu de la coupe géométrique
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height

                let minAlt = min(
                    profile.observerAltitudeMeters,
                    profile.points.map(\.elevationMeters).min() ?? 0.0
                )
                let maxAlt = max(
                    profile.observerAltitudeMeters + 100.0,
                    (profile.points.map(\.elevationMeters).max() ?? 100.0) + 50.0
                )
                let altRange = max(1.0, maxAlt - minAlt)
                let maxDist = max(1.0, profile.points.last?.distanceKm ?? 30.0)

                Canvas { context, size in
                    // 1. Grille d'horizon de référence
                    let zeroY = size.height - CGFloat((profile.observerAltitudeMeters - minAlt) / altRange) * (size.height - 20) - 10
                    var horizonPath = Path()
                    horizonPath.move(to: CGPoint(x: 0, y: zeroY))
                    horizonPath.addLine(to: CGPoint(x: size.width, y: zeroY))
                    context.stroke(
                        horizonPath,
                        with: .color(.white.opacity(0.15)),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                    )

                    // 2. Tracé de la ligne de visée de la Lune
                    let moonAngleRad = profile.moonAltitudeDegrees * .pi / 180.0
                    // Pente visuelle mise à l'échelle
                    let moonTargetY = zeroY - CGFloat(tan(moonAngleRad) * 30000.0 / altRange) * (size.height - 20)
                    var sightPath = Path()
                    sightPath.move(to: CGPoint(x: 0, y: zeroY))
                    sightPath.addLine(to: CGPoint(x: size.width, y: max(0, min(size.height, moonTargetY))))
                    context.stroke(
                        sightPath,
                        with: .color(profile.isObstructed ? .orange.opacity(0.6) : .yellow.opacity(0.8)),
                        style: StrokeStyle(lineWidth: 1.5, dash: [3, 3])
                    )

                    // 3. Dessin de la coupe du terrain (remplissage + ligne de crête)
                    if !profile.points.isEmpty {
                        var terrainPath = Path()
                        let firstPt = profile.points[0]
                        let firstX: CGFloat = 0.0
                        let firstY = size.height - CGFloat((firstPt.elevationMeters - minAlt) / altRange) * (size.height - 20) - 10

                        terrainPath.move(to: CGPoint(x: firstX, y: size.height))
                        terrainPath.addLine(to: CGPoint(x: firstX, y: firstY))

                        for pt in profile.points.dropFirst() {
                            let x = CGFloat(pt.distanceKm / maxDist) * size.width
                            let y = size.height - CGFloat((pt.elevationMeters - minAlt) / altRange) * (size.height - 20) - 10
                            terrainPath.addLine(to: CGPoint(x: x, y: y))
                        }

                        terrainPath.addLine(to: CGPoint(x: size.width, y: size.height))
                        terrainPath.closeSubpath()

                        context.fill(
                            terrainPath,
                            with: .linearGradient(
                                Gradient(colors: [
                                    Color.blue.opacity(0.35),
                                    Color.indigo.opacity(0.15),
                                    Color.clear
                                ]),
                                startPoint: CGPoint(x: 0, y: 0),
                                endPoint: CGPoint(x: 0, y: size.height)
                            )
                        )

                        // Ligne de crête
                        var ridgePath = Path()
                        ridgePath.move(to: CGPoint(x: firstX, y: firstY))
                        for pt in profile.points.dropFirst() {
                            let x = CGFloat(pt.distanceKm / maxDist) * size.width
                            let y = size.height - CGFloat((pt.elevationMeters - minAlt) / altRange) * (size.height - 20) - 10
                            ridgePath.addLine(to: CGPoint(x: x, y: y))
                        }
                        context.stroke(
                            ridgePath,
                            with: .color(profile.isObstructed ? .orange : .cyan),
                            lineWidth: 1.8
                        )
                    }

                    // 4. Point observateur à gauche
                    context.fill(
                        Path(ellipseIn: CGRect(x: -3, y: zeroY - 3, width: 6, height: 6)),
                        with: .color(.white)
                    )
                }
            }
            .frame(height: 70)

            // Légende des distances
            HStack {
                Text("Observateur (0 km)")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Ligne de visée Lune (\(profile.moonAltitudeDegrees >= 0 ? "+" : "")\(profile.moonAltitudeDegrees.formatted(.number.precision(.fractionLength(1))))°)")
                    .font(.system(size: 9))
                    .foregroundStyle(.yellow.opacity(0.8))

                Spacer()

                Text("Horizon (30 km)")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(DesignSystem.Spacing.small)
        .background(.black.opacity(0.25))
        .clipShape(.rect(cornerRadius: DesignSystem.Layout.cornerRadius / 1.5))
    }
}

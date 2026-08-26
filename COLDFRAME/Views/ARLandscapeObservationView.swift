//
//  ARLandscapeObservationView.swift
//  COLDFRAME
//

import SwiftUI

struct ARLandscapeObservationView: View {
    var qiblaManager: QiblaManager
    @State private var motionManager = MotionManager()

    // Champ de vision (FOV) moyen pour la caméra standard iPhone
    private let fovHorizontal: Double = 65.0
    private let fovVertical: Double = 45.0

    var body: some View {
        ZStack {
            // 1. Flux Caméra
            ARCameraView()
                .ignoresSafeArea()

            // 2. Calque Graphique AR (Canvas)
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let currentYaw = motionManager.yawDegrees
                let currentPitch = motionManager.pitchDegrees

                Canvas { context, size in
                    // A. Ligne d'horizon de référence (Altitude 0°)
                    let horizonY = projectY(altitude: 0.0, pitch: currentPitch, screenHeight: size.height)
                    if horizonY >= -50 && horizonY <= size.height + 50 {
                        var horizonPath = Path()
                        horizonPath.move(to: CGPoint(x: 0, y: horizonY))
                        horizonPath.addLine(to: CGPoint(x: size.width, y: horizonY))
                        context.stroke(
                            horizonPath,
                            with: .color(.cyan.opacity(0.4)),
                            style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                        )
                    }

                    // B. Profil de relief MNT (si disponible)
                    if let profile = qiblaManager.hilalObservation.terrainProfile, !profile.points.isEmpty {
                        var terrainPath = Path()
                        var started = false

                        for pt in profile.points {
                            let ptX = projectX(azimuth: qiblaManager.hilalObservation.azimuthDegrees, yaw: currentYaw, screenWidth: size.width)
                            let ptY = projectY(altitude: pt.angleDegrees, pitch: currentPitch, screenHeight: size.height)

                            if !started {
                                terrainPath.move(to: CGPoint(x: ptX, y: ptY))
                                started = true
                            } else {
                                terrainPath.addLine(to: CGPoint(x: ptX, y: ptY))
                            }
                        }

                        context.stroke(
                            terrainPath,
                            with: .color(.orange.opacity(0.8)),
                            lineWidth: 2.0
                        )
                    }

                    // C. Arc de Trajectoire de la Lune
                    let trajectory = qiblaManager.liveMoonPosition.trajectory
                    if trajectory.count > 1 {
                        var arcPath = Path()
                        var arcStarted = false

                        for pt in trajectory {
                            let x = projectX(azimuth: pt.azimuthDegrees, yaw: currentYaw, screenWidth: size.width)
                            let y = projectY(altitude: pt.altitudeDegrees, pitch: currentPitch, screenHeight: size.height)

                            // On relie les points
                            if !arcStarted {
                                arcPath.move(to: CGPoint(x: x, y: y))
                                arcStarted = true
                            } else {
                                arcPath.addLine(to: CGPoint(x: x, y: y))
                            }
                        }

                        // Tracé de la courbe céleste
                        context.stroke(
                            arcPath,
                            with: .color(.cyan.opacity(0.7)),
                            style: StrokeStyle(lineWidth: 2.0, dash: [4, 4])
                        )
                    }

                    // D. Position du Soleil (si visible dans le champ)
                    let sunAz = qiblaManager.liveMoonPosition.sunAzimuthDegrees
                    let sunAlt = qiblaManager.liveMoonPosition.sunAltitudeDegrees
                    let sunX = projectX(azimuth: sunAz, yaw: currentYaw, screenWidth: size.width)
                    let sunY = projectY(altitude: sunAlt, pitch: currentPitch, screenHeight: size.height)

                    if isPointInScreen(x: sunX, y: sunY, width: size.width, height: size.height) {
                        let sunRect = CGRect(x: sunX - 16, y: sunY - 16, width: 32, height: 32)
                        context.fill(Path(ellipseIn: sunRect), with: .color(.yellow.opacity(0.4)))
                        context.stroke(Path(ellipseIn: sunRect), with: .color(.yellow), lineWidth: 2)
                    }

                    // E. Position actuelle de la Lune
                    let moonAz = qiblaManager.liveMoonPosition.azimuthDegrees
                    let moonAlt = qiblaManager.liveMoonPosition.altitudeDegrees
                    let moonX = projectX(azimuth: moonAz, yaw: currentYaw, screenWidth: size.width)
                    let moonY = projectY(altitude: moonAlt, pitch: currentPitch, screenHeight: size.height)

                    if isPointInScreen(x: moonX, y: moonY, width: size.width, height: size.height) {
                        let moonHalo = CGRect(x: moonX - 22, y: moonY - 22, width: 44, height: 44)
                        context.fill(Path(ellipseIn: moonHalo), with: .color(.cyan.opacity(0.3)))
                        context.stroke(Path(ellipseIn: moonHalo), with: .color(.cyan), lineWidth: 2)
                    }
                }

                // 3. Éléments SwiftUI interactifs en surimpression (Lune, Soleil, Cibles)
                let moonX = projectX(azimuth: qiblaManager.liveMoonPosition.azimuthDegrees, yaw: currentYaw, screenWidth: width)
                let moonY = projectY(altitude: qiblaManager.liveMoonPosition.altitudeDegrees, pitch: currentPitch, screenHeight: height)

                if isPointInScreen(x: moonX, y: moonY, width: width, height: height) {
                    VStack(spacing: 2) {
                        Image(systemName: "moonphase.waxing.crescent")
                            .font(.title2)
                            .foregroundStyle(.cyan)
                            .shadow(color: .cyan, radius: 8)

                        Text("Lune (\(qiblaManager.liveMoonPosition.formattedAltitude))")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.black.opacity(0.6))
                            .clipShape(.capsule)
                    }
                    .position(x: moonX, y: moonY - 30)
                }

                // Soleil
                let sunX = projectX(azimuth: qiblaManager.liveMoonPosition.sunAzimuthDegrees, yaw: currentYaw, screenWidth: width)
                let sunY = projectY(altitude: qiblaManager.liveMoonPosition.sunAltitudeDegrees, pitch: currentPitch, screenHeight: height)

                if isPointInScreen(x: sunX, y: sunY, width: width, height: height) {
                    VStack(spacing: 2) {
                        Image(systemName: "sun.max.fill")
                            .font(.title2)
                            .foregroundStyle(.yellow)
                            .shadow(color: .yellow, radius: 10)

                        Text("Soleil")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.yellow)
                    }
                    .position(x: sunX, y: sunY - 25)
                }
            }

            // 4. Bandeau supérieur boussole (Compass Ribbon)
            VStack {
                HStack {
                    // Badge Mode RA
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("MODE RA • PEAKFINDER")
                            .font(.caption2)
                            .bold()
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.6))
                    .clipShape(.capsule)

                    Spacer()

                    // Indicateur de Cap & Altitude
                    HStack(spacing: DesignSystem.Spacing.medium) {
                        Label(
                            "Cap: \(motionManager.yawDegrees.formatted(.number.precision(.fractionLength(0))))°",
                            systemImage: "safari.fill"
                        )
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.white)

                        Label(
                            "Inclinaison: \(motionManager.pitchDegrees.formatted(.number.precision(.fractionLength(0))))°",
                            systemImage: "gyroscope"
                        )
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.6))
                    .clipShape(.capsule)
                }
                .padding(.horizontal)
                .padding(.top, 10)

                Spacer()

                // 5. Bandeau inférieur d'information et de guidage
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cible : Lune (\(qiblaManager.liveMoonPosition.formattedAzimuth) • \(qiblaManager.liveMoonPosition.formattedAltitude))")
                            .font(.caption)
                            .bold()
                            .foregroundStyle(.cyan)
                        Text(qiblaManager.liveMoonPosition.relativeSunPositionText)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    Spacer()

                    Text("Tournez l'appareil vers l'horizon pour aligner la visée")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, DesignSystem.Spacing.normal)
                .padding(.vertical, DesignSystem.Spacing.small)
                .background(.thinMaterial)
                .clipShape(.rect(cornerRadius: DesignSystem.Layout.cornerRadius))
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }
        .onAppear {
            motionManager.startTracking()
        }
        .onDisappear {
            motionManager.stopTracking()
        }
    }

    // MARK: - Fonctions de Projection Mathématique 3D -> 2D
    private func projectX(azimuth: Double, yaw: Double, screenWidth: CGFloat) -> CGFloat {
        var diff = azimuth - yaw
        while diff > 180.0 { diff -= 360.0 }
        while diff < -180.0 { diff += 360.0 }
        let normalized = diff / fovHorizontal
        return (screenWidth / 2.0) + CGFloat(normalized) * screenWidth
    }

    private func projectY(altitude: Double, pitch: Double, screenHeight: CGFloat) -> CGFloat {
        let diff = altitude - pitch
        let normalized = diff / fovVertical
        return (screenHeight / 2.0) - CGFloat(normalized) * screenHeight
    }

    private func isPointInScreen(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> Bool {
        x >= -30 && x <= width + 30 && y >= -30 && y <= height + 30
    }
}

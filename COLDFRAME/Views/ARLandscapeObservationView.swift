//
//  ARLandscapeObservationView.swift
//  COLDFRAME
//
//  Created by Mo on 26/08/2026.
//

import SwiftUI

struct ARLandscapeObservationView: View {
    var qiblaManager: QiblaManager
    @State private var motionManager = MotionManager()

    // Champ de vision (FOV) moyen pour la caméra standard iPhone
    private let fovHorizontal: Double = 65.0
    private let fovVertical: Double = 45.0

    // Couleurs dynamiques selon le mode Vision Nocturne
    private var primaryColor: Color {
        qiblaManager.isNightVisionMode ? Color(red: 1.0, green: 0.25, blue: 0.25) : .cyan
    }

    private var secondaryColor: Color {
        qiblaManager.isNightVisionMode ? Color(red: 0.8, green: 0.15, blue: 0.15) : .white
    }

    private var accentSunColor: Color {
        qiblaManager.isNightVisionMode ? Color(red: 1.0, green: 0.45, blue: 0.2) : .yellow
    }

    var body: some View {
        ZStack {
            // 1. Flux Caméra
            ARCameraView()
                .ignoresSafeArea()

            // Filtre rouge pour la préservation de la vision nocturne
            if qiblaManager.isNightVisionMode {
                Color.red.opacity(0.28)
                    .blendMode(.multiply)
                    .ignoresSafeArea()
            }

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
                            with: .color(primaryColor.opacity(0.4)),
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
                            with: .color(qiblaManager.isNightVisionMode ? .red.opacity(0.9) : .orange.opacity(0.8)),
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

                            if !arcStarted {
                                arcPath.move(to: CGPoint(x: x, y: y))
                                arcStarted = true
                            } else {
                                arcPath.addLine(to: CGPoint(x: x, y: y))
                            }
                        }

                        context.stroke(
                            arcPath,
                            with: .color(primaryColor.opacity(0.7)),
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
                        context.fill(Path(ellipseIn: sunRect), with: .color(accentSunColor.opacity(0.4)))
                        context.stroke(Path(ellipseIn: sunRect), with: .color(accentSunColor), lineWidth: 2)
                    }

                    // E. Position actuelle de la Lune
                    let moonAz = qiblaManager.liveMoonPosition.azimuthDegrees
                    let moonAlt = qiblaManager.liveMoonPosition.altitudeDegrees
                    let moonX = projectX(azimuth: moonAz, yaw: currentYaw, screenWidth: size.width)
                    let moonY = projectY(altitude: moonAlt, pitch: currentPitch, screenHeight: size.height)

                    if isPointInScreen(x: moonX, y: moonY, width: size.width, height: size.height) {
                        let moonHalo = CGRect(x: moonX - 22, y: moonY - 22, width: 44, height: 44)
                        context.fill(Path(ellipseIn: moonHalo), with: .color(primaryColor.opacity(0.3)))
                        context.stroke(Path(ellipseIn: moonHalo), with: .color(primaryColor), lineWidth: 2)

                        // F. Réticule Optique (Simulation FOV Jumelles 7x50 ~ 7.0°)
                        if qiblaManager.showOpticalReticle {
                            let fovRadius = (7.0 / fovHorizontal) * size.width / 2.0
                            let reticleRect = CGRect(
                                x: moonX - fovRadius,
                                y: moonY - fovRadius,
                                width: fovRadius * 2,
                                height: fovRadius * 2
                            )
                            context.stroke(
                                Path(ellipseIn: reticleRect),
                                with: .color(primaryColor.opacity(0.75)),
                                style: StrokeStyle(lineWidth: 1.5, dash: [8, 4])
                            )

                            // Croix de centrage
                            var crossPath = Path()
                            crossPath.move(to: CGPoint(x: moonX - 12, y: moonY))
                            crossPath.addLine(to: CGPoint(x: moonX + 12, y: moonY))
                            crossPath.move(to: CGPoint(x: moonX, y: moonY - 12))
                            crossPath.addLine(to: CGPoint(x: moonX, y: moonY + 12))
                            context.stroke(crossPath, with: .color(primaryColor.opacity(0.85)), lineWidth: 1.0)
                        }
                    }
                }

                // 3. Éléments SwiftUI interactifs en surimpression (Lune, Soleil)
                let moonX = projectX(azimuth: qiblaManager.liveMoonPosition.azimuthDegrees, yaw: currentYaw, screenWidth: width)
                let moonY = projectY(altitude: qiblaManager.liveMoonPosition.altitudeDegrees, pitch: currentPitch, screenHeight: height)

                if isPointInScreen(x: moonX, y: moonY, width: width, height: height) {
                    VStack(spacing: 2) {
                        Image(systemName: "moonphase.waxing.crescent")
                            .font(.title2)
                            .foregroundStyle(primaryColor)
                            .shadow(color: primaryColor, radius: 8)

                        Text("Lune (\(qiblaManager.liveMoonPosition.formattedAltitude))")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(secondaryColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.black.opacity(0.65))
                            .clipShape(.capsule)

                        if qiblaManager.showOpticalReticle {
                            Text("FOV Jumelles 7x50 (7°)")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(primaryColor)
                        }
                    }
                    .position(x: moonX, y: moonY - 34)
                }

                // Soleil
                let sunX = projectX(azimuth: qiblaManager.liveMoonPosition.sunAzimuthDegrees, yaw: currentYaw, screenWidth: width)
                let sunY = projectY(altitude: qiblaManager.liveMoonPosition.sunAltitudeDegrees, pitch: currentPitch, screenHeight: height)

                if isPointInScreen(x: sunX, y: sunY, width: width, height: height) {
                    VStack(spacing: 2) {
                        Image(systemName: "sun.max.fill")
                            .font(.title2)
                            .foregroundStyle(accentSunColor)
                            .shadow(color: accentSunColor, radius: 10)

                        Text("Soleil")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(accentSunColor)
                    }
                    .position(x: sunX, y: sunY - 25)
                }
            }

            // 4. Bandeau supérieur avec commandes de terrain
            VStack {
                HStack(spacing: DesignSystem.Spacing.small) {
                    // Badge Mode RA
                    HStack(spacing: 6) {
                        Circle()
                            .fill(qiblaManager.isNightVisionMode ? .red : .green)
                            .frame(width: 8, height: 8)
                        Text(qiblaManager.isNightVisionMode ? "VISION NOCTURNE" : "MODE RA • PEAKFINDER")
                            .font(.caption2)
                            .bold()
                            .foregroundStyle(secondaryColor)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.65))
                    .clipShape(.capsule)

                    // Bouton Bascule Vision Nocturne
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            qiblaManager.isNightVisionMode.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: qiblaManager.isNightVisionMode ? "moon.stars.fill" : "moon.fill")
                                .foregroundStyle(qiblaManager.isNightVisionMode ? .red : .secondary)
                            Text(qiblaManager.isNightVisionMode ? "Filtre Rouge ON" : "Vision Nuit")
                                .font(.caption2)
                                .bold()
                                .foregroundStyle(qiblaManager.isNightVisionMode ? .red : .secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.black.opacity(0.65))
                        .clipShape(.capsule)
                    }
                    .buttonStyle(.plain)

                    // Bouton Réticule Optique (Jumelles)
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            qiblaManager.showOpticalReticle.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "circle.circle")
                                .foregroundStyle(qiblaManager.showOpticalReticle ? primaryColor : .secondary)
                            Text("FOV 7°")
                                .font(.caption2)
                                .bold()
                                .foregroundStyle(qiblaManager.showOpticalReticle ? primaryColor : .secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(.black.opacity(0.65))
                        .clipShape(.capsule)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Indicateur de Cap & Altitude
                    HStack(spacing: DesignSystem.Spacing.medium) {
                        Label(
                            "Cap: \(motionManager.yawDegrees.formatted(.number.precision(.fractionLength(0))))°",
                            systemImage: "safari.fill"
                        )
                        .font(.caption)
                        .bold()
                        .foregroundStyle(secondaryColor)

                        Label(
                            "Inclinaison: \(motionManager.pitchDegrees.formatted(.number.precision(.fractionLength(0))))°",
                            systemImage: "gyroscope"
                        )
                        .font(.caption)
                        .bold()
                        .foregroundStyle(secondaryColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.65))
                    .clipShape(.capsule)
                }
                .padding(.horizontal)
                .padding(.top, 10)

                Spacer()

                // 5. Bandeau inférieur d'information, météo et guidage
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cible : Lune (\(qiblaManager.liveMoonPosition.formattedAzimuth) • \(qiblaManager.liveMoonPosition.formattedAltitude))")
                            .font(.caption)
                            .bold()
                            .foregroundStyle(primaryColor)

                        if let weather = qiblaManager.hilalObservation.weatherConditions {
                            Text("Météo : \(weather.seeingScore)% clarté (\(weather.seeingDescription)) • Nuages \(weather.cloudCoverTotalPercent)%")
                                .font(.caption2)
                                .foregroundStyle(secondaryColor.opacity(0.85))
                        } else {
                            Text(qiblaManager.liveMoonPosition.relativeSunPositionText)
                                .font(.caption2)
                                .foregroundStyle(secondaryColor.opacity(0.8))
                        }
                    }

                    Spacer()

                    if let bestTime = qiblaManager.hilalObservation.bestObservationTime {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Créneau optimal : \(bestTime.formatted(date: .omitted, time: .shortened))")
                                .font(.caption2)
                                .bold()
                                .foregroundStyle(primaryColor)
                            Text("Lag : +\(Int(qiblaManager.hilalObservation.moonLagMinutes.rounded())) min")
                                .font(.caption2)
                                .foregroundStyle(secondaryColor.opacity(0.8))
                        }
                    }
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

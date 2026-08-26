//
//  ARLandscapeObservationView.swift
//  COLDFRAME
//
//  Created by Mo on 26/08/2026.
//

import SwiftUI

/// Mode d'affichage façon PeakFinder :
/// - Panorama 3D vectoriel complet multi-strates (ciel crépusculaire / nuit avec crêtes étagées ombrées)
/// - Réalité Augmentée avec superposition caméra en direct
enum PeakFinderDisplayMode: String, CaseIterable, Identifiable {
    case panorama = "Panorama 3D"
    case cameraAR = "Caméra RA"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .panorama: return "mountain.2.fill"
        case .cameraAR: return "camera.viewfinder"
        }
    }
}

struct ARLandscapeObservationView: View {
    var qiblaManager: QiblaManager
    @State private var motionManager = MotionManager()
    @State private var displayMode: PeakFinderDisplayMode = .panorama
    @State private var manualAzimuthOffset: Double = 0.0 // Calibrage manuel par glissement horizontal
    @State private var manualPitchOffset: Double = 0.0   // Calibrage vertical

    // Champ de vision (FOV) dynamique selon le mode
    private var fovHorizontal: Double {
        displayMode == .panorama ? 75.0 : 64.0
    }

    private var fovVertical: Double {
        displayMode == .panorama ? 48.0 : 36.0
    }

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

    private var horizonColor: Color {
        qiblaManager.isNightVisionMode ? Color(red: 0.7, green: 0.2, blue: 0.2) : Color.green.opacity(0.85)
    }

    private var ridgeColor: Color {
        qiblaManager.isNightVisionMode ? Color.red.opacity(0.9) : Color.orange.opacity(0.9)
    }

    // Cap boussole de visée : magnétomètre matériel étalonné de l'iPhone
    private var baseCompassYaw: Double {
        qiblaManager.heading
    }

    var body: some View {
        ZStack {
            // 1. Arrière-plan (Caméra RA ou Ciel Vectoriel PeakFinder)
            if displayMode == .cameraAR {
                ARCameraView()
                    .ignoresSafeArea()

                if qiblaManager.isNightVisionMode {
                    Color.red.opacity(0.28)
                        .blendMode(.multiply)
                        .ignoresSafeArea()
                }
            } else {
                // Fond Panorama PeakFinder (Dégradé Ciel Crépusculaire / Nuit)
                LinearGradient(
                    colors: qiblaManager.isNightVisionMode ? [
                        Color(red: 0.12, green: 0.02, blue: 0.02),
                        Color(red: 0.25, green: 0.04, blue: 0.04),
                        Color(red: 0.05, green: 0.0, blue: 0.0)
                    ] : [
                        Color(red: 0.02, green: 0.05, blue: 0.14),
                        Color(red: 0.07, green: 0.14, blue: 0.30),
                        Color(red: 0.18, green: 0.28, blue: 0.44),
                        Color(red: 0.05, green: 0.10, blue: 0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }

            // 2. Calque Graphique Principal (Canvas de Rendu Panoramique Multi-strates 3D)
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let effectiveYaw = (baseCompassYaw + manualAzimuthOffset).truncatingRemainder(dividingBy: 360.0)
                let pitchDamping: Double = displayMode == .panorama ? 0.45 : 1.0
                let effectivePitch = (motionManager.pitchDegrees * pitchDamping) + manualPitchOffset

                ZStack {
                    Canvas { context, size in
                        // A. Échelle d'Élévation Graticule (-10°, 0°, +10°, +20°, +30°)
                        let elevationSteps = [-10.0, 0.0, 10.0, 20.0, 30.0, 45.0]
                        for alt in elevationSteps {
                            let y = projectY(altitude: alt, pitch: effectivePitch, screenHeight: size.height)
                            if y >= -20 && y <= size.height + 20 {
                                var gridLine = Path()
                                gridLine.move(to: CGPoint(x: 0, y: y))
                                gridLine.addLine(to: CGPoint(x: size.width, y: y))

                                if alt == 0.0 {
                                    // Horizon de Référence 0°
                                    context.stroke(
                                        gridLine,
                                        with: .color(horizonColor),
                                        style: StrokeStyle(lineWidth: 1.5, dash: [8, 4])
                                    )
                                } else {
                                    // Lignes d'altitude secondaires
                                    context.stroke(
                                        gridLine,
                                        with: .color(Color.white.opacity(0.12)),
                                        style: StrokeStyle(lineWidth: 1.0, dash: [4, 8])
                                    )
                                }
                            }
                        }

                        // B. Relief 3D Multi-Strates Panoramique (Technique PeakFinder)
                        if qiblaManager.showTerrainSkyline {
                            drawPeakFinderLayeredTerrain(
                                context: &context,
                                size: size,
                                yaw: effectiveYaw,
                                pitch: effectivePitch
                            )
                        }

                        // C. Arc Céleste de la Trajectoire Lunaire
                        let trajectory = qiblaManager.liveMoonPosition.trajectory
                        if trajectory.count > 1 {
                            var arcPath = Path()
                            var arcStarted = false

                            for pt in trajectory {
                                let x = projectX(azimuth: pt.azimuthDegrees, yaw: effectiveYaw, screenWidth: size.width)
                                let y = projectY(altitude: pt.altitudeDegrees, pitch: effectivePitch, screenHeight: size.height)

                                if !arcStarted {
                                    arcPath.move(to: CGPoint(x: x, y: y))
                                    arcStarted = true
                                } else {
                                    arcPath.addLine(to: CGPoint(x: x, y: y))
                                }
                            }

                            context.stroke(
                                arcPath,
                                with: .color(primaryColor.opacity(0.75)),
                                style: StrokeStyle(lineWidth: 2.2, dash: [5, 4])
                            )
                        }

                        // D. Disque Solaire
                        let sunAz = qiblaManager.liveMoonPosition.sunAzimuthDegrees
                        let sunAlt = qiblaManager.liveMoonPosition.sunAltitudeDegrees
                        let sunX = projectX(azimuth: sunAz, yaw: effectiveYaw, screenWidth: size.width)
                        let sunY = projectY(altitude: sunAlt, pitch: effectivePitch, screenHeight: size.height)

                        if isPointInScreen(x: sunX, y: sunY, width: size.width, height: size.height) {
                            let sunRect = CGRect(x: sunX - 18, y: sunY - 18, width: 36, height: 36)
                            context.fill(Path(ellipseIn: sunRect), with: .color(accentSunColor.opacity(0.3)))
                            context.stroke(Path(ellipseIn: sunRect), with: .color(accentSunColor), lineWidth: 2)
                        }

                        // E. Disque Lunaire & Réticule Jumelles
                        let moonAz = qiblaManager.liveMoonPosition.azimuthDegrees
                        let moonAlt = qiblaManager.liveMoonPosition.altitudeDegrees
                        let moonX = projectX(azimuth: moonAz, yaw: effectiveYaw, screenWidth: size.width)
                        let moonY = projectY(altitude: moonAlt, pitch: effectivePitch, screenHeight: size.height)

                        if isPointInScreen(x: moonX, y: moonY, width: size.width, height: size.height) {
                            let moonHalo = CGRect(x: moonX - 22, y: moonY - 22, width: 44, height: 44)
                            context.fill(Path(ellipseIn: moonHalo), with: .color(primaryColor.opacity(0.25)))
                            context.stroke(Path(ellipseIn: moonHalo), with: .color(primaryColor), lineWidth: 2)

                            // Réticule Optique FOV 7° (Simulation Jumelles 7x50)
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

                                var crossPath = Path()
                                crossPath.move(to: CGPoint(x: moonX - 14, y: moonY))
                                crossPath.addLine(to: CGPoint(x: moonX + 14, y: moonY))
                                crossPath.move(to: CGPoint(x: moonX, y: moonY - 14))
                                crossPath.addLine(to: CGPoint(x: moonX, y: moonY + 14))
                                context.stroke(crossPath, with: .color(primaryColor.opacity(0.85)), lineWidth: 1.0)
                            }
                        }
                    }

                    // 3. Éléments SwiftUI interactifs : Étiquettes de Sommets & Objets Célestes
                    renderPeakLabels(width: width, height: height, yaw: effectiveYaw, pitch: effectivePitch)
                    renderCelestialLabels(width: width, height: height, yaw: effectiveYaw, pitch: effectivePitch)
                }
                .contentShape(Rectangle())
                // Geste de glissement pour naviguer et calibrer
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let deltaAz = Double(-value.translation.width / width) * fovHorizontal * 0.35
                            let deltaAlt = Double(value.translation.height / height) * fovVertical * 0.35
                            manualAzimuthOffset = (manualAzimuthOffset + deltaAz).truncatingRemainder(dividingBy: 360.0)
                            manualPitchOffset = max(-30.0, min(30.0, manualPitchOffset + deltaAlt))
                        }
                )
            }

            // 4. Ruban de Boussole Supérieur (Style PeakFinder Ribbon)
            VStack {
                renderCompassRibbon()
                    .padding(.top, 4)

                // Barre de commandes supérieure
                renderTopControlBar()
                    .padding(.horizontal)
                    .padding(.top, 4)

                Spacer()

                // 5. Bandeau inférieur d'information et guidage
                renderBottomHUD()
            }
        }
        .onAppear {
            qiblaManager.setLandscapeOrientation(true)
            motionManager.startTracking()
            qiblaManager.refreshSkylineIfNeeded()
        }
        .onDisappear {
            qiblaManager.setLandscapeOrientation(false)
            motionManager.stopTracking()
        }
    }

    // MARK: - Tracé Multi-Strates Panoramique Vectoriel (PeakFinder Depth Layers)
    private func drawPeakFinderLayeredTerrain(
        context: inout GraphicsContext,
        size: CGSize,
        yaw: Double,
        pitch: Double
    ) {
        let live = qiblaManager.liveMoonPosition

        if displayMode == .panorama {
            // Plan 3 : Crêtes lointaines (16 - 30 km) - Teinte atmosphérique éthérée
            let bgPoints = !live.backgroundSkyline.isEmpty ? live.backgroundSkyline : generateFallbackLayer(amplitude: 1.8, freq1: 2.0, freq2: 5.0, phase: 0.4)
            let bgDense = interpolateSkyline(bgPoints)
            drawSingleLayer(
                context: &context,
                points: bgDense,
                size: size,
                yaw: yaw,
                pitch: pitch,
                strokeColor: qiblaManager.isNightVisionMode ? Color.red.opacity(0.4) : Color(red: 0.45, green: 0.55, blue: 0.75).opacity(0.6),
                fillColor: qiblaManager.isNightVisionMode ? Color(red: 0.20, green: 0.04, blue: 0.04).opacity(0.4) : Color(red: 0.12, green: 0.18, blue: 0.30).opacity(0.35),
                lineWidth: 1.2
            )

            // Plan 2 : Massif intermédiaire (7 km) - Teinte crépusculaire
            let midPoints = !live.midgroundSkyline.isEmpty ? live.midgroundSkyline : generateFallbackLayer(amplitude: 1.2, freq1: 3.5, freq2: 7.0, phase: 1.8)
            let midDense = interpolateSkyline(midPoints)
            drawSingleLayer(
                context: &context,
                points: midDense,
                size: size,
                yaw: yaw,
                pitch: pitch,
                strokeColor: qiblaManager.isNightVisionMode ? Color.red.opacity(0.65) : Color(red: 0.60, green: 0.70, blue: 0.85).opacity(0.8),
                fillColor: qiblaManager.isNightVisionMode ? Color(red: 0.15, green: 0.03, blue: 0.03).opacity(0.55) : Color(red: 0.08, green: 0.13, blue: 0.24).opacity(0.50),
                lineWidth: 1.8
            )

            // Plan 1 : Avant-plan (2.5 km) - Relief découpé sombre avec ligne de crête lumineuse
            let fgPoints = !live.foregroundSkyline.isEmpty ? live.foregroundSkyline : generateFallbackLayer(amplitude: 0.8, freq1: 4.0, freq2: 9.0, phase: 3.2)
            let fgDense = interpolateSkyline(fgPoints)
            drawSingleLayer(
                context: &context,
                points: fgDense,
                size: size,
                yaw: yaw,
                pitch: pitch,
                strokeColor: ridgeColor,
                fillColor: qiblaManager.isNightVisionMode ? Color(red: 0.10, green: 0.02, blue: 0.02).opacity(0.85) : Color(red: 0.04, green: 0.07, blue: 0.14).opacity(0.80),
                lineWidth: 2.6
            )
        } else {
            // Mode Caméra RA : Ligne de crête globale nette d'obstruction
            let rawSkyline = !live.skyline.isEmpty ? live.skyline : generateFallbackLayer(amplitude: 1.4, freq1: 3.0, freq2: 6.0, phase: 1.0)
            let denseSkyline = interpolateSkyline(rawSkyline)
            drawSingleLayer(
                context: &context,
                points: denseSkyline,
                size: size,
                yaw: yaw,
                pitch: pitch,
                strokeColor: ridgeColor,
                fillColor: ridgeColor.opacity(0.18),
                lineWidth: 2.2
            )
        }
    }

    // Dessine une strate de montagne continue avec lissage par courbes quadratiques
    private func drawSingleLayer(
        context: inout GraphicsContext,
        points: [(az: Double, alt: Double)],
        size: CGSize,
        yaw: Double,
        pitch: Double,
        strokeColor: Color,
        fillColor: Color,
        lineWidth: CGFloat
    ) {
        var visiblePoints: [(x: CGFloat, y: CGFloat)] = []
        for pt in points {
            let x = projectX(azimuth: pt.az, yaw: yaw, screenWidth: size.width)
            let y = projectY(altitude: pt.alt, pitch: pitch, screenHeight: size.height)
            if x >= -350 && x <= size.width + 350 {
                visiblePoints.append((x, y))
            }
        }

        visiblePoints.sort { $0.x < $1.x }
        guard visiblePoints.count >= 2 else { return }

        var ridgePath = Path()
        ridgePath.move(to: CGPoint(x: visiblePoints[0].x, y: visiblePoints[0].y))

        for i in 1..<visiblePoints.count {
            let prev = visiblePoints[i - 1]
            let curr = visiblePoints[i]
            let midX = (prev.x + curr.x) / 2.0
            let midY = (prev.y + curr.y) / 2.0
            ridgePath.addQuadCurve(
                to: CGPoint(x: curr.x, y: curr.y),
                control: CGPoint(x: midX, y: midY)
            )
        }

        // 1. Remplissage vers le bas
        if let first = visiblePoints.first, let last = visiblePoints.last {
            var fillPath = ridgePath
            fillPath.addLine(to: CGPoint(x: max(last.x, size.width + 200), y: size.height + 150))
            fillPath.addLine(to: CGPoint(x: min(first.x, -200), y: size.height + 150))
            fillPath.closeSubpath()
            context.fill(fillPath, with: .color(fillColor))
        }

        // 2. Ligne de crête
        context.stroke(ridgePath, with: .color(strokeColor), lineWidth: lineWidth)
    }

    // Interpolation Catmull-Rom haute résolution pour subdiviser les 48 points en 180 points lisses
    private func interpolateSkyline(_ points: [SkylinePoint]) -> [(az: Double, alt: Double)] {
        guard points.count >= 4 else {
            return points.map { ($0.azimuthDegrees, $0.elevationAngleDegrees) }
        }

        var densePoints: [(az: Double, alt: Double)] = []
        let count = points.count
        for i in 0..<count {
            let p0 = points[(i - 1 + count) % count]
            let p1 = points[i]
            let p2 = points[(i + 1) % count]
            let p3 = points[(i + 2) % count]

            densePoints.append((p1.azimuthDegrees, p1.elevationAngleDegrees))

            // Point intermédiaire interpolé (Catmull-Rom spline)
            let midAlt = 0.5 * (2.0 * p1.elevationAngleDegrees +
                               (-p0.elevationAngleDegrees + p2.elevationAngleDegrees) * 0.5 +
                               (2.0 * p0.elevationAngleDegrees - 5.0 * p1.elevationAngleDegrees + 4.0 * p2.elevationAngleDegrees - p3.elevationAngleDegrees) * 0.25 +
                               (-p0.elevationAngleDegrees + 3.0 * p1.elevationAngleDegrees - 3.0 * p2.elevationAngleDegrees + p3.elevationAngleDegrees) * 0.125)

            var midAz = (p1.azimuthDegrees + p2.azimuthDegrees) / 2.0
            if abs(p2.azimuthDegrees - p1.azimuthDegrees) > 180.0 {
                midAz = (p1.azimuthDegrees + p2.azimuthDegrees + 360.0) / 2.0
                if midAz >= 360.0 { midAz -= 360.0 }
            }
            densePoints.append((midAz, max(0.0, midAlt)))
        }

        return densePoints.sorted { $0.az < $1.az }
    }

    // Générateur de strates de secours
    private func generateFallbackLayer(amplitude: Double, freq1: Double, freq2: Double, phase: Double) -> [SkylinePoint] {
        var points: [SkylinePoint] = []
        for az in stride(from: 0.0, to: 360.0, by: 7.5) {
            let rad = az * .pi / 180.0
            let alt = amplitude + (amplitude * 0.6) * sin(rad * freq1 + phase) + (amplitude * 0.3) * cos(rad * freq2)
            points.append(SkylinePoint(
                azimuthDegrees: az,
                elevationAngleDegrees: max(0.2, alt),
                distanceKm: 10.0,
                altitudeMeters: 500.0
            ))
        }
        return points
    }

    // MARK: - Rendu des Étiquettes de Sommets
    @ViewBuilder
    private func renderPeakLabels(width: CGFloat, height: CGFloat, yaw: Double, pitch: Double) -> some View {
        ForEach(qiblaManager.liveMoonPosition.peaks) { peak in
            let x = projectX(azimuth: peak.azimuthDegrees, yaw: yaw, screenWidth: width)
            let y = projectY(altitude: peak.elevationAngleDegrees, pitch: pitch, screenHeight: height)

            if isPointInScreen(x: x, y: y, width: width, height: height) {
                VStack(spacing: 2) {
                    // Hampe verticale de pointage vers la crête
                    Rectangle()
                        .fill(ridgeColor.opacity(0.8))
                        .frame(width: 1, height: 16)

                    HStack(spacing: 3) {
                        Image(systemName: "triangle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(.orange)
                        Text(peak.name)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.black.opacity(0.75))
                    .clipShape(.rect(cornerRadius: 3))
                }
                .position(x: x, y: y - 22)
            }
        }
    }

    // MARK: - Rendu des Étiquettes Célestes (Lune, Soleil & Qibla)
    @ViewBuilder
    private func renderCelestialLabels(width: CGFloat, height: CGFloat, yaw: Double, pitch: Double) -> some View {
        let moonX = projectX(azimuth: qiblaManager.liveMoonPosition.azimuthDegrees, yaw: yaw, screenWidth: width)
        let moonY = projectY(altitude: qiblaManager.liveMoonPosition.altitudeDegrees, pitch: pitch, screenHeight: height)

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
                    .background(.black.opacity(0.7))
                    .clipShape(.capsule)

                if qiblaManager.showOpticalReticle {
                    Text("FOV Jumelles 7x50 (7°)")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(primaryColor)
                }
            }
            .position(x: moonX, y: moonY - 34)
        }

        let sunX = projectX(azimuth: qiblaManager.liveMoonPosition.sunAzimuthDegrees, yaw: yaw, screenWidth: width)
        let sunY = projectY(altitude: qiblaManager.liveMoonPosition.sunAltitudeDegrees, pitch: pitch, screenHeight: height)

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

        // Indicateur flottant Qibla (Direction La Mecque)
        if qiblaManager.qiblaAngle > 0 {
            let qiblaX = projectX(azimuth: qiblaManager.qiblaAngle, yaw: yaw, screenWidth: width)
            let qiblaY = projectY(altitude: 0.0, pitch: pitch, screenHeight: height)

            if qiblaX >= -30 && qiblaX <= width + 30 {
                VStack(spacing: 3) {
                    Image(systemName: "location.north.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                        .shadow(color: .green, radius: 8)

                    Text("QIBLA (\(Int(qiblaManager.qiblaAngle.rounded()))°)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.black.opacity(0.75))
                        .clipShape(.capsule)
                }
                .position(x: qiblaX, y: max(50, min(height - 50, qiblaY - 25)))
            }
        }
    }

    // MARK: - Ruban de Cap Boussole (Compass Tape)
    private func renderCompassRibbon() -> some View {
        GeometryReader { ribbonGeo in
            let ribbonWidth = ribbonGeo.size.width
            let effectiveYaw = (baseCompassYaw + manualAzimuthOffset).truncatingRemainder(dividingBy: 360.0)

            ZStack {
                // Ticks gradués tous les 5°
                ForEach(0..<72, id: \.self) { index in
                    let angle = Double(index * 5)
                    let x = projectX(azimuth: angle, yaw: effectiveYaw, screenWidth: ribbonWidth)

                    if x >= 0 && x <= ribbonWidth {
                        let isCardinal = (index % 18 == 0) // N, E, S, W
                        let isIntercardinal = (index % 9 == 0 && !isCardinal) // NE, SE, SW, NW
                        let isMajor = (index % 2 == 0)

                        VStack(spacing: 1) {
                            Rectangle()
                                .fill(isCardinal ? Color.white : (isMajor ? Color.white.opacity(0.6) : Color.white.opacity(0.3)))
                                .frame(width: isCardinal ? 2 : 1, height: isCardinal ? 12 : (isMajor ? 8 : 5))

                            if isCardinal {
                                Text(cardinalLabel(for: angle))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            } else if isIntercardinal {
                                Text(cardinalLabel(for: angle))
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            } else if isMajor && (index % 6 == 0) {
                                Text("\(Int(angle))°")
                                    .font(.system(size: 7))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .position(x: x, y: 14)
                    }
                }

                // Curseur de visée central
                Rectangle()
                    .fill(primaryColor)
                    .frame(width: 2, height: 24)
                    .position(x: ribbonWidth / 2.0, y: 12)

                // Repère Qibla sur le ruban
                if qiblaManager.qiblaAngle > 0 {
                    let qiblaRibbonX = projectX(azimuth: qiblaManager.qiblaAngle, yaw: effectiveYaw, screenWidth: ribbonWidth)
                    if qiblaRibbonX >= 0 && qiblaRibbonX <= ribbonWidth {
                        VStack(spacing: 1) {
                            Image(systemName: "location.north.circle.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.green)
                            Text("Q")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(.green)
                        }
                        .position(x: qiblaRibbonX, y: 12)
                    }
                }
            }
        }
        .frame(height: 28)
        .background(.black.opacity(0.45))
        .clipShape(.rect(cornerRadius: 6))
        .padding(.horizontal, 40)
    }

    // MARK: - Barre de Commandes Supérieure
    private func renderTopControlBar() -> some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            // Sélecteur de Mode (Panorama 3D / Caméra RA)
            Picker("Mode", selection: $displayMode) {
                ForEach(PeakFinderDisplayMode.allCases) { mode in
                    Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 220)

            // Bouton Bascule Vision Nocturne
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    qiblaManager.isNightVisionMode.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: qiblaManager.isNightVisionMode ? "moon.stars.fill" : "moon.fill")
                        .foregroundStyle(qiblaManager.isNightVisionMode ? .red : .secondary)
                    Text(qiblaManager.isNightVisionMode ? "Filtre Rouge" : "Vision Nuit")
                        .font(.caption2)
                        .bold()
                        .foregroundStyle(qiblaManager.isNightVisionMode ? .red : .secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.black.opacity(0.65))
                .clipShape(.capsule)
            }
            .buttonStyle(.plain)

            // Bouton Réticule Jumelles FOV 7°
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    qiblaManager.showOpticalReticle.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "circle.circle")
                        .foregroundStyle(qiblaManager.showOpticalReticle ? primaryColor : .secondary)
                    Text("Jumelles 7°")
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

            // Réinitialisation du calibrage si modifié
            if abs(manualAzimuthOffset) > 0.5 || abs(manualPitchOffset) > 0.5 {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        manualAzimuthOffset = 0.0
                        manualPitchOffset = 0.0
                    }
                }) {
                    Text("Recalibrer (0°)")
                        .font(.caption2)
                        .bold()
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(.black.opacity(0.65))
                        .clipShape(.capsule)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Indicateur de Cap & Altitude
            HStack(spacing: DesignSystem.Spacing.small) {
                Label(
                    "Cap: \(((baseCompassYaw + manualAzimuthOffset + 360).truncatingRemainder(dividingBy: 360)).formatted(.number.precision(.fractionLength(0))))°",
                    systemImage: "safari.fill"
                )
                .font(.caption)
                .bold()
                .foregroundStyle(secondaryColor)

                Label(
                    "Inclinaison: \((motionManager.pitchDegrees + manualPitchOffset).formatted(.number.precision(.fractionLength(0))))°",
                    systemImage: "gyroscope"
                )
                .font(.caption)
                .bold()
                .foregroundStyle(secondaryColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.black.opacity(0.65))
            .clipShape(.capsule)
        }
    }

    // MARK: - Bandeau Inférieur HUD
    private func renderBottomHUD() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Lune : \(qiblaManager.liveMoonPosition.formattedAzimuth) • Élévation \(qiblaManager.liveMoonPosition.formattedAltitude)")
                    .font(.caption)
                    .bold()
                    .foregroundStyle(primaryColor)

                if let weather = qiblaManager.hilalObservation.weatherConditions {
                    Text("Clarté ciel : \(weather.seeingScore)% (\(weather.seeingDescription)) • Nuages \(weather.cloudCoverTotalPercent)%")
                        .font(.caption2)
                        .foregroundStyle(secondaryColor.opacity(0.85))
                } else {
                    Text(qiblaManager.liveMoonPosition.relativeSunPositionText)
                        .font(.caption2)
                        .foregroundStyle(secondaryColor.opacity(0.8))
                }
            }

            Spacer()

            Text("Faites glisser l'écran pour affiner l'alignement sur les crêtes")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, DesignSystem.Spacing.normal)
        .padding(.vertical, DesignSystem.Spacing.small)
        .background(.thinMaterial)
        .clipShape(.rect(cornerRadius: DesignSystem.Layout.cornerRadius))
        .padding(.horizontal)
        .padding(.bottom, 10)
    }

    // MARK: - Projection Perspective Optique Réelle (Pinhole Lens Model)
    private func projectX(azimuth: Double, yaw: Double, screenWidth: CGFloat) -> CGFloat {
        var diff = azimuth - yaw
        while diff > 180.0 { diff -= 360.0 }
        while diff < -180.0 { diff += 360.0 }
        guard abs(diff) < 85.0 else { return diff > 0 ? screenWidth + 500 : -500 }

        let diffRad = diff * .pi / 180.0
        let halfFovRad = (fovHorizontal / 2.0) * .pi / 180.0
        let normalized = tan(diffRad) / tan(halfFovRad)
        return (screenWidth / 2.0) + CGFloat(normalized) * (screenWidth / 2.0)
    }

    private func projectY(altitude: Double, pitch: Double, screenHeight: CGFloat) -> CGFloat {
        let diff = altitude - pitch
        guard abs(diff) < 85.0 else { return diff > 0 ? -500 : screenHeight + 500 }

        let diffRad = diff * .pi / 180.0
        let halfFovRad = (fovVertical / 2.0) * .pi / 180.0
        let normalized = tan(diffRad) / tan(halfFovRad)
        return (screenHeight / 2.0) - CGFloat(normalized) * (screenHeight / 2.0)
    }

    private func isPointInScreen(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> Bool {
        x >= -40 && x <= width + 40 && y >= -40 && y <= height + 40
    }

    private func cardinalLabel(for angle: Double) -> String {
        let normalized = (angle.truncatingRemainder(dividingBy: 360.0) + 360.0).truncatingRemainder(dividingBy: 360.0)
        switch Int(normalized.rounded()) {
        case 0, 360: return "N"
        case 45: return "NE"
        case 90: return "E"
        case 135: return "SE"
        case 180: return "S"
        case 225: return "SO"
        case 270: return "O"
        case 315: return "NO"
        default: return ""
        }
    }
}

//
//  CompassWidget.swift
//  COLDFRAME
//

import SwiftUI

struct CompassWidget: View {
    var qiblaManager: QiblaManager
    
    private var safeHeading: Double {
        qiblaManager.heading.isFinite ? qiblaManager.heading : 0
    }
    
    private var safeQiblaAngle: Double {
        qiblaManager.qiblaAngle.isFinite ? qiblaManager.qiblaAngle : 0
    }
    
    private var cardinalDirection: String {
        let normalized = (safeHeading.truncatingRemainder(dividingBy: 360.0) + 360.0).truncatingRemainder(dividingBy: 360.0)
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSO", "SO", "OSO", "O", "ONO", "NO", "NNO"]
        let index = Int((normalized + 11.25) / 22.5) % 16
        return directions[index]
    }
    
    var body: some View {
        ZStack {
            // Halo de validation arrière-plan lors de l'alignement
            Circle()
                .fill(qiblaManager.isAligned ? Color.green.opacity(0.2) : Color.clear)
                .frame(width: DesignSystem.Layout.dialSize + 24, height: DesignSystem.Layout.dialSize + 24)
                .blur(radius: 20)
                .animation(.easeInOut(duration: 0.5), value: qiblaManager.isAligned)
            
            // 1. Cadran et pointeurs astronomiques (Tourne en temps réel avec le capteur)
            ZStack {
                CompassDial()
                
                // Pointeur Lune
                if qiblaManager.liveMoonPosition.azimuthDegrees > 0 {
                    MoonPointer(
                        azimuth: qiblaManager.liveMoonPosition.azimuthDegrees,
                        altitude: qiblaManager.liveMoonPosition.altitudeDegrees,
                        isAboveHorizon: qiblaManager.liveMoonPosition.isAboveHorizon
                    )
                }
                
                // Pointeur Qibla (Direction La Mecque)
                if qiblaManager.qiblaAngle > 0 {
                    QiblaPointer(isAligned: qiblaManager.isAligned)
                        .rotationEffect(.degrees(safeQiblaAngle))
                }
            }
            .frame(width: DesignSystem.Layout.dialSize, height: DesignSystem.Layout.dialSize)
            .rotationEffect(.degrees(-safeHeading))
            
            // 2. Affichage Central Épuré & Lisible
            VStack(spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(safeHeading, format: .number.precision(.fractionLength(0)))
                        .font(.system(size: 42, weight: .light))
                        .fontDesign(.rounded)
                    Text("°")
                        .font(.system(size: 28, weight: .light))
                    Text(cardinalDirection)
                        .font(.system(size: 22, weight: .semibold))
                        .fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.white)

                // Bascule Vrai Nord / Nord Magnétique
                Button {
                    qiblaManager.toggleNorthReference()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: qiblaManager.isTrueNorth ? "location.fill" : "safari.fill")
                            .font(.system(size: 8))
                        Text(qiblaManager.isTrueNorth ? "VRAI NORD" : "MAGNÉTIQUE")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.12))
                    .foregroundStyle(qiblaManager.isTrueNorth ? Color.green : Color.orange)
                    .clipShape(.capsule)
                }
                .buttonStyle(.plain)

                if qiblaManager.isAligned {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 9))
                        Text("ALIGNÉ AVEC LA MECQUE")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.3))
                    .foregroundStyle(.green)
                    .clipShape(.capsule)
                } else if qiblaManager.qiblaAngle > 0 {
                    Text("🕋 Qibla: \(Int(qiblaManager.qiblaAngle.rounded()))°")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .zIndex(2)

            // 3. Repère fixe supérieur (Lubber Line à 12h)
            Image(systemName: "triangle.fill")
                .font(.system(size: 10))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(180))
                .offset(y: -(DesignSystem.Layout.dialSize / 2 + 5))
                .zIndex(2)
        }
        .frame(height: DesignSystem.Layout.widgetHeight)
    }
}

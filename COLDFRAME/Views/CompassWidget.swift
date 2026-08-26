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
            // Halo de validation arrière-plan
            Circle()
                .fill(qiblaManager.isAligned ? .green.opacity(0.15) : .clear)
                .frame(width: DesignSystem.Layout.dialSize + 20, height: DesignSystem.Layout.dialSize + 20)
                .blur(radius: 20)
                .animation(.easeInOut(duration: 0.6), value: qiblaManager.isAligned)
            
            // Repère fixe du Nord au centre en haut
            Image(systemName: "triangle.fill")
                .font(.system(size: 12))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(180))
                .offset(y: -(DesignSystem.Layout.dialSize / 2 + 5))
                .zIndex(2)
            
            // Réticule central (Crosshair fixe)
            ZStack {
                Rectangle()
                    .fill(.white.opacity(0.4))
                    .frame(width: 1, height: 40)
                Rectangle()
                    .fill(.white.opacity(0.4))
                    .frame(width: 40, height: 1)
            }
            .zIndex(2)
            
            // Affichage numérique central style Apple Boussole avec bascule Vrai Nord / Magnétique
            VStack(spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(safeHeading, format: .number.precision(.fractionLength(0)))
                        .font(.system(size: 38, weight: .light))
                        .fontDesign(.rounded)
                    Text("°")
                        .font(.system(size: 28, weight: .light))
                    Text(cardinalDirection)
                        .font(.system(size: 22, weight: .medium))
                        .fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.white)

                Button {
                    qiblaManager.toggleNorthReference()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: qiblaManager.isTrueNorth ? "location.fill" : "safari.fill")
                            .font(.system(size: 8))
                        Text(qiblaManager.isTrueNorth ? "VRAI NORD" : "MAGNÉTIQUE")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.12))
                    .foregroundStyle(qiblaManager.isTrueNorth ? .green : .orange)
                    .clipShape(.capsule)
                }
                .buttonStyle(.plain)
            }
            .offset(y: -48)
            .zIndex(2)
            
            // Cadran et indicateurs Qibla et Lune qui tournent
            ZStack {
                CompassDial()
                
                if qiblaManager.liveMoonPosition.azimuthDegrees > 0 {
                    MoonPointer(
                        azimuth: qiblaManager.liveMoonPosition.azimuthDegrees,
                        altitude: qiblaManager.liveMoonPosition.altitudeDegrees,
                        isAboveHorizon: qiblaManager.liveMoonPosition.isAboveHorizon
                    )
                }
                
                QiblaPointer(isAligned: qiblaManager.isAligned)
                    .rotationEffect(.degrees(safeQiblaAngle))
            }
            .frame(width: DesignSystem.Layout.dialSize, height: DesignSystem.Layout.dialSize)
            .rotationEffect(.degrees(-safeHeading))
        }
        .frame(height: DesignSystem.Layout.widgetHeight)
        .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.6), value: safeHeading)
    }
}

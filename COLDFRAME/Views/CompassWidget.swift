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
            
            // Degré actuel au centre
            Text("\(safeHeading.formatted(.number.precision(.fractionLength(0))))°")
                .font(.system(size: 40, weight: .light))
                .fontDesign(.rounded)
                .foregroundStyle(.white)
                .offset(y: -55)
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

//
//  MoonPointer.swift
//  COLDFRAME
//

import SwiftUI

struct MoonPointer: View {
    let azimuth: Double
    let altitude: Double
    let isAboveHorizon: Bool

    var body: some View {
        ZStack {
            // Ligne pointillée fine vers la direction de la Lune
            Rectangle()
                .fill(isAboveHorizon ? Color.cyan.opacity(0.8) : Color.cyan.opacity(0.3))
                .frame(width: 1.5, height: 125)
                .offset(y: -62.5)

            // Badge lune avec altitude
            VStack(spacing: 1) {
                Image(systemName: isAboveHorizon ? "moonphase.waxing.crescent" : "moon.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(isAboveHorizon ? .cyan : .gray)
                    .shadow(color: isAboveHorizon ? .cyan.opacity(0.8) : .clear, radius: 4)

                Text(altitude.formatted(.number.precision(.fractionLength(0))) + "°")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(isAboveHorizon ? .cyan : .gray)
            }
            .offset(y: -142)

            // Petit point sur le bord
            Circle()
                .fill(isAboveHorizon ? Color.cyan : Color.gray.opacity(0.5))
                .frame(width: 5, height: 5)
                .offset(y: -125)
        }
        .rotationEffect(.degrees(azimuth))
    }
}

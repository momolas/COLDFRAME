//
//  CompassDial.swift
//  COLDFRAME
//

import SwiftUI

struct CompassDial: View {
    var body: some View {
        ZStack {
            // Graduations (180 traits, 1 tous les 2 degrés)
            ForEach(0..<180) { i in
                let degree = i * 2
                let isMajor = degree % 30 == 0
                let isTen = degree % 10 == 0 && !isMajor
                
                Rectangle()
                    .fill(isMajor ? .white : (isTen ? .white.opacity(0.8) : .white.opacity(0.4)))
                    .frame(width: isMajor ? 2.5 : 1.5, height: isMajor ? 14 : (isTen ? 10 : 6))
                    .offset(y: -140)
                    .rotationEffect(.degrees(Double(degree)))
            }
            
            // Labels (N, E, S, O et degrés intermédiaires)
            ForEach(0..<12) { i in
                let degree = i * 30
                if degree == 0 {
                    Text("N")
                        .font(.system(size: 26).bold())
                        .foregroundStyle(.white)
                        .offset(y: -105)
                        .rotationEffect(.degrees(Double(degree)))
                    
                    // Triangle rouge sous le N pour marquer le Nord
                    Image(systemName: "triangle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                        .offset(y: -125)
                        .rotationEffect(.degrees(Double(degree)))
                } else if degree == 90 {
                    Text("E")
                        .font(.system(size: 24).bold())
                        .foregroundStyle(.white)
                        .offset(y: -105)
                        .rotationEffect(.degrees(Double(degree)))
                } else if degree == 180 {
                    Text("S")
                        .font(.system(size: 24).bold())
                        .foregroundStyle(.white)
                        .offset(y: -105)
                        .rotationEffect(.degrees(Double(degree)))
                } else if degree == 270 {
                    Text("O")
                        .font(.system(size: 24).bold())
                        .foregroundStyle(.white)
                        .offset(y: -105)
                        .rotationEffect(.degrees(Double(degree)))
                } else {
                    Text(degree, format: .number.precision(.fractionLength(0)))
                        .font(.system(size: 16).bold())
                        .foregroundStyle(.white)
                        .offset(y: -105)
                        .rotationEffect(.degrees(Double(degree)))
                }
            }
        }
        .frame(width: DesignSystem.Layout.dialSize, height: DesignSystem.Layout.dialSize)
        .drawingGroup()
    }
}

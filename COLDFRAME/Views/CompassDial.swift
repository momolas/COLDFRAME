//
//  CompassDial.swift
//  COLDFRAME
//

import SwiftUI

struct CompassDial: View {
    var body: some View {
        ZStack {
            // Graduations (Ticks) via Canvas pour la performance
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = size.width / 2
                
                for i in 0..<180 {
                    let degree = Double(i * 2)
                    let isMajor = i * 2 % 30 == 0
                    let isTen = i * 2 % 10 == 0 && !isMajor
                    
                    let tickHeight: CGFloat = isMajor ? 14 : (isTen ? 10 : 6)
                    let tickWidth: CGFloat = isMajor ? 2.5 : 1.5
                    let opacity: Double = isMajor ? 1.0 : (isTen ? 0.8 : 0.4)
                    
                    var path = Path()
                    path.addRect(CGRect(x: -tickWidth / 2, y: -radius, width: tickWidth, height: tickHeight))
                    
                    var transform = CGAffineTransform(translationX: center.x, y: center.y)
                    transform = transform.rotated(by: CGFloat(degree * .pi / 180))
                    
                    context.fill(path.applying(transform), with: .color(.white.opacity(opacity)))
                }
            }
            
            // Labels (N, E, S, O et degrés) - On les garde en SwiftUI pour le rendu texte optimal
            ForEach(0..<12) { i in
                let degree = i * 30
                LabelView(degree: degree)
                    .offset(y: -105)
                    .rotationEffect(.degrees(Double(degree)))
            }
        }
        .frame(width: DesignSystem.Layout.dialSize, height: DesignSystem.Layout.dialSize)
    }
}

private struct LabelView: View {
    let degree: Int
    
    var body: some View {
        Group {
            if degree == 0 {
                VStack(spacing: 2) {
                    Text("N")
                        .font(.system(size: 26).bold())
                        .foregroundStyle(.white)
                    
                    Image(systemName: "triangle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                        .offset(y: -5)
                }
            } else if degree == 90 {
                Text("E")
                    .font(.system(size: 24).bold())
                    .foregroundStyle(.white)
            } else if degree == 180 {
                Text("S")
                    .font(.system(size: 24).bold())
                    .foregroundStyle(.white)
            } else if degree == 270 {
                Text("O")
                    .font(.system(size: 24).bold())
                    .foregroundStyle(.white)
            } else {
                Text(degree, format: .number.precision(.fractionLength(0)))
                    .font(.system(size: 16).bold())
                    .foregroundStyle(.white)
            }
        }
    }
}

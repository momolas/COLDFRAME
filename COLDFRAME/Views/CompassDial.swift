//
//  CompassDial.swift
//  COLDFRAME
//

import SwiftUI

struct CompassDial: View {
    private let dialSize = DesignSystem.Layout.dialSize
    private let labelRadius: CGFloat = 105.0 // Rayon pour les lettres et nombres

    var body: some View {
        ZStack {
            // 1. Graduations (Ticks) 360° dessinées précisément dans le Canvas
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let outerRadius = size.width / 2

                for i in 0..<180 {
                    let deg = Double(i * 2)
                    let rad = deg * .pi / 180.0

                    let isMajor = (i * 2 % 30 == 0)
                    let isTen = (i * 2 % 10 == 0 && !isMajor)

                    let tickLength: CGFloat = isMajor ? 14 : (isTen ? 10 : 6)
                    let tickWidth: CGFloat = isMajor ? 2.5 : 1.5
                    let opacity: Double = isMajor ? 1.0 : (isTen ? 0.8 : 0.4)

                    let innerRadius = outerRadius - tickLength

                    let sinAngle = sin(rad)
                    let cosAngle = cos(rad)

                    let startPoint = CGPoint(
                        x: center.x + CGFloat(sinAngle) * innerRadius,
                        y: center.y - CGFloat(cosAngle) * innerRadius
                    )
                    let endPoint = CGPoint(
                        x: center.x + CGFloat(sinAngle) * outerRadius,
                        y: center.y - CGFloat(cosAngle) * outerRadius
                    )

                    var path = Path()
                    path.move(to: startPoint)
                    path.addLine(to: endPoint)

                    context.stroke(
                        path,
                        with: .color(.white.opacity(opacity)),
                        lineWidth: tickWidth
                    )
                }
            }

            // 2. Labels N, E, S, O et degrés intermédiaires (positionnés rigoureusement par coordonnées polaires)
            ForEach(0..<12, id: \.self) { i in
                let degree = i * 30
                let rad = Double(degree) * .pi / 180.0
                let xPos = (dialSize / 2) + CGFloat(sin(rad)) * labelRadius
                let yPos = (dialSize / 2) - CGFloat(cos(rad)) * labelRadius

                LabelView(degree: degree)
                    .position(x: xPos, y: yPos)
            }
        }
        .frame(width: dialSize, height: dialSize)
    }
}

private struct LabelView: View {
    let degree: Int

    var body: some View {
        Group {
            if degree == 0 {
                VStack(spacing: 1) {
                    Text("N")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                    Image(systemName: "triangle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.red)
                }
            } else if degree == 90 {
                Text("E")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            } else if degree == 180 {
                Text("S")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            } else if degree == 270 {
                Text("O")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Text(degree, format: .number.precision(.fractionLength(0)))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }
}

//
//  CompassDial.swift
//  COLDFRAME
//
//  Created by Mo on 17/12/2025.
//


import SwiftUI
import Foundation

struct CompassDial: View {
    var body: some View {
        ZStack {
            // Fond principal - Style Neumorphisme sombre
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.darkBackground.opacity(0.8), .black],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .shadow(color: .white.opacity(0.05), radius: 1, x: -1, y: -1)
                .shadow(color: .black.opacity(0.8), radius: 10, x: 5, y: 5)
            
            // Anneau extérieur avec reflet subtil
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [.gray.opacity(0.1), .white.opacity(0.2), .gray.opacity(0.1), .white.opacity(0.2), .gray.opacity(0.1)],
                        center: .center
                    ),
                    lineWidth: 1.5
                )
            
            // Graduations (72 traits, soit 1 trait tous les 5 degrés)
            ForEach(0..<72) { i in
                let isMajor = i % 18 == 0 // Tous les 90° (N, E, S, O)
                let isMinor = i % 6 == 0  // Tous les 30°
                
                Rectangle()
                    .fill(isMajor ? Color.gold : (isMinor ? Color.white.opacity(0.6) : Color.white.opacity(0.2)))
                    .frame(width: isMajor ? 2.5 : 1, height: isMajor ? 14 : (isMinor ? 8 : 4))
                    .offset(y: -135)
                    .rotationEffect(.degrees(Double(i) * 5))
            }
            
            // Anneau de repère intérieur pointillé
            Circle()
                .stroke(Color.white.opacity(0.05), style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
                .frame(width: 180, height: 180)
            
            // Points cardinaux
            ForEach(["N", "E", "S", "O"], id: \.self) { dir in
                Text(dir)
                    .font(.title2)
                    .bold()
                    .fontDesign(.serif)
                    .foregroundStyle(dir == "N" ? Color.gold : Color.white.opacity(0.8))
                    .shadow(color: dir == "N" ? .gold.opacity(0.4) : .clear, radius: 5)
                    .offset(y: -105)
                    .rotationEffect(.degrees(dir == "N" ? 0 : dir == "E" ? 90 : dir == "S" ? 180 : 270))
            }
        }
    }
}

struct QiblaPointer: View {
    var isAligned: Bool
    
    var body: some View {
        ZStack {
            // Aiguille Principale
            VStack(spacing: 0) {
                Image(systemName: "location.north.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(isAligned ? Color.green : Color.gold)
                    .shadow(color: isAligned ? .green.opacity(0.8) : .gold.opacity(0.6), radius: 8)
                    .symbolEffect(.pulse.byLayer, isActive: isAligned)
                    .offset(y: -2)

                // Traînée / Tige de l'aiguille
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [isAligned ? .green : .gold, .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3, height: 130)
                    .clipShape(.capsule)
            }
            // Décalé de la moitié de sa hauteur pour tourner exactement autour du centre
            .offset(y: -65)
            
            // Point de Pivot Central (axe)
            ZStack {
                Circle()
                    .fill(Color.black)
                    .frame(width: 18, height: 18)
                    .shadow(color: .black.opacity(0.5), radius: 3)
                
                Circle()
                    .stroke(isAligned ? Color.green : Color.gold.opacity(0.8), lineWidth: 2)
                    .frame(width: 18, height: 18)
                
                Circle()
                    .fill(isAligned ? Color.green : Color.gold)
                    .frame(width: 4, height: 4)
            }
        }
    }
}

struct PrayerTimesList: View {
    let prayers: [PrayerTime]
    var nextPrayer: PrayerTime? = nil

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 15) {
                ForEach(prayers.enumerated(), id: \.element.id) { index, prayer in
                    let isNext = prayer.id == nextPrayer?.id

                    VStack(spacing: 8) {
                        Image(systemName: prayer.icon)
                            .font(.title2)
                            .foregroundStyle(isNext ? .white : Color.gold)
                            .symbolEffect(.pulse.byLayer, isActive: true)
                        Text(prayer.name)
                            .font(.caption).bold()
                            .foregroundStyle(isNext ? .white : .primary)
                        Text(prayer.time)
                            .font(.caption2)
                            .foregroundStyle(isNext ? .white.opacity(0.8) : .secondary)
                    }
                    .frame(width: 80, height: 100)
                    .background(isNext ? AnyShapeStyle(Color.gold) : AnyShapeStyle(.regularMaterial))
                    .clipShape(.rect(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(LinearGradient(colors: [isNext ? .white : .gold.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                    )
                    .shadow(color: isNext ? .gold.opacity(0.5) : .black.opacity(0.2), radius: isNext ? 10 : 5, x: 0, y: 5)
                    .scaleEffect(isNext ? 1.05 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isNext)
                }
            }
            .padding(.horizontal)
            .contentMargins(.horizontal, 20, for: .scrollContent)
        }
        .scrollIndicators(.hidden)
    }
}

struct MoonPhaseView: View {
    var moonName: String
    var moonIcon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: moonIcon)
                .font(.system(size: 20))
                .foregroundStyle(Color.gold)
            Text(moonName)
                .font(.footnote)
                .bold()
                //.fontDesign(.serif)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(.capsule)
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
    }
}

struct HilalObservationView: View {
    let visibility: HilalVisibility

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.gold)
                Text("Observation du Hilal ce soir")
                    .font(.subheadline)
                    .bold()
                    //.fontDesign(.serif)
                    .foregroundStyle(Color.gold)
            }

            HStack(spacing: 12) {
                Image(systemName: visibility.icon)
                    .font(.title)
                    .foregroundStyle(visibility.color)

                Text(visibility.rawValue)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.gold.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

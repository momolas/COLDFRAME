//
//  CompassDial.swift
//  COLDFRAME
//
//  Created by Mo on 17/12/2025.
//


import SwiftUI
import Foundation

struct CompassWidget: View {
	var qiblaManager: QiblaManager
	
	// Utilisation de isFinite protège à la fois contre NaN et contre +Infinity / -Infinity
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
				.frame(width: 320, height: 320)
				.blur(radius: 20)
				.animation(.easeInOut(duration: 0.6), value: qiblaManager.isAligned)
			
			// Repère fixe du Nord au centre en haut
			Image(systemName: "triangle.fill")
				.font(.system(size: 12))
				.foregroundStyle(.white)
				.rotationEffect(.degrees(180))
				.offset(y: -155)
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
			
			// Le cadran et l'indicateur Qibla qui tournent
			ZStack {
				CompassDial()
				
				QiblaPointer(isAligned: qiblaManager.isAligned)
					.rotationEffect(.degrees(safeQiblaAngle))
			}
			.frame(width: 300, height: 300)
			.rotationEffect(.degrees(-safeHeading))
		}
		.frame(height: 320)
		.animation(.interactiveSpring(response: 0.6, dampingFraction: 0.6), value: safeHeading)
	}
}

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
                        .font(.system(size: 26, weight: .bold))
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
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(y: -105)
                        .rotationEffect(.degrees(Double(degree)))
                } else if degree == 180 {
                    Text("S")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(y: -105)
                        .rotationEffect(.degrees(Double(degree)))
                } else if degree == 270 {
                    Text("O")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(y: -105)
                        .rotationEffect(.degrees(Double(degree)))
                } else {
                    Text(degree, format: .number.precision(.fractionLength(0)))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .offset(y: -105)
                        .rotationEffect(.degrees(Double(degree)))
                }
            }
        }
        .frame(width: 300, height: 300)
        // Optimize: Rasterize the complex rotating compass dial to a single Metal texture, reducing CPU overhead
        .drawingGroup()
    }
}

struct QiblaPointer: View {
    var isAligned: Bool
    
    var body: some View {
        ZStack {
            // Ligne fine du centre vers le bord
            Rectangle()
                .fill(isAligned ? .white : .green.opacity(0.7))
                .frame(width: 2, height: 135)
                .offset(y: -67.5)
                
            // Icône au bord du cadran
            Image(systemName: "triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(isAligned ? .white : .green.opacity(0.7))
                .symbolEffect(.pulse.byLayer, isActive: isAligned)
                .offset(y: -145)
            
            // Point central
            Circle()
                .fill(isAligned ? .white : .green.opacity(0.8))
                .frame(width: 8, height: 8)
        }
    }
}

struct PrayerTimesList: View {
    let prayers: [PrayerTime]
    var nextPrayer: PrayerTime? = nil

    var body: some View {
        ScrollView(.horizontal) {
            // Optimize: Use LazyHStack to avoid off-screen rendering
            LazyHStack(spacing: 15) {
                // Optimize: Avoid enumerated() tuple wrapping since index is unused
                ForEach(prayers, id: \.id) { prayer in
                    let isNext = prayer.id == nextPrayer?.id

                    VStack(spacing: 8) {
                        Image(systemName: prayer.icon)
                            .font(.title2)
                            .foregroundStyle(isNext ? .white : .blue)
                        Text(prayer.name)
                            .font(.caption).bold()
                            .foregroundStyle(isNext ? .white : .primary)
                        Text(prayer.time)
                            .font(.caption2)
                            .foregroundStyle(isNext ? .white.opacity(0.8) : .secondary)
                    }
                    .frame(width: 80, height: 100)
                    .background(isNext ? AnyShapeStyle(.blue) : AnyShapeStyle(.thinMaterial))
                    .clipShape(.rect(cornerRadius: 5))
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
    var illumination: Double

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: moonIcon)
                .font(.system(size: 20))
                .foregroundStyle(.blue)
            Text("\(moonName) • \(illumination.formatted(.percent.precision(.fractionLength(0))))")
                .font(.footnote)
                .bold()
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.thinMaterial)
        .clipShape(.rect(cornerRadius: 5))
    }
}

struct HilalObservationView: View {
    let visibility: HilalVisibility

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.blue)
                Text("Observation du Hilal ce soir")
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(.blue)
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
        .background(.thinMaterial)
        .clipShape(.rect(cornerRadius: 5))
    }
}

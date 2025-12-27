//
//  CompassDial.swift
//  COLDFRAME
//
//  Created by Mo on 17/12/2025.
//


import SwiftUI

struct CompassDial: View {
	var body: some View {
		ZStack {
			// Fond avec Glassmorphism
			Circle()
				.fill(.ultraThinMaterial)
				.overlay(Circle().stroke(LinearGradient(colors: [.gold, .gold.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 3))
				.shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
			
			// Graduations
			ForEach(0..<60) { i in
				// Graduation majeure tous les 5 (donc 12 principales)
				let isMajor = i % 5 == 0
				Rectangle()
					.fill(isMajor ? Color.gold : Color.secondary)
					.frame(width: isMajor ? 2 : 1, height: isMajor ? 15 : 7)
					.offset(y: -135)
					.rotationEffect(.degrees(Double(i) * 6))
			}
			
			// Points cardinaux
			ForEach(["N", "E", "S", "O"], id: \.self) { dir in
				Text(dir)
					.font(.caption).bold().foregroundStyle(.primary)
					.offset(y: -110)
					.rotationEffect(.degrees(dir == "N" ? 0 : dir == "E" ? 90 : dir == "S" ? 180 : 270))
			}
		}
	}
}

struct QiblaPointer: View {
	var isAligned: Bool
	var body: some View {
		VStack(spacing: 0) {
			Image(systemName: "moon.stars.circle")
				.font(.system(size: 40))
				.foregroundStyle(isAligned ? Color.gold : .white)
				.shadow(color: isAligned ? .gold.opacity(0.8) : .clear, radius: 20)
                .symbolEffect(.bounce, value: isAligned)
			Rectangle()
				.fill(LinearGradient(colors: [isAligned ? .gold : .white, .clear], startPoint: .top, endPoint: .bottom))
				.frame(width: 4, height: 110)
				.clipShape(.rect(cornerRadius: 2))
		}
	}
}

struct PrayerTimesList: View {
	let prayers: [PrayerTime]
	var body: some View {
		ScrollView(.horizontal) {
			HStack(spacing: 15) {
				ForEach(prayers) { prayer in
					VStack(spacing: 8) {
						Image(systemName: prayer.icon)
                            .font(.title2)
                            .foregroundStyle(Color.gold)
                            .symbolEffect(.pulse.byLayer, isActive: true)
						Text(prayer.name)
                            .font(.caption).bold()
                            .foregroundStyle(.primary)
						Text(prayer.time)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
					}
					.frame(width: 80, height: 100)
					.background(.regularMaterial)
					.clipShape(.rect(cornerRadius: 20))
					.overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(LinearGradient(colors: [.gold.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
				}
			}
			.padding(.horizontal)
            .contentMargins(.horizontal, 20, for: .scrollContent)
		}
        .scrollIndicators(.hidden)
	}
}

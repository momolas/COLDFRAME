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
			// Fond
			Circle()
				.fill(Color(white: 0.1))
				.overlay(Circle().stroke(Color.gold, lineWidth: 2))
				.shadow(color: .black.opacity(0.5), radius: 10)
			
			// Graduations
			ForEach(0..<12) { i in
				Rectangle()
					.fill(i % 3 == 0 ? Color.gold : Color.gray)
					.frame(width: 2, height: i % 3 == 0 ? 15 : 7)
					.offset(y: -135)
					.rotationEffect(.degrees(Double(i) * 30))
			}
			
			// Points cardinaux
			ForEach(["N", "E", "S", "O"], id: \.self) { dir in
				Text(dir)
					.font(.caption).bold().foregroundStyle(Color.white)
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
				.font(.largeTitle)
				.foregroundStyle(isAligned ? Color.gold : Color.white)
				.shadow(color: isAligned ? .gold : .clear, radius: 15)
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
						Image(systemName: prayer.icon).font(.title2).foregroundStyle(Color.gold)
						Text(prayer.name).font(.caption).bold().foregroundStyle(Color.white)
						Text(prayer.time).font(.caption2).foregroundStyle(Color.gray)
					}
					.frame(width: 80, height: 100)
					.background(Color(white: 0.15))
					.clipShape(.rect(cornerRadius: 15))
					.overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.gold.opacity(0.3), lineWidth: 1))
				}
			}
			.padding(.horizontal)
		}
        .scrollIndicators(.hidden)
	}
}

//
//  PrayerTimesList.swift
//  COLDFRAME
//

import SwiftUI

struct PrayerTimesList: View {
    let prayers: [PrayerTime]
    var nextPrayer: PrayerTime? = nil

    private let defaultPrayerKeys: [(LocalizedStringKey, String)] = [
        ("prayer_fajr", "sun.haze.fill"),
        ("prayer_dhuhr", "sun.max.fill"),
        ("prayer_asr", "sun.min.fill"),
        ("prayer_maghrib", "sunset.fill"),
        ("prayer_isha", "moon.stars.fill")
    ]

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: DesignSystem.Spacing.medium) {
                if prayers.isEmpty {
                    ForEach(defaultPrayerKeys.indices, id: \.self) { idx in
                        let (key, icon) = defaultPrayerKeys[idx]
                        VStack(spacing: DesignSystem.Spacing.small) {
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundStyle(.blue.opacity(0.5))
                            Text(key)
                                .font(.caption).bold()
                                .foregroundStyle(.secondary)
                            Text("--:--")
                                .font(.caption2)
                                .foregroundStyle(.secondary.opacity(0.6))
                        }
                        .frame(width: 80, height: 100)
                        .background(Color.clear.background(.thinMaterial))
                        .clipShape(.rect(cornerRadius: DesignSystem.Layout.cornerRadius))
                    }
                } else {
                    ForEach(prayers) { prayer in
                        let isNext = prayer.id == nextPrayer?.id

                        VStack(spacing: DesignSystem.Spacing.small) {
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
                        .background {
                            if isNext {
                                Color.blue
                            } else {
                                Color.clear.background(.thinMaterial)
                            }
                        }
                        .clipShape(.rect(cornerRadius: DesignSystem.Layout.cornerRadius))
                        .scaleEffect(isNext ? 1.05 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isNext)
                    }
                }
            }
            .padding(.horizontal)
            .contentMargins(.horizontal, DesignSystem.Spacing.large, for: .scrollContent)
        }
        .scrollIndicators(.hidden)
    }
}

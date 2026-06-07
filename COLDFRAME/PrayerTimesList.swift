//
//  PrayerTimesList.swift
//  COLDFRAME
//

import SwiftUI

struct PrayerTimesList: View {
    let prayers: [PrayerTime]
    var nextPrayer: PrayerTime? = nil

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: DesignSystem.Spacing.medium) {
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
            .padding(.horizontal)
            .contentMargins(.horizontal, DesignSystem.Spacing.large, for: .scrollContent)
        }
        .scrollIndicators(.hidden)
    }
}

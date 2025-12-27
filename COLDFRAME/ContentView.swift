//
//  ContentView 2.swift
//  COLDFRAME
//
//  Created by Mo on 17/12/2025.
//


import SwiftUI

struct ContentView: View {
    @State private var qiblaManager = QiblaManager()
    
    var body: some View {
        ZStack {
            // Fond Moderne
            RadialGradient(colors: [Color(red: 0.1, green: 0.1, blue: 0.2), .black], center: .center, startRadius: 20, endRadius: 500)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Titre
                VStack(spacing: 8) {
                    Text("COLDFRAME")
                        .font(.largeTitle)
                        .fontDesign(.serif)
                        .fontWeight(.heavy)
                        .tracking(8)
                        .foregroundStyle(LinearGradient(colors: [.gold, .gold.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .shadow(color: .gold.opacity(0.3), radius: 10)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(qiblaManager.isAligned ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(qiblaManager.isAligned ? "Aligné" : "Recherche...")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(qiblaManager.isAligned ? Color.green : Color.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(.capsule)
                }
                .padding(.top)
                
                Spacer()
                
                // Boussole
                ZStack {
                    CompassDial()
                        .frame(width: 300, height: 300)
                        .rotationEffect(.degrees(-qiblaManager.heading))
                    QiblaPointer(isAligned: qiblaManager.isAligned)
                        .rotationEffect(.degrees(qiblaManager.qiblaAngle - qiblaManager.heading))
                }
                .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.6), value: qiblaManager.heading)
                
                Spacer()
                
                // Horaires
                VStack(alignment: .leading, spacing: 10) {
                    Text("Horaires de Prière")
						.font(.headline)
                        .fontDesign(.serif)
						.foregroundStyle(Color.gold)
						.padding(.leading, 20)
                    PrayerTimesList(prayers: qiblaManager.prayerTimes)
                }
                .frame(height: 160)
                .background(
                    LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                )
                
            }
            .padding(.bottom)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: qiblaManager.isAligned) { _, newValue in
            newValue
        }
    }
}

#Preview {
	ContentView()
}

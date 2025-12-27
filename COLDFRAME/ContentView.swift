//
//  ContentView 2.swift
//  COLDFRAME
//
//  Created by Mo on 17/12/2025.
//


import SwiftUI
import CoreLocation

struct ContentView: View {
    @State private var qiblaManager = QiblaManager()
    
    var body: some View {
        ZStack {
            // Fond Moderne
            RadialGradient(colors: [Color(red: 0.1, green: 0.1, blue: 0.2), .black], center: .center, startRadius: 20, endRadius: 500)
                .ignoresSafeArea()
            
            if qiblaManager.authorizationStatus == .denied || qiblaManager.authorizationStatus == .restricted {
                VStack(spacing: 20) {
                    Image(systemName: "location.slash.circle")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.gold)
                    Text("Localisation requise")
                        .font(.title2).bold()
                        .fontDesign(.serif)
                        .foregroundStyle(.white)
                    Text("Veuillez autoriser l'accès à la localisation dans les paramètres pour utiliser la boussole Qibla.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.gray)
                        .padding(.horizontal)

                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Ouvrir les Réglages")
                            .bold()
                            .padding()
                            .background(Color.gold)
                            .foregroundStyle(.black)
                            .clipShape(.capsule)
                    }
                }
            } else {
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
                        PrayerTimesList(prayers: qiblaManager.prayerTimes, nextPrayer: qiblaManager.nextPrayer)
                    }
                    .frame(height: 160)
                    .background(
                        LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                    )

                }
                .padding(.bottom)
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: qiblaManager.isAligned) { _, newValue in
            newValue
        }
    }
}

#Preview {
	ContentView()
}

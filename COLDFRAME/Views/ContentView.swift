//
//  ContentView.swift
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
            (qiblaManager.isAligned ? Color.green : Color.clear)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: qiblaManager.isAligned)
            
            if qiblaManager.authorizationStatus == .denied || qiblaManager.authorizationStatus == .restricted {
                VStack(spacing: DesignSystem.Spacing.large) {
                    Image(systemName: "location.slash.circle")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                    Text("Localisation requise")
                        .font(.title2).bold()
                        .foregroundStyle(.white)
                    Text("Veuillez autoriser l'accès à la localisation dans les paramètres pour utiliser la boussole Qibla.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.gray)
                        .padding(.horizontal)

                    Button("Ouvrir les Réglages", action: openSettings)
                        .bold()
                        .buttonStyle(.borderedProminent)
                }
            } else {
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.large) {
                        // Titre
                        VStack(spacing: DesignSystem.Spacing.small) {
                            Text("COLDFRAME")
                                .font(.largeTitle.weight(.light))
                                .fontDesign(.rounded)
                                .foregroundStyle(qiblaManager.isAligned ? .white : .green)

                            Text(qiblaManager.islamicDate)
                                .font(.title3.weight(.medium))
                                .foregroundStyle(.secondary)

                            if !qiblaManager.moonPhaseName.isEmpty {
                                MoonPhaseView(
                                    moonName: qiblaManager.moonPhaseName,
                                    moonIcon: qiblaManager.moonPhaseIcon,
                                    illumination: qiblaManager.moonIllumination
                                )
                            }
                        }
                        .padding(.top)

                        // Boussole Modernisée (Style Apple)
                        CompassWidget(qiblaManager: qiblaManager)

                        // Horaires de Prière et Hilal
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                            Text("Horaires de Prière")
                                .font(.title3.weight(.medium))
                                .foregroundStyle(.secondary)
                                .padding(.leading)

                            PrayerTimesList(prayers: qiblaManager.prayerTimes, nextPrayer: qiblaManager.nextPrayer)

                            // Tracker d'observation du Hilal / Lune
                            HilalObservationView(data: qiblaManager.hilalObservation)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, DesignSystem.Spacing.large)
                }
                .scrollIndicators(.hidden)
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: qiblaManager.isAligned) { _, newValue in
            newValue
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}

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
            (qiblaManager.isAligned ? Color.green : Color.clear)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: qiblaManager.isAligned)
            
            if qiblaManager.authorizationStatus == .denied || qiblaManager.authorizationStatus == .restricted {
                VStack(spacing: 20) {
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

                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Ouvrir les Réglages")
                            .bold()
                            .padding()
                            .background(.blue)
                    }
                }
            } else {
                VStack(spacing: 20) {
                    // Titre
                    VStack(spacing: 8) {
                        Text("COLDFRAME")
                            .font(.largeTitle)
                            .fontWeight(.light)
                            .fontDesign(.rounded)
                            .foregroundStyle(qiblaManager.isAligned ? .white : .green)

                        Text(qiblaManager.islamicDate)
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .padding(.top, -4)

                        if !qiblaManager.moonPhaseName.isEmpty {
                            MoonPhaseView(
                                moonName: qiblaManager.moonPhaseName,
                                moonIcon: qiblaManager.moonPhaseIcon,
                                illumination: qiblaManager.moonIllumination
                            )
                            .padding(.top, 4)
                        }
                    }
                    .padding(.top)
                    
                    Spacer()
                    
                    // Boussole Modernisée (Style Apple)
                    // Optimize: Isolated in its own view to prevent high-frequency heading updates from re-rendering the entire ContentView
                    QiblaCompassWidget(qiblaManager: qiblaManager)
                    
                    Spacer()
                    
                    // Horaires et Hilal
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Horaires de Prière")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 20)
                        PrayerTimesList(prayers: qiblaManager.prayerTimes, nextPrayer: qiblaManager.nextPrayer)

                        // Afficher le Tracker de Hilal uniquement si c'est le jour d'observation
                        if qiblaManager.hilalVisibility != .notObservationDay {
                            HilalObservationView(visibility: qiblaManager.hilalVisibility)
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                        }
                    }
                    .padding(.bottom, qiblaManager.hilalVisibility != .notObservationDay ? 20 : 0)
                    .background(.clear)
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

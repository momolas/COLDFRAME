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
            Color.clear
                .ignoresSafeArea()
            
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
                            .foregroundStyle(.green)

                        Text(qiblaManager.islamicDate)
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .padding(.top, -4)

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

                        if !qiblaManager.moonPhaseName.isEmpty {
                            MoonPhaseView(moonName: qiblaManager.moonPhaseName, moonIcon: qiblaManager.moonPhaseIcon)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.top)
                    
                    Spacer()
                    
                    // Boussole Modernisée (Style Apple)
                    ZStack {
                        // Halo de validation arrière-plan
                        Circle()
                            .fill(qiblaManager.isAligned ? Color.green.opacity(0.15) : Color.clear)
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
                                .fill(Color.white.opacity(0.4))
                                .frame(width: 1, height: 40)
                            Rectangle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: 40, height: 1)
                        }
                        .zIndex(2)
                        
                        // Degré actuel au centre
                        Text("\(qiblaManager.heading.formatted(.number.precision(.fractionLength(0))))°")
                            .font(.system(size: 40, weight: .light))
                            .fontDesign(.rounded)
                            .foregroundStyle(.white)
                            .offset(y: -55)
                            .zIndex(2)

                        // Le cadran et l'indicateur Qibla qui tournent
                        ZStack {
                            CompassDial()
                            
                            QiblaPointer(isAligned: qiblaManager.isAligned)
                                .rotationEffect(.degrees(qiblaManager.qiblaAngle))
                        }
                        .frame(width: 300, height: 300)
                        .rotationEffect(.degrees(-qiblaManager.heading))
                    }
                    .frame(height: 320)
                    .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.6), value: qiblaManager.heading)
                    
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

//
//  ContentView 2.swift
//  COLDFRAME
//
//  Created by Mo on 17/12/2025.
//


import SwiftUI
import MapKit

struct ContentView: View {
    @State private var qiblaManager = QiblaManager()
    
    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Titre
                VStack {
                    Text("COLDFRAME")
                        .font(.largeTitle)
                        .fontDesign(.serif)
                        .fontWeight(.light)
                        .tracking(5)
                        .foregroundStyle(Color.gold)
                    Text(qiblaManager.isAligned ? "Aligné" : "Recherche...")
                        .font(.caption)
                        .foregroundStyle(qiblaManager.isAligned ? Color.green : Color.white.opacity(0.5))
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
                .animation(.interactiveSpring(response: 0.8, dampingFraction: 0.6), value: qiblaManager.heading)
                
                Spacer()
                
                // Horaires
                VStack(alignment: .leading) {
                    Text("Horaires de Prière").font(.headline).foregroundStyle(Color.gold).padding(.leading)
                    PrayerTimesList(prayers: qiblaManager.prayerTimes)
                }
                .frame(height: 140)
                
                // Carte
                Map {
                    if let user = qiblaManager.userLocation {
                        Annotation("Moi", coordinate: user) {
                            Image(systemName: "person.circle.fill").foregroundStyle(Color.blue)
                        }
                        Annotation("Kaaba", coordinate: qiblaManager.meccaCoordinate) {
                            Image(systemName: "house.circle.fill").foregroundStyle(Color.gold)
                        }
                        MapPolyline(coordinates: [user, qiblaManager.meccaCoordinate])
                            .stroke(Color.gold, lineWidth: 2)
                    }
                }
                .frame(height: 120)
                .clipShape(.rect(cornerRadius: 20))
                .padding([.horizontal, .bottom])
                .saturation(0)
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

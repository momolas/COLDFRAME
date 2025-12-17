import SwiftUI
import MapKit

struct ContentView: View {
	@StateObject private var qiblaManager = QiblaManager()
	
	var body: some View {
		ZStack {
			// Fond sombre global
			Color.darkBackground.ignoresSafeArea()
			
			VStack(spacing: 20) {
				// 1. Titre
				VStack {
					Text("AL QIBLA")
						.font(.system(size: 28, weight: .light, design: .serif))
						.tracking(5)
						.foregroundColor(.gold)
					
					Text(qiblaManager.isAligned ? "ALIGNÉ AVEC LA MECQUE" : "RECHERCHE...")
						.font(.caption)
						.foregroundColor(qiblaManager.isAligned ? .green : .white.opacity(0.5))
						.animation(.easeInOut, value: qiblaManager.isAligned)
				}
				.padding(.top)
				
				Spacer()
				
				// 2. Boussole
				ZStack {
					CompassDial()
						.frame(width: 300, height: 300)
						.rotationEffect(.degrees(-qiblaManager.heading))
					
					QiblaPointer(isAligned: qiblaManager.isAligned)
						.rotationEffect(.degrees(qiblaManager.qiblaAngle - qiblaManager.heading))
				}
				.animation(.smooth(duration: 0.5), value: qiblaManager.heading)
				
				Spacer()
				
				// 3. Horaires
				VStack(alignment: .leading) {
					Text("Horaires de Prière")
						.font(.headline)
						.foregroundColor(.gold)
						.padding(.leading)
					
					PrayerTimesList(prayers: qiblaManager.prayerTimes)
				}
				.frame(height: 140)
				
				// 4. Carte
				Map {
					if let user = qiblaManager.userLocation {
						Annotation("Moi", coordinate: user) {
							Image(systemName: "person.circle.fill").foregroundColor(.blue)
						}
						Annotation("Kaaba", coordinate: qiblaManager.meccaCoordinate) {
							Image(systemName: "mosque.fill").foregroundColor(.gold)
						}
						MapPolyline(coordinates: [user, qiblaManager.meccaCoordinate])
							.stroke(Color.gold, lineWidth: 2)
					}
				}
				.mapStyle(.standard(elevation: .realistic))
				.frame(height: 120)
				.clipShape(RoundedRectangle(cornerRadius: 20))
				.padding([.horizontal, .bottom])
				.saturation(0) // Carte en noir et blanc pour le style
			}
		}
	}
}

#Preview {
	ContentView()
}

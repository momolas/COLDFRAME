//
//  QiblaPointer.swift
//  COLDFRAME
//

import SwiftUI

struct QiblaPointer: View {
    var isAligned: Bool
    
    var body: some View {
        ZStack {
            // Ligne fine du centre vers le bord
            Rectangle()
                .fill(isAligned ? Color.green : Color.green.opacity(0.75))
                .frame(width: 2, height: 130)
                .offset(y: -65)
                
            // Badge distinctif QIBLA (Direction La Mecque)
            VStack(spacing: 1) {
                Image(systemName: "location.north.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isAligned ? Color.white : Color.green)
                    .shadow(color: isAligned ? Color.green : Color.clear, radius: 8)

                Text("QIBLA")
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(isAligned ? Color.white : Color.green)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.black.opacity(0.8))
                    .clipShape(.capsule)
            }
            .offset(y: -145)
            
            // Point central émeraude
            Circle()
                .fill(isAligned ? Color.white : Color.green)
                .frame(width: 8, height: 8)
        }
    }
}

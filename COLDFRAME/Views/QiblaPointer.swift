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
                .fill(isAligned ? .green : .green.opacity(0.75))
                .frame(width: 2, height: 130)
                .offset(y: -65)
                
            // Badge distinctif QIBLA (Direction La Mecque)
            VStack(spacing: 1) {
                Image(systemName: "location.north.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isAligned ? .white : .green)
                    .shadow(color: isAligned ? .green : .clear, radius: 8)

                Text("qibla_pointer_badge")
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(isAligned ? .white : .green)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(.black.opacity(0.8))
                    .clipShape(.capsule)
            }
            .offset(y: -145)
            
            // Point central émeraude
            Circle()
                .fill(isAligned ? .white : .green)
                .frame(width: 8, height: 8)
        }
    }
}

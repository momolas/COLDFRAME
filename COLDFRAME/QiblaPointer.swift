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
                .fill(isAligned ? .white : .green.opacity(0.7))
                .frame(width: 2, height: 135)
                .offset(y: -67.5)
                
            // Icône au bord du cadran
            Image(systemName: "triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(isAligned ? .white : .green.opacity(0.7))
                .symbolEffect(.pulse.byLayer, isActive: isAligned)
                .offset(y: -145)
            
            // Point central
            Circle()
                .fill(isAligned ? .white : .green.opacity(0.8))
                .frame(width: 8, height: 8)
        }
    }
}

//
//  Double+Conversions.swift
//  COLDFRAME
//

import Foundation

extension Double {
    var deg2rad: Double { return self * .pi / 180 }
    var rad2deg: Double { return self * 180 / .pi }
}

//
//  Line.swift
//  DrawingApp
//
//  Created by ali on 12/11/25.
//

import SwiftUI

// This structure holds the data for a single drawn line.
struct Line: Identifiable {
    let id = UUID()
    var points: [CGPoint] = []
    var color: Color = .black
    var lineWidth: CGFloat = 5
}

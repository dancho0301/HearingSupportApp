//
//  HearingGraph.swift
//  HearingSupportApp
//
//  Created by dancho on 2025/06/01.
//


import SwiftUI

struct HearingGraph: View {
    let freqs: [String]
    let values: [Int?]
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let points = values.enumerated()
                .compactMap { (i, v) -> CGPoint? in
                    guard let v = v else { return nil }
                    let x = geo.size.width * CGFloat(i) / CGFloat(freqs.count - 1)
                    let y = geo.size.height * (1 - CGFloat(v) / 120.0)
                    return CGPoint(x: x, y: y)
                }

            Path { path in
                if let first = points.first {
                    path.move(to: first)
                    for p in points.dropFirst() {
                        path.addLine(to: p)
                    }
                }
            }
            .stroke(color, lineWidth: 2)
            ForEach(0..<points.count, id: \.self) { i in
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                    .position(points[safe: i] ?? .zero)
            }
        }
        .frame(height: 60)
        .padding(.vertical, 2)
    }
}

// 安全な配列参照用
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

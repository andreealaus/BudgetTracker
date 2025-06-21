import SwiftUI

struct PieChartView: View {
    var data: [Double]
    var colors: [Color]
    
    var total: Double {
        data.reduce(0, +)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<data.count, id: \.self) { index in
                    let startAngle = angle(for: index)
                    let endAngle = angle(for: index + 1)
                    let midAngle = (startAngle.radians + endAngle.radians) / 2
                    
                    // Pie Slice
                    PieSliceView(startAngle: startAngle, endAngle: endAngle, color: colors[index % colors.count])
                    
                    // Percentage Text
                    if data[index] > 0 { // Only show percentage for non-zero values
                        Text("\(percentage(for: data[index]))%")
                            .font(.caption)
                            .foregroundColor(.white)
                            .position(position(for: midAngle, in: geometry.size))
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.width)
        }
    }
    
    private func angle(for index: Int) -> Angle {
        let value = data.prefix(index).reduce(0, +)
        return .degrees((value / total) * 360)
    }
    
    private func percentage(for value: Double) -> String {
        let percentage = (value / total) * 100
        return String(format: "%.1f", percentage)
    }
    
    private func position(for midAngle: Double, in size: CGSize) -> CGPoint {
        let radius = size.width / 2 * 0.6 // Reduce radius for text placement closer to the center of the slice
        let x = size.width / 2 + radius * cos(midAngle)
        let y = size.height / 2 + radius * sin(midAngle)
        return CGPoint(x: x, y: y)
    }
}

struct PieSliceView: View {
    var startAngle: Angle
    var endAngle: Angle
    var color: Color
    
    var body: some View {
        Path { path in
            let center = CGPoint(x: 100, y: 100)
            path.move(to: center)
            path.addArc(center: center, radius: 100, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        }
        .fill(color)
    }
}
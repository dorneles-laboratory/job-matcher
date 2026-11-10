import SwiftUI

struct CompatibilityBadge: View {
    let percentage: Int
    
    var color: Color {
        switch percentage {
        case 75...100: return .green
        case 50..<75: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "bolt.shield.fill")
            Text("\(percentage)% Match")
                .fontWeight(.bold)
        }
        .font(.caption)
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color)
        .clipShape(Capsule())
        .shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 2)
    }
}

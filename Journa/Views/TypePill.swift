import SwiftUI

struct TypePill: View {
    var icon: String
    var color: Color
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 10))
            .foregroundColor(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(5)
    }
}

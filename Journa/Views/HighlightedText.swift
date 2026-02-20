import SwiftUI

struct HighlightedText: View {
    var text: String
    var query: String
    var baseColor: Color = .white
    var highlightColor: Color = Color(hex: "FFD700")
    
    var attributed: AttributedString {
        var result = AttributedString(text)
        result.foregroundColor = UIColor(baseColor)
        
        guard !query.isEmpty else { return result }
        
        let str = text
        var searchStart = str.startIndex
        
        while searchStart < str.endIndex,
              let range = str.range(of: query, options: .caseInsensitive, range: searchStart..<str.endIndex) {
            
            let attrStart = AttributedString.Index(range.lowerBound, within: result)
            let attrEnd = AttributedString.Index(range.upperBound, within: result)
            
            if let s = attrStart, let e = attrEnd {
                result[s..<e].foregroundColor = UIColor(highlightColor)
                result[s..<e].font = .boldSystemFont(ofSize: UIFont.systemFontSize)
            }
            
            searchStart = range.upperBound
        }
        
        return result
    }
    
    var body: some View {
        Text(attributed)
    }
}

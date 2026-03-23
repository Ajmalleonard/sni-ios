
import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        return CGSize(width: proposal.width ?? 0, height: rows.last?.maxY ?? 0)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        
        for row in rows {
            for element in row.elements {
                element.subview.place(at: CGPoint(x: bounds.minX + element.x, y: bounds.minY + row.y), proposal: .unspecified)
            }
        }
    }
    
    struct Row {
        var elements: [Element] = []
        var y: CGFloat = 0
        var height: CGFloat = 0
        
        var maxY: CGFloat {
            y + height
        }
    }
    
    struct Element {
        var subview: LayoutSubview
        var x: CGFloat
    }
    
    func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()
        var x: CGFloat = 0
        let maxWidth = proposal.width ?? 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if x + size.width > maxWidth && !currentRow.elements.isEmpty {
                // Move to next row
                currentRow.y = (rows.last?.maxY ?? 0) + spacing
                rows.append(currentRow)
                currentRow = Row()
                x = 0
            }
            
            currentRow.elements.append(Element(subview: subview, x: x))
            currentRow.height = max(currentRow.height, size.height)
            x += size.width + spacing
        }
        
        if !currentRow.elements.isEmpty {
            currentRow.y = (rows.last?.maxY ?? 0) + spacing
            rows.append(currentRow)
        }
        
        return rows
    }
}

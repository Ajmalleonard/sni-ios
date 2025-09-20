//
//  SharedTypes.swift
//  SNI Rentals
//
//  Created by Assistant on 1/20/25.
//

import Foundation

// MARK: - Navigation Types
public enum NavigationDestination: Hashable {
    case profile
    case chat
    case notifications
}

// MARK: - Bottom Sheet Types
public enum BottomSheetState {
    case collapsed
    case quickActions
    case searchHistory
    case vehicleTypes
    case expanded
}

// MARK: - Swipe Direction
public enum SwipeDirection {
    case up
    case down
}

// MARK: - Bottom Sheet Height Constants
public struct BottomSheetHeights {
    static let collapsed: CGFloat = 80
    static let quickActions: CGFloat = 200
    static let searchHistory: CGFloat = 350
    static let expanded: CGFloat = 600
}

// MARK: - Search History
public struct SearchHistoryItem: Identifiable {
    public let id: Int
    public let fromLocation: String
    public let toLocation: String
    public let timestamp: Date
    
    public var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
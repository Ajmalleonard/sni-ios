////
////  Searcher.swift
////  SNI Rentals
////
////  Created by Ajmal Leonard on 12/08/2025.
////
//
//import SwiftUI
//
//struct Searcher: View {
//    var searchView: some View {
//        ScrollView {
//            VStack(spacing: 24) {
//                searchHeader
//                searchFields
//                recentSearches
//                Spacer(minLength: 100)
//            }
//            .padding(.horizontal, 20)
//        }
//    }
//}
//
//#Preview {
//    Searcher()
//}
//
//// Search view
//
//
//// Search header
//private var searchHeader: some View {
//    HStack {
//        Text("Plan Your Trip")
//            .font(.title3)
//            .fontWeight(.bold)
//            .foregroundColor(.black)
//        
//        Spacer()
//        
//        Button {
//            isSearchActive = false
//            if sheetDetent == .large {
//                sheetDetent = .height(80)
//            }
//        } label: {
//            Image(systemName: "xmark.circle.fill")
//                .font(.title3)
//                .foregroundColor(.black)
//        }
//    }
//    .padding(.top, 16)
//}
//
//// Search fields
//private var searchFields: some View {
//    VStack(spacing: 16) {
//        HStack(spacing: 16) {
//            Image(systemName: "arrow.up.arrow.down")
//                .font(.headline)
//                .foregroundColor(.black)
//                .frame(width: 30)
//            
//            VStack(spacing: 20) {
//                TextField("From", text: $fromLocation)
//                    .padding()
//                    .background(Color.gray.opacity(0.1))
//                    .clipShape(Capsule())
//                
//                TextField("To", text: $toLocation)
//                    .padding()
//                    .background(Color.gray.opacity(0.1))
//                    .clipShape(Capsule())
//            }
//        }
//        
//        Button {
//            // Implement search action
//        } label: {
//            Text("Search")
//                .fontWeight(.semibold)
//                .frame(maxWidth: .infinity)
//                .padding()
//                .background(Color.black)
//                .foregroundColor(.white)
//                .clipShape(Capsule())
//        }
//    }
//    .padding(.top, 16)
//}
//
//// Recent searches
//private var recentSearches: some View {
//    VStack(alignment: .leading, spacing: 16) {
//        Text("Recent Searches")
//            .font(.headline)
//            .foregroundColor(.black)
//            .padding(.top, 16)
//        
//        ForEach(["Dodoma to City Center", "Hotel Zone to Beach", "Sinza to Mall"], id: \.self) { search in
//            HStack {
//                Image(systemName: "clock")
//                    .foregroundColor(.black)
//                Text(search)
//                    .foregroundColor(.black)
//                Spacer()
//            }
//            .padding()
//            .background(Color.gray.opacity(0.1))
//            .clipShape(Capsule())
//        }
//    }
//}

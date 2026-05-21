//
//  AddBirdView.swift
//  BirdWatch
//
//  Created by Ryan Brunk on 5/19/26.
//

import SwiftUI
import SwiftData

struct AddBirdView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Fetch all birds to filter through. Because there are only ~1100,
    // loading them into memory to filter is incredibly fast.
    @Query(sort: \Bird.commonName) private var allBirds: [Bird]
    
    // We need the active checklist to append the new sighting to
    @Query(sort: \Checklist.startTime, order: .reverse) private var checklists: [Checklist]
    var activeChecklist: Checklist? {
        checklists.first
    }
    
    // The search text bound to the .searchable modifier
    @State private var searchText = ""
    
    // Dynamic property to filter and smartly sort the birds list
    var searchResults: [Bird] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        
        if query.isEmpty {
            return allBirds
        }
        
        // 1. Filter: Keep only birds that contain the query in their code OR name
        let filtered = allBirds.filter {
            $0.alphaCode.lowercased().contains(query) ||
            $0.commonName.lowercased().contains(query)
        }
        
        // 2. Smart Sort: Rank the results based on match quality
        return filtered.sorted { b1, b2 in
            let b1AlphaPrefix = b1.alphaCode.lowercased().hasPrefix(query)
            let b2AlphaPrefix = b2.alphaCode.lowercased().hasPrefix(query)
            
            // Priority 1: Left-to-right exact Alpha Code matches float to the very top
            if b1AlphaPrefix != b2AlphaPrefix {
                return b1AlphaPrefix // true comes first
            }
            
            let b1NamePrefix = b1.commonName.lowercased().hasPrefix(query)
            let b2NamePrefix = b2.commonName.lowercased().hasPrefix(query)
            
            // Priority 2: Left-to-right Common Name matches come next
            if b1NamePrefix != b2NamePrefix {
                return b1NamePrefix
            }
            
            // Fallback: Alphabetical sort by common name
            return b1.commonName < b2.commonName
        }
    }
    
    var body: some View {
        List {
            // 1. BULLETPROOF SEARCH BAR
            // Guaranteed to show up at the top of the list on all watchOS versions
            Section {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.ebirdGreenLight)
                    TextField("Code or Name", text: $searchText)
                        .textFieldStyle(.plain) // Removes the inner nested background
                        .background(Color.clear)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .glassCard(isActive: true)
            }
            .listRowBackground(Color.clear)
            
            // 2. SEARCH RESULTS
            Section {
                ForEach(searchResults) { bird in
                    Button {
                        addSighting(for: bird)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(bird.alphaCode)
                                .font(.headline)
                                .foregroundColor(.ebirdGreen)
                            Text(bird.commonName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassCard()
                    }
                    .buttonStyle(TactileButtonStyle())
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                }
            }
        }
        .navigationTitle("Search")
        // Removed the finicky .searchable modifier entirely
    }
    
    private func addSighting(for bird: Bird) {
        guard let checklist = activeChecklist else { return }
        
        // 1. Check if the user already has this bird on their list
        if let existingSighting = checklist.sightings.first(where: { $0.bird?.alphaCode == bird.alphaCode }) {
            // If yes, just increment the count and bump its timestamp
            existingSighting.count += 1
            existingSighting.timestamp = Date()
        } else {
            // 2. If no, create a brand new sighting starting at count = 1
            let newSighting = Sighting(count: 1, bird: bird)
            newSighting.checklist = checklist
        }
        
        // 3. Play success haptic
        WKInterfaceDevice.current().play(.success)
        
        // 4. Dismiss this view to return to the active list automatically!
        dismiss()
    }
}

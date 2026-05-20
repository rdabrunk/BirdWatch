//
//  ContentView.swift
//  BirdWatch Watch App
//
//  Created by Ryan Brunk on 5/19/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    // Access the database environment
    @Environment(\.modelContext) private var modelContext
    
    // Automatically fetch all checklists, sorted by newest first
    @Query(sort: \Checklist.startTime, order: .reverse) private var checklists: [Checklist]
    
    // Helper to get the current active checklist
    var activeChecklist: Checklist? {
        checklists.first
    }
    
    // Helper to get sightings for the active checklist, sorted by chronological addition
    var sortedSightings: [Sighting] {
        activeChecklist?.sightings.sorted(by: { $0.timestamp < $1.timestamp }) ?? []
    }
    
    var body: some View {
        NavigationStack {
            // Changed from VStack to Group to fix toolbar collapsing logic
            Group {
                if sortedSightings.isEmpty {
                    // Upgraded Empty State with a central action button
                    VStack {
                        Image(systemName: "bird.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                            .padding(.bottom, 2)
                        
                        Text("No birds yet.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        NavigationLink(destination: AddBirdView()) {
                            Text("Add First Bird")
                                .fontWeight(.medium)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        // Iterate through actual SwiftData Sighting models
                        ForEach(sortedSightings) { sighting in
                            // NORMAL TAPPABLE ROW
                            Button {
                                WKInterfaceDevice.current().play(.click)
                                sighting.count += 1
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(sighting.bird?.alphaCode ?? "???")
                                            .font(.system(.title3, design: .rounded))
                                            .fontWeight(.bold)
                                            .foregroundColor(.orange)
                                        
                                        Text(sighting.bird?.commonName ?? "Unknown Species")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(sighting.count)")
                                        .font(.system(.title2, design: .rounded))
                                        .fontWeight(.semibold)
                                        .frame(minWidth: 44, minHeight: 44)
                                        .background(sighting.count > 0 ? Color.orange.opacity(0.2) : Color.white.opacity(0.1))
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(sighting.count > 0 ? Color.orange : Color.clear, lineWidth: 1)
                                        )
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            // 1. Swipe Right-to-Left (.trailing) for -1
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    if sighting.count > 0 {
                                        sighting.count -= 1
                                    }
                                } label: {
                                    Label("-1", systemImage: "minus.circle.fill")
                                }
                                .tint(.yellow)
                            }
                            // 2. Swipe Left-to-Right (.leading) for Delete
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    modelContext.delete(sighting)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.carousel)
                }
            } // End of Group
            .navigationTitle("Active List")
            .toolbar {
                // We only show the top-right toolbar button if the list has items.
                // If it's empty, they will use the big central button instead!
                if !sortedSightings.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        NavigationLink(destination: AddBirdView()) {
                            Label("Add Bird", systemImage: "plus")
                        }
                    }
                }
            }
            .onAppear {
                setupInitialData()
            }
        }
    }
    
    private func setupInitialData() {
        // If we don't have a checklist at all, create one
        if checklists.isEmpty {
            let newChecklist = Checklist()
            modelContext.insert(newChecklist)
            
            // --- TEMPORARY TEST DATA ---
            // Let's query the database we built for two common birds to populate the UI
            let fetchDescriptor = FetchDescriptor<Bird>(
                predicate: #Predicate { $0.alphaCode == "AMRO" || $0.alphaCode == "BCCH" }
            )
            
            if let testBirds = try? modelContext.fetch(fetchDescriptor) {
                for bird in testBirds {
                    let newSighting = Sighting(count: 0, bird: bird)
                    newSighting.checklist = newChecklist // Link it to the checklist
                }
            }
        }
    }
}

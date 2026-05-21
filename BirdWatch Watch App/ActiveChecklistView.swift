//
//  ActiveChecklistView.swift
//  BirdWatch Watch App
//
//  Created by Ryan Brunk on 5/21/26.
//

import SwiftUI
import SwiftData

struct ActiveChecklistView: View {
    @Environment(\.modelContext) private var modelContext
    
    let checklist: Checklist
    let onEnd: (Checklist) -> Void
    
    @State private var showEndConfirmation = false
    
    var sortedSightings: [Sighting] {
        checklist.sightings.sorted(by: { $0.timestamp < $1.timestamp })
    }
    
    var body: some View {
        Group {
            if sortedSightings.isEmpty {
                VStack {
                    Image(systemName: "bird.fill")
                        .font(.largeTitle)
                        .foregroundColor(.ebirdGreen)
                        .padding(.bottom, 2)
                    
                    Text("No birds yet.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    NavigationLink(destination: AddBirdView()) {
                        Text("Add First Bird")
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.ebirdGreen)
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(sortedSightings) { sighting in
                        Button {
                            WKInterfaceDevice.current().play(.directionUp)
                            sighting.count += 1
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(sighting.bird?.alphaCode ?? "???")
                                        .font(.system(.title3, design: .rounded))
                                        .fontWeight(.bold)
                                        .foregroundColor(sighting.count > 0 ? .ebirdGreen : .primary)
                                    
                                    Text(sighting.bird?.commonName ?? "Unknown Species")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Text("\(sighting.count)")
                                    .font(.system(.title2, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundColor(sighting.count > 0 ? .white : .secondary)
                                    .frame(minWidth: 44, minHeight: 44)
                                    .background(sighting.count > 0 ? Color.ebirdGreen.opacity(0.3) : Color.white.opacity(0.1))
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(sighting.count > 0 ? Color.ebirdGreen : Color.clear, lineWidth: 1)
                                    )
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .glassCard(isActive: sighting.count > 0)
                        }
                        .buttonStyle(TactileButtonStyle())
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                if sighting.count > 0 {
                                    WKInterfaceDevice.current().play(.directionDown)
                                    sighting.count -= 1
                                }
                            } label: {
                                Label("-1", systemImage: "minus.circle.fill")
                            }
                            .tint(.yellow)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                modelContext.delete(sighting)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    
                    // End Checklist Action Section
                    Section {
                        Button {
                            WKInterfaceDevice.current().play(.click)
                            showEndConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("End Checklist", systemImage: "checkmark.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.glassBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.4), lineWidth: 1)
                            )
                        }
                        .buttonStyle(TactileButtonStyle())
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    }
                }
                .listStyle(.carousel)
            }
        }
        .navigationTitle("Active List")
        .toolbar {
            if !sortedSightings.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink(destination: AddBirdView()) {
                        Label("Add Bird", systemImage: "plus")
                    }
                    .tint(.ebirdGreen)
                }
            }
        }
        .confirmationDialog("End Checklist?", isPresented: $showEndConfirmation, titleVisibility: .visible) {
            Button("End & Save", role: .destructive) {
                WKInterfaceDevice.current().play(.success)
                checklist.endTime = Date()
                try? modelContext.save()
                onEnd(checklist)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will finalize your sightings for this session.")
        }
    }
}

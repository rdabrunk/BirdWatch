//
//  ActiveChecklistView.swift
//  BirdWatch Watch App
//
//  Created by Ryan Brunk on 5/21/26.
//

import SwiftUI
import WatchKit

private let checklistTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

struct ActiveChecklistView: View {
    @EnvironmentObject private var taxonRegistry: TaxonRegistry
    @ObservedObject var session: ChecklistSession
    
    @State private var showEndConfirmation = false
    @State private var showDiscardConfirmation = false
    @State private var dictationQuery = ""
    @State private var navigateToAddTaxon = false
    @State private var redrawTrigger = false
    
    var sortedSightings: [Sighting] {
        guard let sightings = session.activeChecklist?.sightings else { return [] }
        return sightings.sorted { s1, s2 in
            let name1 = taxonRegistry.taxon(forAlphaCode: s1.alphaCode)?.commonName ?? s1.alphaCode
            let name2 = taxonRegistry.taxon(forAlphaCode: s2.alphaCode)?.commonName ?? s2.alphaCode
            return name1.localizedCaseInsensitiveCompare(name2) == .orderedAscending
        }
    }
    
    var body: some View {
        Group {
            if sortedSightings.isEmpty {
                VStack {
                    Image(systemName: "bird.fill")
                        .font(.largeTitle)
                        .foregroundColor(.ebirdGreen)
                        .padding(.bottom, 2)
                    
                    Text("No species recorded yet.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    addBirdButton {
                        Text("Add First Bird")
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.ebirdGreen)
                    .handGestureShortcut(.primaryAction)
                    .padding(.top, 8)
                    
                    Button(role: .destructive) {
                        showDiscardConfirmation = true
                    } label: {
                        Text("Discard Checklist")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section {
                        HStack(spacing: 0) {
                            HStack(spacing: 3) {
                                Image(systemName: "clock")
                                Text(session.activeChecklist?.formattedDuration ?? "")
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            .font(.system(size: 10, design: .rounded))
                            .foregroundColor(.secondary)
                            .id(redrawTrigger)
                            
                            if let active = session.activeChecklist, active.trackLocation {
                                Spacer()
                                HStack(spacing: 3) {
                                    Image(systemName: "figure.walk")
                                    Text(String(format: "%.2f mi", active.distanceMiles ?? 0.0))
                                        .lineLimit(1)
                                        .fixedSize(horizontal: true, vertical: false)
                                }
                                .font(.system(size: 10, design: .rounded))
                                .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 3) {
                                Image(systemName: "bird")
                                Text("\(session.activeChecklist?.totalTaxaCount ?? 0)")
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            .font(.system(size: 10, design: .rounded))
                            .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                        
                        addBirdButton {
                            HStack {
                                Spacer()
                                Label("Add Bird", systemImage: "plus")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.ebirdGreen)
                            )
                        }
                        .buttonStyle(TactileButtonStyle())
                        .handGestureShortcut(.primaryAction)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: -4, leading: 4, bottom: 4, trailing: 4))
                    }
                    
                    ForEach(sortedSightings) { sighting in
                        // Instant O(1) synchronous lookup from memory
                        let taxon = taxonRegistry.taxon(forAlphaCode: sighting.alphaCode)
                        
                        Button {
                            WKInterfaceDevice.current().play(.directionUp)
                            session.incrementTally(for: sighting)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(taxon?.alphaCode ?? sighting.alphaCode)
                                        .font(.system(.body, design: .rounded))
                                        .fontWeight(.bold)
                                        .foregroundColor(sighting.tally > 0 ? .ebirdGreen : .primary)
                                    
                                    Text(taxon?.commonName ?? "Unknown Species")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Text("\(sighting.tally)")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundColor(sighting.tally > 0 ? .white : .secondary)
                                    .frame(width: 32, height: 32)
                                    .background(sighting.tally > 0 ? Color.ebirdGreen.opacity(0.3) : Color.white.opacity(0.1))
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(sighting.tally > 0 ? Color.ebirdGreen : Color.clear, lineWidth: 1)
                                    )
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.glassBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(sighting.tally > 0 ? Color.ebirdGreen : Color.glassBorder, lineWidth: sighting.tally > 0 ? 1.5 : 1.0)
                            )
                        }
                        .buttonStyle(TactileButtonStyle())
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 1.5, leading: 4, bottom: 1.5, trailing: 4))
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                if sighting.tally > 0 {
                                    WKInterfaceDevice.current().play(.directionDown)
                                    session.decrementTally(for: sighting)
                                }
                            } label: {
                                Label("-1", systemImage: "minus.circle.fill")
                            }
                            .tint(.yellow)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                session.removeSighting(sighting)
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
        .toolbar(.hidden, for: .navigationBar)
        // Programmatic navigation triggered after dictation input
        .navigationDestination(isPresented: $navigateToAddTaxon) {
            AddTaxonView(session: session, initialQuery: dictationQuery)
        }
        .confirmationDialog("End Checklist?", isPresented: $showEndConfirmation, titleVisibility: .visible) {
            Button("End & Save", role: .destructive) {
                WKInterfaceDevice.current().play(.success)
                session.endSession()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will finalize your sightings for this checklist.")
        }
        .confirmationDialog("Discard Checklist?", isPresented: $showDiscardConfirmation, titleVisibility: .visible) {
            Button("Discard & Delete", role: .destructive) {
                WKInterfaceDevice.current().play(.directionDown)
                session.discardSession()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete this checklist and all recorded sightings.")
        }
        .onReceive(checklistTimer) { _ in
            redrawTrigger.toggle()
        }
    }
    
    // MARK: - Dictation Input
    
    private func addBirdButton<Label: View>(@ViewBuilder label: () -> Label) -> some View {
        Button {
            presentTextInput()
        } label: {
            label()
        }
    }
    
    private func presentTextInput() {
        WKApplication.shared().visibleInterfaceController?.presentTextInputController(
            withSuggestions: nil,
            allowedInputMode: .plain
        ) { result in
            guard let result = result as? [String], let first = result.first else { return }
            let trimmed = first.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return }
            DispatchQueue.main.async {
                dictationQuery = trimmed
                navigateToAddTaxon = true
            }
        }
    }
}

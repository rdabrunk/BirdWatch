//
//  HomeDashboardView.swift
//  BirdWatch Watch App
//
//  Created by Ryan Brunk on 5/21/26.
//

import SwiftUI
import SwiftData

struct HomeDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Checklists passed from parent
    let checklists: [Checklist]
    
    // The session coordinator
    @ObservedObject var session: ChecklistSession
    
    // We only show completed checklists in the history list
    var completedChecklists: [Checklist] {
        checklists.filter { $0.endTime != nil }
    }
    
    var body: some View {
        List {
            // Section 1: Session Control
            Section {
                Button(action: startNewSession) {
                    HStack(spacing: 12) {
                        Image(systemName: "bird.fill")
                            .font(.title2)
                            .foregroundColor(.ebirdGreen)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Start Session")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("Begin logging sightings")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .glassCard(isActive: true)
                }
                .buttonStyle(TactileButtonStyle())
                .listRowBackground(Color.clear)
            }
            
            // Section 2: Completed Session History
            Section(header: Text("Past Sessions").font(.system(size: 10, weight: .bold)).foregroundColor(.secondary)) {
                if completedChecklists.isEmpty {
                    VStack(spacing: 6) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("No completed lists")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(completedChecklists) { checklist in
                        NavigationLink(destination: ChecklistSummaryView(checklist: checklist, isModal: false)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(checklist.formattedDate)
                                        .font(.system(.body, design: .rounded))
                                        .fontWeight(.semibold)
                                    Text("\(checklist.formattedDuration) • \(checklist.formattedTimeRange.components(separatedBy: " - ").first ?? "")")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(checklist.totalTallyCount)")
                                        .font(.system(.body, design: .rounded))
                                        .fontWeight(.bold)
                                        .foregroundColor(.ebirdGreen)
                                    Text("\(checklist.totalTaxaCount) species")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .glassCard()
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    }
                }
            }
        }
        .navigationTitle("BirdWatch")
        .listStyle(.carousel)
    }
    
    private func startNewSession() {
        WKInterfaceDevice.current().play(.click)
        session.startNewSession()
    }
}

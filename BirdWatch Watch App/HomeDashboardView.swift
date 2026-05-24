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
    @EnvironmentObject private var taxonRegistry: TaxonRegistry
    
    // Checklists passed from parent
    let checklists: [Checklist]
    
    // The session coordinator
    @ObservedObject var session: ChecklistSession
    
    // We only show completed checklists in the history list
    var completedChecklists: [Checklist] {
        checklists.filter { $0.endTime != nil }
    }
    
    @State private var selectedChecklistForExport: Checklist? = nil
    @AppStorage("trackLocation") private var trackLocation = true
    
    var body: some View {
        List {
            // Section 1: Checklist Control
            Section {
                Toggle(isOn: $trackLocation) {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.ebirdGreen)
                        Text("Track Location")
                            .font(.system(.body, design: .rounded))
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .ebirdGreen))
                .padding(.horizontal, 4)
                .listRowBackground(Color.clear)
                
                Button(action: startNewSession) {
                    HStack(spacing: 8) {
                        Image(systemName: "bird.fill")
                            .font(.headline)
                            .foregroundColor(.ebirdGreen)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Start Checklist")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .allowsTightening(true)
                            Text("Begin logging")
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
            
            // Section 2: Completed Checklist History
            Section(header: Text("Past Checklists").font(.system(size: 10, weight: .bold)).foregroundColor(.secondary)) {
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
                        NavigationLink(destination: ChecklistSummaryView(checklist: checklist, isEditable: true)) {
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
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                selectedChecklistForExport = checklist
                            } label: {
                                Label("Export", systemImage: "qrcode")
                            }
                            .tint(.ebirdGreen)
                        }
                    }
                    .onDelete(perform: deleteChecklists)
                }
            }
        }
        .navigationTitle("BirdWatch")
        .listStyle(.carousel)
        .navigationDestination(item: $selectedChecklistForExport) { checklist in
            let csvString = EBirdCSVFormatter.format(checklist, registry: taxonRegistry)
            let baseURL = "https://rdabrunk.github.io/BirdWatch/decoder/"
            if let qrUrl = try? QRExportEncoder.encode(csv: csvString, baseURL: baseURL) {
                QRDisplayView(urlString: qrUrl)
            }
        }
    }
    
    private func deleteChecklists(at offsets: IndexSet) {
        WKInterfaceDevice.current().play(.directionDown)
        for index in offsets {
            let checklist = completedChecklists[index]
            modelContext.delete(checklist)
        }
        try? modelContext.save()
    }
    
    private func startNewSession() {
        WKInterfaceDevice.current().play(.click)
        session.startNewSession(trackLocation: trackLocation)
    }
}

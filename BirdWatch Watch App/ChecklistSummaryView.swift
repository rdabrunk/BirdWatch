//
//  ChecklistSummaryView.swift
//  BirdWatch Watch App
//
//  Created by Ryan Brunk on 5/21/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ChecklistSummaryView: View {
    @Bindable var checklist: Checklist
    var isModal: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header with Date & Time Range
                VStack(spacing: 2) {
                    Text(checklist.formattedDate)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.ebirdGreen)
                    
                    Text(checklist.formattedTimeRange)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
                
                if isModal {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("EFFORT DETAILS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                            
                        VStack(spacing: 8) {
                            Picker("Protocol", selection: $checklist.protocolTypeRaw) {
                                ForEach(ProtocolType.allCases) { type in
                                    Text(type.rawValue).tag(type.rawValue)
                                }
                            }
                            .frame(height: 40)
                            
                            Divider()
                            
                            HStack {
                                Text("Observers")
                                    .font(.subheadline)
                                Spacer()
                                HStack(spacing: 12) {
                                    Button {
                                        if checklist.observersCount > 1 {
                                            checklist.observersCount -= 1
                                        }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title3)
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(checklist.observersCount > 1 ? .ebirdGreen : .secondary.opacity(0.5))
                                    
                                    Text("\(checklist.observersCount)")
                                        .font(.headline)
                                        .frame(minWidth: 20, alignment: .center)
                                    
                                    Button {
                                        if checklist.observersCount < 99 {
                                            checklist.observersCount += 1
                                        }
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title3)
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(.ebirdGreen)
                                }
                            }
                            .padding(.vertical, 2)
                            
                            Divider()
                            
                            Toggle("Complete?", isOn: $checklist.isCompleteChecklist)
                                .font(.subheadline)
                                .tint(.ebirdGreen)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .glassCard()
                    }
                }
                
                // Stats Card Grid
                HStack(spacing: 6) {
                    // Species Count Card
                    VStack(spacing: 2) {
                        Text("\(checklist.totalSpeciesCount)")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.ebirdGreen)
                        Text("Species")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .glassCard()
                    
                    // Total Bird Count Card
                    VStack(spacing: 2) {
                        Text("\(checklist.totalBirdCount)")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.ebirdGreen)
                        Text("Total Birds")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .glassCard()
                    
                    // Duration Card
                    VStack(spacing: 2) {
                        Text(checklist.formattedDuration)
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.ebirdGreen)
                        Text("Duration")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .glassCard()
                }
                
                // Sightings Section
                if checklist.sightings.isEmpty {
                    Text("No bird sightings recorded.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 20)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SIGHTINGS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                        
                        ForEach(checklist.sightings.sorted(by: { $0.count > $1.count })) { sighting in
                            HStack {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(sighting.bird?.alphaCode ?? "???")
                                        .font(.system(.body, design: .rounded))
                                        .fontWeight(.bold)
                                        .foregroundColor(.ebirdGreen)
                                    Text(sighting.bird?.commonName ?? "Unknown Species")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Text("\(sighting.count)")
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.ebirdGreen.opacity(0.15))
                                    .cornerRadius(6)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .glassCard()
                        }
                    }
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                // eBird CSV Export Button using ShareLink
                let csvString = checklist.generateCSVString()
                let fileName = "BirdWatch_\(formattedFileDate(from: checklist.startTime)).csv"
                let csvExport = CSVExport(csvText: csvString, filename: fileName)
                
                ShareLink(item: csvExport, preview: SharePreview("eBird Checklist CSV", image: Image(systemName: "tablecells"))) {
                    Label("Export CSV", systemImage: "square.and.arrow.up")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .tint(.ebirdGreen)
                
                if isModal {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .navigationTitle(isModal ? "Session Ended" : "Summary")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formattedFileDate(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmm"
        return formatter.string(from: date)
    }
}

// MARK: - Transferable CSV Helper
struct CSVExport: Transferable {
    let csvText: String
    let filename: String
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText, exporting: { export in
            Data(export.csvText.utf8)
        })
        .suggestedFileName { export in
            export.filename
        }
    }
}

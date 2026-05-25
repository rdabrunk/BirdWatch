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
    @EnvironmentObject private var taxonRegistry: TaxonRegistry
    @Bindable var checklist: Checklist
    var isEditable: Bool = true
    
    @Environment(\.dismiss) private var dismiss
    @State private var isSightingsExpanded = false
    
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
                
                if isEditable {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("EFFORT DETAILS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                            
                        VStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Protocol")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 4) {
                                    ForEach(ProtocolType.allCases) { type in
                                        Button {
                                            WKInterfaceDevice.current().play(.click)
                                            checklist.protocolType = type
                                        } label: {
                                            Text(type.rawValue)
                                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                                .foregroundColor(checklist.protocolType == type ? .white : .secondary)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 8)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(checklist.protocolType == type ? Color.ebirdGreen : Color.white.opacity(0.08))
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Observers")
                                    .font(.system(.subheadline, design: .rounded))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .allowsTightening(true)
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
                            
                            if checklist.protocolType == .traveling {
                                Divider()
                                
                                HStack {
                                    Text("Distance")
                                        .font(.system(.subheadline, design: .rounded))
                                    Spacer()
                                    HStack(spacing: 12) {
                                        Button {
                                            let current = checklist.distanceMiles ?? 0.0
                                            checklist.distanceMiles = max(0.0, current - 0.1)
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.title3)
                                        }
                                        .buttonStyle(.plain)
                                        .foregroundColor((checklist.distanceMiles ?? 0.0) > 0.05 ? .ebirdGreen : .secondary.opacity(0.5))
                                        
                                        Text(String(format: "%.1f mi", checklist.distanceMiles ?? 0.0))
                                            .font(.headline)
                                            .lineLimit(1)
                                            .fixedSize(horizontal: true, vertical: false)
                                        
                                        Button {
                                            let current = checklist.distanceMiles ?? 0.0
                                            checklist.distanceMiles = current + 0.1
                                        } label: {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.title3)
                                        }
                                        .buttonStyle(.plain)
                                        .foregroundColor(.ebirdGreen)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                            
                            if let lat = checklist.latitude, let lon = checklist.longitude {
                                Divider()
                                
                                HStack {
                                    Text("Start Location")
                                        .font(.system(.subheadline, design: .rounded))
                                    Spacer()
                                    Text(String(format: "%.4f, %.4f", lat, lon))
                                        .font(.system(.footnote, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                            
                            Divider()
                            
                            Toggle("Complete?", isOn: $checklist.isCompleteChecklist)
                                .font(.subheadline)
                                .tint(.ebirdGreen)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .glassCard()
                    }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("EFFORT DETAILS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                            
                        VStack(spacing: 8) {
                            HStack {
                                Text("Protocol")
                                    .font(.system(.subheadline, design: .rounded))
                                Spacer()
                                Text(checklist.protocolType.rawValue)
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Observers")
                                    .font(.system(.subheadline, design: .rounded))
                                Spacer()
                                Text("\(checklist.observersCount)")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            
                            if checklist.protocolType == .traveling {
                                Divider()
                                
                                HStack {
                                    Text("Distance")
                                        .font(.system(.subheadline, design: .rounded))
                                    Spacer()
                                    Text(String(format: "%.2f mi", checklist.distanceMiles ?? 0.0))
                                        .font(.system(.subheadline, design: .rounded))
                                        .lineLimit(1)
                                        .fixedSize(horizontal: true, vertical: false)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if let lat = checklist.latitude, let lon = checklist.longitude {
                                Divider()
                                
                                HStack {
                                    Text("Start Location")
                                        .font(.system(.subheadline, design: .rounded))
                                    Spacer()
                                    Text(String(format: "%.4f, %.4f", lat, lon))
                                        .font(.system(.footnote, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Complete checklist?")
                                    .font(.system(.subheadline, design: .rounded))
                                Spacer()
                                Text(checklist.isCompleteChecklist ? "Yes" : "No")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .glassCard()
                    }
                }
                
                // Stats Card Grid
                HStack(spacing: 6) {
                    // Taxa Count Card
                    VStack(spacing: 2) {
                        Text("\(checklist.totalTaxaCount)")
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
                    
                    // Total Tally Count Card
                    VStack(spacing: 2) {
                        Text("\(checklist.totalTallyCount)")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.ebirdGreen)
                        Text("Total Count")
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
                    Text("No species recorded.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 20)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SIGHTINGS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                        
                        let sortedSightings = checklist.sightings.sorted(by: { $0.tally > $1.tally })
                        let threshold = 5
                        let showExpandCollapse = sortedSightings.count > threshold
                        let visibleSightings = (showExpandCollapse && !isSightingsExpanded)
                            ? Array(sortedSightings.prefix(threshold))
                            : sortedSightings
                        
                        ForEach(visibleSightings) { sighting in
                            let taxon = taxonRegistry.taxon(forAlphaCode: sighting.alphaCode)
                            HStack {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(taxon?.alphaCode ?? sighting.alphaCode)
                                        .font(.system(.body, design: .rounded))
                                        .fontWeight(.bold)
                                        .foregroundColor(.ebirdGreen)
                                    Text(taxon?.commonName ?? "Unknown Species")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Text("\(sighting.tally)")
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
                        
                        if showExpandCollapse {
                            Button {
                                withAnimation {
                                    isSightingsExpanded.toggle()
                                }
                            } label: {
                                Text(isSightingsExpanded ? "Show Less" : "Show \(sortedSightings.count - threshold) More...")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.ebirdGreen)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .glassCard()
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                        }
                    }
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                // eBird QR Export Navigation
                let exporter = ChecklistExporter(taxonLookup: taxonRegistry)
                if let qrUrl = try? exporter.exportAsQRURL(checklist) {
                    NavigationLink(destination: QRDisplayView(urlString: qrUrl.absoluteString)) {
                        Label("Export QR Code", systemImage: "qrcode")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.ebirdGreen)
                }
                
                if isEditable {
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
        .navigationTitle(isEditable ? "Checklist Ended" : "Summary")
        .navigationBarTitleDisplayMode(.inline)
    }
}

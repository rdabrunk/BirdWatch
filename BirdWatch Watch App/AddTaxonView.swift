//
//  AddTaxonView.swift
//  BirdWatch
//
//  Created by Ryan Brunk on 5/19/26.
//

import SwiftUI
import SwiftData

struct AddTaxonView: View {
    @EnvironmentObject private var taxonRegistry: TaxonRegistry
    @ObservedObject var session: ChecklistSession
    @Environment(\.dismiss) private var dismiss
    
    // The search text bound to the text field
    @State private var searchText = ""
    
    // Dynamic property to search our fast in-memory static store
    var searchResults: [Taxon] {
        taxonRegistry.search(query: searchText)
    }
    
    var body: some View {
        List {
            // 1. BULLETPROOF SEARCH BAR
            Section {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.ebirdGreenLight)
                    TextField("Code or Name", text: $searchText)
                        .textFieldStyle(.plain)
                        .background(Color.clear)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .glassCard(isActive: true)
            }
            .listRowBackground(Color.clear)
            
            // 2. SEARCH RESULTS
            Section {
                ForEach(searchResults) { taxon in
                    Button {
                        addSighting(for: taxon)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(taxon.alphaCode)
                                .font(.headline)
                                .foregroundColor(.ebirdGreen)
                            Text(taxon.commonName)
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
    }
    
    private func addSighting(for taxon: Taxon) {
        // Delegate state transaction to the deep coordinator module
        session.addSighting(for: taxon)
        WKInterfaceDevice.current().play(.success)
        dismiss()
    }
}

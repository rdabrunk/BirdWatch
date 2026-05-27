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
    
    /// The query string passed in from dictation (or empty if the user cancelled / typed manually).
    var initialQuery: String = ""
    
    // The search text bound to the text field
    @State private var searchText = ""
    @State private var hasAppliedInitialQuery = false
    @AppStorage("autoLogAlphaCodes") private var autoLogAlphaCodes = false
    
    // Dynamic property to search our fast in-memory static store.
    // Returns an empty array when there is no query, preventing the
    // full ~2k taxon list from rendering.
    var searchResults: [Taxon] {
        let term = searchText.trimmingCharacters(in: .whitespaces)
        guard !term.isEmpty else { return [] }
        return taxonRegistry.search(query: term)
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
                        .onSubmit(of: .text) {
                            handleSearchSubmit()
                        }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .glassCard(isActive: true)
                .listRowBackground(Color.clear)
            }
            
            // 2. SEARCH RESULTS / EMPTY STATE
            if searchResults.isEmpty && !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                Section {
                    VStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("No matching birds")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Try a different name or code.")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(Array(searchResults.enumerated()), id: \.element.id) { index, taxon in
                        let isTopResult = index == 0
                        Button {
                            addSighting(for: taxon)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(taxon.alphaCode)
                                        .font(.headline)
                                        .foregroundColor(.ebirdGreen)
                                    Text(taxon.commonName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if isTopResult {
                                    Image(systemName: "hand.tap.fill")
                                        .foregroundColor(.ebirdGreen)
                                }
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glassCard(isActive: isTopResult)
                        }
                        .buttonStyle(TactileButtonStyle())
                        .handGestureShortcut(.primaryAction, isEnabled: isTopResult)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    }
                }
            }
        }
        .navigationTitle("Search")
        .onAppear {
            if !hasAppliedInitialQuery {
                searchText = initialQuery
                hasAppliedInitialQuery = true
            }
        }
    }
    
    private func handleSearchSubmit() {
        guard autoLogAlphaCodes else { return }
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let taxon = taxonRegistry.taxon(forAlphaCode: term) {
            addSighting(for: taxon)
        }
    }
    
    private func addSighting(for taxon: Taxon) {
        // Delegate state transaction to the deep coordinator module
        session.addSighting(for: taxon)
        WKInterfaceDevice.current().play(.success)
        dismiss()
    }
}

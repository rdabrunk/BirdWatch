//
//  ContentView.swift
//  BirdWatch Watch App
//
//  Created by Ryan Brunk on 5/19/26.
//

import SwiftUI
import SwiftData

enum NavigationRoute: Hashable {
    case settings
    case checklistSummary(Checklist)
    case qrExport(Checklist)
    case addTaxon(String)
}

struct ContentView: View {
    // Access the database environment
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var taxonRegistry: TaxonRegistry
    
    // Automatically fetch all checklists, sorted by newest first
    @Query(sort: \Checklist.startTime, order: .reverse) private var checklists: [Checklist]
    
    // The core transaction coordinator
    @StateObject private var checklistSession: ChecklistSession
    
    // State to trigger the checklist summary modal sheet upon completion
    @State private var endedChecklistForSummary: Checklist? = nil
    
    // Centralized navigation path
    @State private var path: [NavigationRoute] = []
    
    init(modelContext: ModelContext) {
        _checklistSession = StateObject(wrappedValue: ChecklistSession(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if checklistSession.activeChecklist != nil {
                    ActiveChecklistView(session: checklistSession, path: $path)
                } else {
                    HomeDashboardView(checklists: checklists, session: checklistSession, path: $path)
                }
            }
            .onChange(of: checklistSession.activeChecklist) { oldList, newList in
                // Reset navigation path to clean state on Checklist transition
                path.removeAll()
                
                // Detect when a list goes from active to ended (has an endTime)
                // Discarded checklists will not have an endTime set.
                if let old = oldList, newList == nil, old.endTime != nil {
                    endedChecklistForSummary = old
                }
            }
            .sheet(item: $endedChecklistForSummary) { checklist in
                NavigationStack {
                    ChecklistSummaryView(checklist: checklist, isEditable: true)
                }
            }
            .navigationDestination(for: NavigationRoute.self) { route in
                switch route {
                case .settings:
                    SettingsView()
                case .checklistSummary(let checklist):
                    ChecklistSummaryView(checklist: checklist, isEditable: true)
                case .qrExport(let checklist):
                    QRDisplayView(checklist: checklist)
                case .addTaxon(let query):
                    AddTaxonView(session: checklistSession, initialQuery: query)
                }
            }
        }
    }
}

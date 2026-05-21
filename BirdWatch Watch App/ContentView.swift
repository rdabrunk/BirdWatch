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
    @EnvironmentObject private var taxonRegistry: TaxonRegistry
    
    // Automatically fetch all checklists, sorted by newest first
    @Query(sort: \Checklist.startTime, order: .reverse) private var checklists: [Checklist]
    
    // The core transaction coordinator
    @StateObject private var checklistSession: ChecklistSession
    
    // State to trigger the checklist summary modal sheet upon completion
    @State private var endedChecklistForSummary: Checklist? = nil
    
    init(modelContext: ModelContext) {
        _checklistSession = StateObject(wrappedValue: ChecklistSession(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if checklistSession.activeChecklist != nil {
                    ActiveChecklistView(session: checklistSession)
                } else {
                    HomeDashboardView(checklists: checklists, session: checklistSession)
                }
            }
            .onChange(of: checklistSession.activeChecklist) { oldList, newList in
                // Detect when a list goes from active to ended
                if oldList != nil && newList == nil {
                    endedChecklistForSummary = oldList
                }
            }
            .sheet(item: $endedChecklistForSummary) { checklist in
                NavigationStack {
                    ChecklistSummaryView(checklist: checklist, isModal: true)
                }
            }
        }
    }
}

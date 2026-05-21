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
    
    // Automatically fetch all checklists, sorted by newest first
    @Query(sort: \Checklist.startTime, order: .reverse) private var checklists: [Checklist]
    
    // State to trigger the checklist summary modal sheet upon completion
    @State private var endedChecklistForSummary: Checklist? = nil
    
    // Helper to find if there is an active checklist (no end time)
    var activeChecklist: Checklist? {
        checklists.first(where: { $0.endTime == nil })
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let active = activeChecklist {
                    ActiveChecklistView(
                        checklist: active,
                        onEnd: { completedList in
                            endedChecklistForSummary = completedList
                        }
                    )
                } else {
                    HomeDashboardView(checklists: checklists)
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

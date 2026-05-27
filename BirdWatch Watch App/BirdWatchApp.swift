//
//  BirdWatchApp.swift
//  BirdWatch Watch App
//
//  Created by Ryan Brunk on 5/19/26.
//

import SwiftUI
import SwiftData

@main
struct BirdWatchApp: App {
    
    // This creates the local SQLite database for our 2 models (Taxon is handled in memory now)
    let container: ModelContainer = {
        let schema = Schema([Checklist.self, Sighting.self])
        let isMock = ProcessInfo.processInfo.arguments.contains("--mock-data") || ProcessInfo.processInfo.arguments.contains("--empty-checklist")
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isMock)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("⚠️ Migration failed. Deleting store and recreating container: \(error)")
            let storeURL = modelConfiguration.url
            let fileManager = FileManager.default
            try? fileManager.removeItem(at: storeURL)
            try? fileManager.removeItem(at: storeURL.appendingPathExtension("wal"))
            try? fileManager.removeItem(at: storeURL.appendingPathExtension("shm"))
            
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer after store recovery: \(error)")
            }
        }
    }()
    
    // The static taxonomy memory store
    @StateObject private var taxonRegistry = TaxonRegistry()

    @MainActor
    init() {
        // Preload the CSV into memory immediately on launch
        let registry = TaxonRegistry()
        registry.load()
        
        let hasMockData = ProcessInfo.processInfo.arguments.contains("--mock-data")
        let hasEmptyChecklist = ProcessInfo.processInfo.arguments.contains("--empty-checklist")
        
        if hasMockData || hasEmptyChecklist {
            let context = container.mainContext
            
            // Clear any old checklists
            let fetchDescriptor = FetchDescriptor<Checklist>()
            if let lists = try? context.fetch(fetchDescriptor) {
                for list in lists {
                    context.delete(list)
                }
            }
            
            // Start a session
            let session = ChecklistSession(modelContext: context)
            session.startNewSession(trackLocation: true)
            
            if hasMockData {
                // Add a mock sighting
                let mockTaxon = Taxon(alphaCode: "BCCH", commonName: "Black-capped Chickadee", scientificName: "Poecile atricapillus", ebirdCode: "bkcchi")
                session.addSighting(for: mockTaxon)
            }
            
            try? context.save()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(modelContext: container.mainContext)
                .environmentObject(taxonRegistry)
                .onAppear {
                    taxonRegistry.load()
                }
        }
        .modelContainer(container)
    }
}

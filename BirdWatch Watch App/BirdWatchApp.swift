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
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

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

    var body: some Scene {
        WindowGroup {
            ContentView(modelContext: container.mainContext)
                .environmentObject(taxonRegistry)
                .onAppear {
                    // Preload the CSV into memory immediately on launch
                    taxonRegistry.load()
                }
        }
        .modelContainer(container)
    }
}

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
    
    // This creates the local SQLite database for our 3 models
    let container: ModelContainer = {
        let schema = Schema([Bird.self, Checklist.self, Sighting.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Fire our CSV loader the moment the UI appears
                .onAppear {
                    DatabaseHelper.preloadTaxonomyData(modelContext: container.mainContext)
                }
        }
        // Attach the database to our entire app
        .modelContainer(container)
    }
}

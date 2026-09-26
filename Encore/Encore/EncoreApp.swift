//
//  EncoreApp.swift
//  Encore
//
//  Created by Yufan on 26/9/2026.
//

import SwiftUI
import CoreData

@main
struct EncoreApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

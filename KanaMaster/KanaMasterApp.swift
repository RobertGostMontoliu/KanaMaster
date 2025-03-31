//
//  KanaMasterApp.swift
//  KanaMaster
//
//  Created by robert gost montoliu on 31/3/25.
//

import SwiftUI

@main
struct KanaMasterApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

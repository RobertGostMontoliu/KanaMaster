//
//  ContentView.swift
//  KanaMaster
//
//  Created by robert gost montoliu on 31/3/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            MenuView()
        }
        .appThemeScreen()
    }
}

#Preview {
    ContentView()
}

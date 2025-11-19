//
//  ContentView.swift
//  zörgm.ai
//
//  Created by Chitra Joshy on 17/11/25.
//

import SwiftUI

struct ContentView: View {
    @State private var isAuthenticated: Bool = false
    
    var body: some View {
        if isAuthenticated {
            ChatView()
        } else {
            LoginView(isAuthenticated: $isAuthenticated)
        }
    }
}

#Preview {
    ContentView()
}

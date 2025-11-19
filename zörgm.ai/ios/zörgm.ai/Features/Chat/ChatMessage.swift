//
//  ChatMessage.swift
//  zörgm.ai
//
//  Created by Chitra Joshy on 17/11/25.
//

import Foundation

struct ChatMessage: Identifiable, Equatable, Codable {
    let id: String
    let content: String
    let isUser: Bool
    let timestamp: Date
    let sources: [String]?
    
    init(id: String = UUID().uuidString, content: String, isUser: Bool, timestamp: Date = Date(), sources: [String]? = nil) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.sources = sources
    }
}


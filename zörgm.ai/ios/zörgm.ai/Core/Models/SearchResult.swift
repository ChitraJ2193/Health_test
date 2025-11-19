//
//  SearchResult.swift
//  zörgm.ai
//
//  Created by Chitra Joshy on 17/11/25.
//

import Foundation

struct SearchResult: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let url: String
    let snippet: String?
    let description: String?
    
    init(id: String = UUID().uuidString, title: String, url: String, snippet: String? = nil, description: String? = nil) {
        self.id = id
        self.title = title
        self.url = url
        self.snippet = snippet
        self.description = description
    }
}

struct NHSArticle: Identifiable, Codable {
    let id: String
    let title: String
    let url: String
    let content: String?
    let summary: String?
    let lastUpdated: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, title, url, content, summary
        case lastUpdated = "last_updated"
    }
}

struct SearchResponse: Codable {
    let results: [SearchResult]
    let totalResults: Int?
    let query: String?
    
    enum CodingKeys: String, CodingKey {
        case results
        case totalResults = "total_results"
        case query
    }
}


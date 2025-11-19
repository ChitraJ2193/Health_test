//
//  ChatViewModel.swift
//  zörgm.ai
//
//  Created by Chitra Joshy on 17/11/25.
//  Features/Chat/ChatViewModel.swift
//

import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let nhsService: NHSServiceProtocol
    private var currentTask: Task<Void, Never>?
    
    // Track conversation context
    private var conversationContext: ConversationContext?
    
    struct ConversationContext {
        let originalQuery: String
        let originalResponse: String
        let followUpAnswers: [String]
        let condition: String
    }
    
    init(nhsService: NHSServiceProtocol = NHSService()) {
        self.nhsService = nhsService
        // Don't add welcome message initially - show landing page instead
    }
    
    var hasStartedConversation: Bool {
        return messages.count > 0 && messages.contains { $0.isUser }
    }
    
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let userMessage = ChatMessage(
            content: inputText.trimmingCharacters(in: .whitespacesAndNewlines),
            isUser: true
        )
        
        messages.append(userMessage)
        let query = userMessage.content
        inputText = ""
        
        // Log user query to console
        print("📤 USER QUERY: \(query)")
        
        // Check if it's a casual greeting or conversation
        if isGreetingOrCasualMessage(query) {
            let greetingResponse = getGreetingResponse(for: query)
            let botMessage = ChatMessage(
                content: greetingResponse,
                isUser: false
            )
            messages.append(botMessage)
            print("📥 BOT RESPONSE: \(greetingResponse)")
            // Clear context for new conversation
            conversationContext = nil
            return
        }
        
        // Check if this is a follow-up answer to previous questions
        if let context = conversationContext, isFollowUpAnswer(query: query) {
            // This is an answer to follow-up questions
            handleFollowUpAnswer(query: query, context: context)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Cancel previous task
        currentTask?.cancel()
        
        currentTask = Task {
            do {
                // Build enhanced query with full conversation history
                let enhancedQuery = buildQueryWithHistory(currentQuery: query)
                print("🔍 ENHANCED QUERY (with history): \(enhancedQuery)")
                
                let response = try await nhsService.getChatResponse(query: enhancedQuery, context: nil)
                
                if Task.isCancelled { return }
                
                // Log response to console
                print("📥 BOT RESPONSE: \(response.content)")
                print("📎 SOURCES: \(response.sources)")
                
                // Extract condition from response for context
                let condition = extractCondition(from: query, response: response.content)
                
                // Store conversation context
                await MainActor.run {
                    conversationContext = ConversationContext(
                        originalQuery: query,
                        originalResponse: response.content,
                        followUpAnswers: [],
                        condition: condition
                    )
                }
                
                let botMessage = ChatMessage(
                    content: response.content,
                    isUser: false,
                    sources: response.sources
                )
                
                await MainActor.run {
                    messages.append(botMessage)
                    isLoading = false
                }
            } catch {
                if Task.isCancelled { return }
                
                let errorMsg = error.localizedDescription
                print("❌ ERROR: \(errorMsg)")
                
                let errorBotMessage = ChatMessage(
                    content: "I apologize, but I encountered an error while finding information. Please try rephrasing your question.",
                    isUser: false
                )
                
                await MainActor.run {
                    messages.append(errorBotMessage)
                    isLoading = false
                    errorMessage = errorMsg
                }
            }
        }
    }
    
    private func isFollowUpAnswer(query: String) -> Bool {
        // Check if we have context and the last bot message asked follow-up questions
        guard conversationContext != nil,
              let lastBotMessage = messages.last(where: { !$0.isUser }),
              (lastBotMessage.content.contains("could you share:") ||
               lastBotMessage.content.contains("To help me provide") ||
               lastBotMessage.content.contains("1.") && lastBotMessage.content.contains("2.")) else {
            return false
        }
        
        // Also check if the query looks like an answer (not a new question)
        let lowercased = query.lowercased()
        let isAnswer = lowercased.contains("month") || lowercased.contains("week") || 
                      lowercased.contains("day") || lowercased.contains("degree") ||
                      lowercased.contains("temperature") || lowercased.contains("severe") ||
                      lowercased.contains("mild") || lowercased.contains("moderate") ||
                      lowercased.contains("experience") || lowercased.contains("noticed")
        
        return isAnswer
    }
    
    private func handleFollowUpAnswer(query: String, context: ConversationContext) {
        isLoading = true
        errorMessage = nil
        
        currentTask?.cancel()
        
        currentTask = Task {
            do {
                // Build query with full conversation history
                let enhancedQuery = buildQueryWithHistory(currentQuery: query)
                print("🔍 FOLLOW-UP QUERY (with history): \(enhancedQuery)")
                
                let response = try await nhsService.getChatResponse(
                    query: enhancedQuery,
                    context: context
                )
                
                if Task.isCancelled { return }
                
                // Log response to console
                print("📥 BOT RESPONSE: \(response.content)")
                print("📎 SOURCES: \(response.sources)")
                
                // Update context with the new answer
                var updatedAnswers = context.followUpAnswers
                updatedAnswers.append(query)
                
                await MainActor.run {
                    conversationContext = ConversationContext(
                        originalQuery: context.originalQuery,
                        originalResponse: context.originalResponse,
                        followUpAnswers: updatedAnswers,
                        condition: context.condition
                    )
                }
                
                let botMessage = ChatMessage(
                    content: response.content,
                    isUser: false,
                    sources: response.sources
                )
                
                await MainActor.run {
                    messages.append(botMessage)
                    isLoading = false
                }
            } catch {
                if Task.isCancelled { return }
                
                print("❌ ERROR: \(error.localizedDescription)")
                
                let errorBotMessage = ChatMessage(
                    content: "I apologize, but I encountered an error. Please try rephrasing your answer.",
                    isUser: false
                )
                
                await MainActor.run {
                    messages.append(errorBotMessage)
                    isLoading = false
                }
            }
        }
    }
    
    private func buildQueryWithHistory(currentQuery: String) -> String {
        // Build query with full conversation history (excluding welcome message)
        let userMessages = messages.filter { $0.isUser && !isWelcomeMessage($0.content) }
        
        if userMessages.count > 1 {
            // Combine all previous user messages with current query
            let previousQueries = userMessages.dropLast().map { $0.content }
            let historyContext = previousQueries.joined(separator: ". ")
            return "\(historyContext). \(currentQuery)"
        }
        
        // If we have context from follow-up answers, include that too
        if let context = conversationContext, !context.followUpAnswers.isEmpty {
            let answers = context.followUpAnswers.joined(separator: " ")
            return "\(context.originalQuery) \(answers) \(currentQuery)"
        }
        
        return currentQuery
    }
    
    private func isWelcomeMessage(_ content: String) -> Bool {
        return content.contains("Hello! I'm Zörgm") || 
               content.contains("What would you like to know")
    }
    
    private func extractCondition(from query: String, response: String) -> String {
        let lowercased = query.lowercased()
        
        if lowercased.contains("fever") { return "fever" }
        if lowercased.contains("headache") { return "headache" }
        if lowercased.contains("cough") { return "cough" }
        if lowercased.contains("pain") { return "pain" }
        if lowercased.contains("diabetes") { return "diabetes" }
        if lowercased.contains("anxiety") { return "anxiety" }
        if lowercased.contains("depression") { return "depression" }
        
        // Try to extract from response
        if response.lowercased().contains("fever") { return "fever" }
        if response.lowercased().contains("headache") { return "headache" }
        
        return query
    }
    
    private func isGreetingOrCasualMessage(_ message: String) -> Bool {
        let lowercased = message.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        let greetings = [
            "hi", "hello", "hey", "hi there", "hello there", "hey there",
            "good morning", "good afternoon", "good evening", "gm", "gn",
            "thanks", "thank you", "thankyou", "thx", "ty",
            "bye", "goodbye", "see you", "cya",
            "how are you", "how are you doing", "how's it going",
            "what's up", "whats up", "sup", "wassup",
            "ok", "okay", "okay thanks", "ok thanks",
            "yes", "yeah", "yep", "no", "nope", "maybe"
        ]
        
        // Check if it's exactly a greeting
        if greetings.contains(lowercased) {
            return true
        }
        
        // Check if it's a very short message (likely casual)
        if lowercased.count <= 3 && !lowercased.contains("?") {
            return true
        }
        
        return false
    }
    
    private func getGreetingResponse(for message: String) -> String {
        let lowercased = message.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if lowercased.contains("hi") || lowercased.contains("hello") || lowercased.contains("hey") {
            return "Hello! How can I help you with health information today?"
        } else if lowercased.contains("thank") {
            return "You're welcome! Feel free to ask me anything about health conditions, symptoms, or medical information."
        } else if lowercased.contains("bye") || lowercased.contains("goodbye") {
            return "Goodbye! Take care and feel free to come back if you have any health questions."
        } else if lowercased.contains("how are you") {
            return "I'm doing well, thank you for asking! I'm here to help you with health information. What would you like to know?"
        } else if lowercased.contains("what's up") || lowercased.contains("whats up") || lowercased.contains("sup") {
            return "Not much! I'm here to help you with health questions. What can I help you with?"
        } else if lowercased == "ok" || lowercased == "okay" {
            return "Great! What health information are you looking for?"
        } else {
            return "Hi there! I'm here to help you with health information. What would you like to know?"
        }
    }
    
    func clearChat() {
        print("🔄 NEW CHAT STARTED - Clearing conversation history")
        currentTask?.cancel()
        messages.removeAll()
        inputText = ""
        isLoading = false
        errorMessage = nil
        conversationContext = nil
        // Don't add welcome message - show landing page instead
    }
    
    func startNewChat() {
        // Start a completely new chat without comparing with previous
        print("🆕 STARTING NEW CHAT - No previous context")
        clearChat()
    }
}


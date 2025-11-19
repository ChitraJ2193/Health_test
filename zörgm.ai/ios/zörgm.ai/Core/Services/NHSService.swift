//
//  NHSService.swift
//  zörgm.ai
//
//  Created by Chitra Joshy on 17/11/25.
//

import Foundation

protocol NHSServiceProtocol {
    func search(query: String) async throws -> [SearchResult]
    func fetchArticleContent(url: String) async throws -> String
    func getChatResponse(query: String, context: Any?) async throws -> ChatResponse
}

class NHSService: NHSServiceProtocol {
    private let networkManager: NetworkManagerProtocol
    private let baseURL = "https://www.nhs.uk"
    
    init(networkManager: NetworkManagerProtocol = NetworkManager.shared) {
        self.networkManager = networkManager
    }
    
    func search(query: String) async throws -> [SearchResult] {
        // Try direct condition URL first for common conditions
        if let directResult = tryDirectConditionURL(query: query) {
            return [directResult]
        }
        
        // Try enhanced search query
        let enhancedQuery = enhanceSearchQuery(query)
        let encodedQuery = enhancedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let searchURLString = "\(baseURL)/search/?q=\(encodedQuery)"
        
        guard let url = URL(string: searchURLString) else {
            throw NetworkError.invalidURL
        }
        
        let htmlContent = try await networkManager.fetchHTMLContent(url: url)
        var results = parseSearchResults(from: htmlContent, query: query)
        
        // If no results, try alternative parsing methods
        if results.isEmpty {
            results = parseSearchResultsAlternative(from: htmlContent, query: query)
        }
        
        return results
    }
    
    private func enhanceSearchQuery(_ query: String) -> String {
        let lowercased = query.lowercased()
        
        // Add "NHS" if not present for better results
        if !lowercased.contains("nhs") {
            return query + " NHS"
        }
        
        return query
    }
    
    private func tryDirectConditionURL(query: String) -> SearchResult? {
        // Map common queries to NHS condition URLs
        let conditionMap: [String: String] = [
            "fever": "/conditions/fever/",
            "headache": "/conditions/headaches/",
            "cough": "/conditions/cough/",
            "cold": "/conditions/common-cold/",
            "flu": "/conditions/flu/",
            "diabetes": "/conditions/type-2-diabetes/",
            "asthma": "/conditions/asthma/",
            "depression": "/conditions/clinical-depression/",
            "anxiety": "/conditions/generalised-anxiety-disorder/",
            "pain": "/conditions/pain/",
            "nausea": "/conditions/feeling-sick-nausea/",
            "diarrhea": "/conditions/diarrhoea-and-vomiting/",
            "vomiting": "/conditions/diarrhoea-and-vomiting/",
            "rash": "/conditions/rashes-babies-and-children/",
            "sore throat": "/conditions/sore-throat/",
            "earache": "/conditions/earache/",
            "back pain": "/conditions/back-pain/",
            "chest pain": "/conditions/chest-pain/",
            "dizziness": "/conditions/dizziness/",
            "fatigue": "/conditions/tiredness-and-fatigue/"
        ]
        
        let lowercased = query.lowercased()
        for (key, path) in conditionMap {
            if lowercased.contains(key) {
                return SearchResult(
                    title: key.capitalized,
                    url: "\(baseURL)\(path)",
                    snippet: "Information about \(key)"
                )
            }
        }
        
        return nil
    }
    
    func fetchArticleContent(url: String) async throws -> String {
        guard let articleURL = URL(string: url) else {
            throw NetworkError.invalidURL
        }
        
        let htmlContent = try await networkManager.fetchHTMLContent(url: articleURL)
        return extractArticleContent(from: htmlContent)
    }
    
    func getChatResponse(query: String, context: Any? = nil) async throws -> ChatResponse {
        // If we have context from follow-up answers, enhance the query
        var enhancedQuery = query
        if let context = context as? ChatViewModel.ConversationContext {
            // Build a more specific query using original query + follow-up answers
            let allAnswers = context.followUpAnswers.joined(separator: " ")
            enhancedQuery = "\(context.originalQuery) \(allAnswers) \(query)"
        }
        
        // Search for relevant NHS articles with enhanced query
        let searchResults = try await search(query: enhancedQuery)
        
        guard let firstResult = searchResults.first else {
            // Provide helpful suggestions based on the query
            let suggestions = getSuggestions(for: query)
            return ChatResponse(
                content: "I couldn't find specific information about '\(query)'. \(suggestions)\n\nTry asking about specific symptoms or conditions like:\n• Fever and temperature\n• Headaches\n• Cough and cold symptoms\n• Pain management\n• Mental health concerns",
                sources: []
            )
        }
        
        // Fetch comprehensive content from the most relevant result
        var articleContent: String = ""
        var contentFetched = false
        
        // Try to fetch from first result
        do {
            articleContent = try await fetchArticleContent(url: firstResult.url)
            if articleContent.count > 100 {
                contentFetched = true
            }
        } catch {
            // Continue to try other results
        }
        
        // If first result didn't work, try other results
        if !contentFetched {
            for result in searchResults.prefix(3).dropFirst() {
                do {
                    let content = try await fetchArticleContent(url: result.url)
                    if content.count > 100 {
                        articleContent = content
                        contentFetched = true
                        break
                    }
                } catch {
                    continue
                }
            }
        }
        
        // Get more detailed content - don't summarize too aggressively
        var finalContent: String
        
        // Check if we have substantial content
        if articleContent.count > 200 {
            // Use a larger limit to get more comprehensive information
            finalContent = summarizeContent(articleContent, maxLength: 2500)
            
            // If summarization cut too much, use more of the original
            if finalContent.count < 300 && articleContent.count > 500 {
                finalContent = summarizeContent(articleContent, maxLength: 3000)
            }
        } else if articleContent.count > 100 {
            // Use what we have if it's reasonable
            finalContent = articleContent
        } else {
            // Last resort: create informative content from title and snippet
            var fallbackContent = ""
            if let snippet = firstResult.snippet, snippet.count > 30 {
                fallbackContent = snippet
            } else {
                // Create a basic informative response
                fallbackContent = getBasicInfoForCondition(title: firstResult.title)
            }
            finalContent = fallbackContent
        }
        
        // Try to fetch additional context from other relevant results
        var additionalInfo = ""
        if searchResults.count > 1 {
            for result in searchResults.prefix(2).dropFirst() {
                do {
                    let additionalContent = try await fetchArticleContent(url: result.url)
                    let summary = summarizeContent(additionalContent, maxLength: 300)
                    if !summary.isEmpty && summary.count > 50 {
                        additionalInfo += "\n\n**Additional Information:**\n\(summary)"
                    }
                } catch {
                    // Continue if we can't fetch additional content
                    continue
                }
            }
        }
        
        // Check if this is a follow-up response (has context)
        let isFollowUpResponse = context != nil
        
        // Generate contextual follow-up questions only if not a follow-up response
        let followUpQuestions = isFollowUpResponse ? [] : generateFollowUpQuestions(for: query, content: finalContent, title: firstResult.title)
        
        // Format comprehensive response - different format for follow-up responses
        let response: String
        if isFollowUpResponse {
            // For follow-up responses, provide more specific information without questions
            response = formatFollowUpResponse(
                content: finalContent,
                additionalInfo: additionalInfo,
                title: firstResult.title,
                query: query
            )
        } else {
            // For initial responses, include follow-up questions
            response = formatChatResponse(
                content: finalContent,
                additionalInfo: additionalInfo,
                title: firstResult.title,
                snippet: firstResult.snippet,
                followUpQuestions: followUpQuestions
            )
        }
        
        // Store sources but don't make them clickable links that navigate away
        let sources = searchResults.prefix(3).map { $0.url }
        
        return ChatResponse(
            content: response,
            sources: Array(sources)
        )
    }
    
    private func generateFollowUpQuestions(for query: String, content: String, title: String) -> [String] {
        let lowercased = query.lowercased()
        var questions: [String] = []
        
        // Check for multiple symptoms mentioned
        let hasMultipleSymptoms = (lowercased.contains("fever") && lowercased.contains("headache")) ||
                                 (lowercased.contains("fever") && lowercased.contains("cough")) ||
                                 (lowercased.contains("headache") && lowercased.contains("nausea"))
        
        if hasMultipleSymptoms {
            questions = [
                "How long have you been experiencing these symptoms?",
                "Which symptom is most concerning to you?",
                "Have you noticed any patterns or triggers?"
            ]
        } else if lowercased.contains("fever") || lowercased.contains("temperature") {
            questions = [
                "How high is your temperature?",
                "How long have you had the fever?",
                "Are there any other symptoms you've noticed?"
            ]
        } else if lowercased.contains("headache") || lowercased.contains("head ache") {
            questions = [
                "How severe is the headache?",
                "How long have you been experiencing it?",
                "Are there any triggers or patterns you've noticed?"
            ]
        } else if lowercased.contains("cough") {
            questions = [
                "Is the cough dry or productive?",
                "How long have you had the cough?",
                "Do you have any other symptoms like fever or shortness of breath?"
            ]
        } else if lowercased.contains("pain") && !lowercased.contains("back pain") && !lowercased.contains("chest pain") {
            questions = [
                "Where exactly is the pain located?",
                "How would you describe the pain (sharp, dull, aching)?",
                "What makes it better or worse?"
            ]
        } else if lowercased.contains("i have") || lowercased.contains("i'm") || lowercased.contains("i am") {
            // Extract the main symptom/condition from the query
            if lowercased.contains("noticed") {
                questions = [
                    "How long have you been experiencing this?",
                    "How would you describe the severity?",
                    "Are there any other symptoms you've noticed?"
                ]
            } else {
                questions = [
                    "How long have you been experiencing this?",
                    "How severe would you rate it?",
                    "Are there any other symptoms you've noticed?"
                ]
            }
        } else if lowercased.contains("diabetes") {
            questions = [
                "Are you looking for information about type 1 or type 2 diabetes?",
                "Do you have concerns about symptoms, management, or prevention?",
                "Are you looking for dietary or lifestyle advice?"
            ]
        } else if lowercased.contains("anxiety") || lowercased.contains("depression") || lowercased.contains("mental health") {
            questions = [
                "How long have you been experiencing these feelings?",
                "Are there specific situations that trigger these feelings?",
                "Have you noticed any impact on your daily activities?"
            ]
        } else if lowercased.contains("back pain") {
            questions = [
                "Is the pain in your upper, middle, or lower back?",
                "Did it start suddenly or gradually?",
                "Are there any activities that make it worse?"
            ]
        } else if lowercased.contains("chest pain") {
            questions = [
                "Is the pain constant or does it come and go?",
                "Does it worsen with activity or breathing?",
                "Do you have any other symptoms like shortness of breath or nausea?"
            ]
        } else if lowercased.contains("rash") {
            questions = [
                "Where is the rash located?",
                "Is it itchy or painful?",
                "When did it first appear?"
            ]
        } else if lowercased.contains("nausea") || lowercased.contains("vomiting") {
            questions = [
                "How long have you been feeling nauseous?",
                "Have you been able to keep food or fluids down?",
                "Are there any other symptoms like fever or abdominal pain?"
            ]
        }
        
        // If no specific questions, generate generic ones based on content
        if questions.isEmpty {
            questions = [
                "How long have you been experiencing this?",
                "What prompted you to ask about this?",
                "Is there anything specific you'd like to know more about?"
            ]
        }
        
        return questions
    }
    
    private func getSuggestions(for query: String) -> String {
        let lowercased = query.lowercased()
        
        if lowercased.contains("i have") || lowercased.contains("i'm") || lowercased.contains("i am") {
            return "You might want to describe your symptoms more specifically."
        }
        
        return "Please try rephrasing your question with more specific keywords."
    }
    
    private func summarizeContent(_ content: String, maxLength: Int) -> String {
        // Better summarization that preserves structure
        var summary = ""
        let paragraphs = content.components(separatedBy: "\n\n")
        
        for paragraph in paragraphs {
            let trimmedParagraph = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedParagraph.isEmpty {
                continue
            }
            
            // If adding this paragraph would exceed limit, try to add partial
            if summary.count + trimmedParagraph.count + 2 > maxLength {
                // Try to add partial paragraph (first few sentences)
                let sentences = trimmedParagraph.components(separatedBy: ". ")
                var partialParagraph = ""
                
                for sentence in sentences {
                    if summary.count + partialParagraph.count + sentence.count + 3 > maxLength {
                        break
                    }
                    partialParagraph += sentence + ". "
                }
                
                if !partialParagraph.isEmpty {
                    summary += partialParagraph.trimmingCharacters(in: .whitespacesAndNewlines) + "\n\n"
                }
                break
            } else {
                summary += trimmedParagraph + "\n\n"
            }
        }
        
        return summary.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func formatChatResponse(content: String, additionalInfo: String = "", title: String, snippet: String?, followUpQuestions: [String] = []) -> String {
        var response = ""
        
        // Check if we have meaningful content
        let hasRealContent = content.count > 100 && 
                            !content.lowercased().contains("couldn't retrieve") && 
                            !content.lowercased().contains("looking into") &&
                            !content.lowercased().contains("let me get")
        
        // Start with a conversational introduction if it's a symptom query
        let lowercasedTitle = title.lowercased()
        let isSymptomQuery = lowercasedTitle.contains("fever") || lowercasedTitle.contains("pain") || 
                            lowercasedTitle.contains("headache") || lowercasedTitle.contains("cough") ||
                            lowercasedTitle.contains("rash") || lowercasedTitle.contains("nausea")
        
        if isSymptomQuery && hasRealContent {
            // Create a natural introduction
            let intro = getConversationalIntro(for: title)
            response += intro + "\n\n"
        }
        
        // Always try to show content - even if minimal
        if hasRealContent {
            // Extract and show key information
            let keyPoints = extractKeyPoints(from: content, maxLength: 1500)
            if !keyPoints.isEmpty && keyPoints.count > 80 {
                response += keyPoints
            } else {
                // Use the content directly
                let displayContent = content.count > 2000 ? summarizeContent(content, maxLength: 1500) : content
                response += displayContent
            }
        } else if content.count > 50 {
            // Even if it's not "real content", show what we have
            response += content
        } else {
            // Last resort: provide basic information
            response += getBasicInfoForCondition(title: title)
        }
        
        // Add follow-up questions if we have content or it's a symptom query
        if (hasRealContent || isSymptomQuery) && !followUpQuestions.isEmpty {
            response += "\n\nTo help me provide more specific guidance, could you share:\n"
            for (index, question) in followUpQuestions.enumerated() {
                response += "\(index + 1). \(question)\n"
            }
        }
        
        if !additionalInfo.isEmpty && hasRealContent {
            response += "\n\n" + additionalInfo
        }
        
        return response
    }
    
    private func formatFollowUpResponse(content: String, additionalInfo: String = "", title: String, query: String) -> String {
        var response = ""
        
        // Extract key information from the follow-up answer
        let lowercased = query.lowercased()
        var specificInfo = ""
        
        // Add context-specific information based on the answer
        if lowercased.contains("month") || lowercased.contains("week") || lowercased.contains("day") {
            if let duration = extractDuration(from: query) {
                specificInfo = "Since you've been experiencing this for \(duration), "
            }
        }
        
        if lowercased.contains("degree") || lowercased.contains("temperature") || lowercased.contains("f") || lowercased.contains("c") {
            if let temp = extractTemperature(from: query) {
                specificInfo += "With a temperature of \(temp), "
            }
        }
        
        if lowercased.contains("severe") || lowercased.contains("mild") || lowercased.contains("moderate") {
            if let severity = extractSeverity(from: query) {
                specificInfo += "Given the \(severity) severity, "
            }
        }
        
        // Add the specific context
        if !specificInfo.isEmpty {
            response += specificInfo
        }
        
        // Add main content
        let keyPoints = extractKeyPoints(from: content, maxLength: 1500)
        if !keyPoints.isEmpty && keyPoints.count > 100 {
            response += keyPoints
        } else {
            response += content
        }
        
        if !additionalInfo.isEmpty {
            response += "\n\n" + additionalInfo
        }
        
        return response
    }
    
    private func extractDuration(from query: String) -> String? {
        let lowercased = query.lowercased()
        if lowercased.contains("2 months") || lowercased.contains("two months") {
            return "2 months"
        } else if lowercased.contains("month") {
            if let range = lowercased.range(of: #"\d+\s*month"#, options: .regularExpression) {
                return String(query[range])
            }
            return "a month"
        } else if lowercased.contains("week") {
            if let range = lowercased.range(of: #"\d+\s*week"#, options: .regularExpression) {
                return String(query[range])
            }
            return "a week"
        } else if lowercased.contains("day") {
            if let range = lowercased.range(of: #"\d+\s*day"#, options: .regularExpression) {
                return String(query[range])
            }
            return "a few days"
        }
        return nil
    }
    
    private func extractTemperature(from query: String) -> String? {
        let lowercased = query.lowercased()
        // Look for temperature patterns
        if let range = lowercased.range(of: #"\d+\s*(degree|°|f|c)"#, options: .regularExpression) {
            let tempStr = String(query[range])
            return tempStr
        }
        if lowercased.contains("100") && lowercased.contains("degree") {
            return "100°F"
        }
        return nil
    }
    
    private func extractSeverity(from query: String) -> String? {
        let lowercased = query.lowercased()
        if lowercased.contains("severe") { return "severe" }
        if lowercased.contains("mild") { return "mild" }
        if lowercased.contains("moderate") { return "moderate" }
        return nil
    }
    
    private func getBasicInfoForCondition(title: String) -> String {
        let lowercased = title.lowercased()
        
        if lowercased.contains("fever") {
            return "A fever is a high body temperature, usually 38°C (100.4°F) or above. It's usually a sign that your body is fighting an infection. Common causes include viral infections like colds or flu, bacterial infections, and other conditions. Most fevers are not serious and can be managed at home with rest, staying hydrated, and taking paracetamol or ibuprofen if needed. However, you should seek medical attention if the fever is very high, lasts more than a few days, or is accompanied by severe symptoms."
        } else if lowercased.contains("headache") {
            return "Headaches are a common condition that can range from mild discomfort to severe pain. They can be caused by various factors including stress, dehydration, lack of sleep, eye strain, or underlying medical conditions. Most headaches can be managed with rest, staying hydrated, and over-the-counter pain relievers. If headaches are frequent, severe, or accompanied by other symptoms, it's important to consult a healthcare professional."
        } else if lowercased.contains("cough") {
            return "A cough is a reflex action to clear your airways of mucus and irritants. It can be caused by infections, allergies, asthma, or other conditions. Most coughs are temporary and resolve on their own. Staying hydrated, using cough drops, and getting rest can help. If a cough persists for more than a few weeks or is accompanied by other symptoms like fever or difficulty breathing, it's advisable to see a healthcare provider."
        } else if lowercased.contains("pain") {
            return "Pain can occur in various parts of the body and can have many causes. It's important to identify the location, type, and severity of pain to understand its cause. Mild pain can often be managed with rest and over-the-counter pain relievers, but persistent or severe pain should be evaluated by a healthcare professional."
        } else {
            return "Here's information about \(title). This condition can have various causes and symptoms. It's important to monitor your symptoms and consult with a healthcare professional if they persist or worsen."
        }
    }
    
    private func getConversationalIntro(for title: String) -> String {
        let lowercased = title.lowercased()
        
        if lowercased.contains("fever") {
            return "Dealing with a fever can be uncomfortable."
        } else if lowercased.contains("headache") {
            return "Headaches can be quite bothersome."
        } else if lowercased.contains("pain") {
            return "Experiencing pain can be distressing."
        } else if lowercased.contains("cough") {
            return "A persistent cough can be concerning."
        } else if lowercased.contains("rash") {
            return "Noticing a rash can be worrying."
        } else if lowercased.contains("nausea") || lowercased.contains("vomiting") {
            return "Feeling nauseous can be very uncomfortable."
        } else {
            return "I understand you're looking for information about this."
        }
    }
    
    private func extractKeyPoints(from content: String, maxLength: Int) -> String {
        // Extract the most important information (first few paragraphs or key sentences)
        let paragraphs = content.components(separatedBy: "\n\n")
        var keyPoints = ""
        var currentLength = 0
        
        for paragraph in paragraphs {
            let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed.count < 30 {
                continue
            }
            
            if currentLength + trimmed.count > maxLength {
                break
            }
            
            keyPoints += trimmed + "\n\n"
            currentLength += trimmed.count
        }
        
        return keyPoints.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - HTML Parsing
    
    private func parseSearchResults(from html: String, query: String) -> [SearchResult] {
        var results: [SearchResult] = []
        
        // Multiple patterns to try for different NHS.uk page structures
        let patterns = [
            // Pattern 1: NHS search results with data attributes
            #"<a[^>]*href="([^"]*)"[^>]*data-track-label="[^"]*"[^>]*>[\s\S]*?<h[23][^>]*>([^<]*)</h[23]>[\s\S]*?<p[^>]*>([^<]*)</p>"#,
            // Pattern 2: Standard search result links
            #"<a[^>]*href="([^"]*)"[^>]*class="[^"]*search-result[^"]*"[^>]*>[\s\S]*?<h3[^>]*>([^<]*)</h3>[\s\S]*?<p[^>]*>([^<]*)</p>"#,
            // Pattern 3: Article links in search results
            #"<a[^>]*href="([^"]*conditions/[^"]*)"[^>]*>[\s\S]*?<h[23][^>]*>([^<]*)</h[23]>[\s\S]*?<p[^>]*>([^<]*)</p>"#,
            // Pattern 4: Links with title attribute
            #"<a[^>]*href="([^"]*)"[^>]*title="([^"]*)"[^>]*>[\s\S]*?<p[^>]*>([^<]*)</p>"#,
            // Pattern 5: General article links
            #"<a[^>]*href="([^"]*)"[^>]*>[\s\S]*?<h[23][^>]*>([^<]*)</h[23]>[\s\S]*?<p[^>]*>([^<]*)</p>"#
        ]
        
        let nsString = html as NSString
        var processedURLs = Set<String>()
        
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { continue }
            let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                if match.numberOfRanges >= 4 {
                    let urlRange = match.range(at: 1)
                    let titleRange = match.range(at: 2)
                    let snippetRange = match.range(at: 3)
                    
                    let urlString = nsString.substring(with: urlRange)
                    let title = nsString.substring(with: titleRange)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                    let snippet = nsString.substring(with: snippetRange)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                    
                    // Skip if already processed or invalid
                    guard !urlString.isEmpty,
                          !title.isEmpty,
                          urlString.contains("nhs.uk") || urlString.hasPrefix("/"),
                          !processedURLs.contains(urlString) else {
                        continue
                    }
                    
                    let fullURL: String
                    if urlString.hasPrefix("http") {
                        fullURL = urlString
                    } else if urlString.hasPrefix("/") {
                        fullURL = "\(baseURL)\(urlString)"
                    } else {
                        fullURL = "\(baseURL)/\(urlString)"
                    }
                    
                    processedURLs.insert(urlString)
                    
                    let result = SearchResult(
                        title: title,
                        url: fullURL,
                        snippet: snippet.isEmpty ? nil : snippet
                    )
                    results.append(result)
                    
                    // Limit results to prevent too many
                    if results.count >= 20 {
                        return results
                    }
                }
            }
            
            // If we found results with this pattern, use them
            if !results.isEmpty {
                break
            }
        }
        
        return results
    }
    
    private func parseSearchResultsAlternative(from html: String, query: String) -> [SearchResult] {
        var results: [SearchResult] = []
        let nsString = html as NSString
        var processedURLs = Set<String>()
        
        // Try to find any links to /conditions/ pages
        let conditionPattern = #"<a[^>]*href="([^"]*conditions/[^"]*)"[^>]*>([^<]*)</a>"#
        
        if let regex = try? NSRegularExpression(pattern: conditionPattern, options: []) {
            let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in matches where match.numberOfRanges >= 3 {
                let urlRange = match.range(at: 1)
                let titleRange = match.range(at: 2)
                
                let urlString = nsString.substring(with: urlRange)
                let title = nsString.substring(with: titleRange)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                
                guard !urlString.isEmpty,
                      !title.isEmpty,
                      (urlString.contains("nhs.uk") || urlString.hasPrefix("/")),
                      !processedURLs.contains(urlString),
                      urlString.contains("conditions") else {
                    continue
                }
                
                let fullURL: String
                if urlString.hasPrefix("http") {
                    fullURL = urlString
                } else if urlString.hasPrefix("/") {
                    fullURL = "\(baseURL)\(urlString)"
                } else {
                    fullURL = "\(baseURL)/\(urlString)"
                }
                
                processedURLs.insert(urlString)
                
                let result = SearchResult(
                    title: title,
                    url: fullURL,
                    snippet: "Information about \(title)"
                )
                results.append(result)
                
                if results.count >= 10 {
                    break
                }
            }
        }
        
        return results
    }
    
    private func extractArticleContent(from html: String) -> String {
        // Extract main content from NHS article with better parsing
        
        // Try multiple patterns to find the main content
        let contentPatterns = [
            // NHS article body
            #"<div[^>]*class="[^"]*article-body[^"]*"[^>]*>([\s\S]*?)</div>"#,
            #"<div[^>]*class="[^"]*content[^"]*"[^>]*>([\s\S]*?)</div>"#,
            #"<main[^>]*>([\s\S]*?)</main>"#,
            #"<article[^>]*>([\s\S]*?)</article>"#,
            // NHS specific patterns
            #"<div[^>]*id="[^"]*content[^"]*"[^>]*>([\s\S]*?)</div>"#,
            #"<section[^>]*class="[^"]*article-content[^"]*"[^>]*>([\s\S]*?)</section>"#
        ]
        
        for pattern in contentPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]),
               let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: html.utf16.count)),
               match.numberOfRanges > 1 {
                let contentRange = match.range(at: 1)
                if let range = Range(contentRange, in: html) {
                    let content = String(html[range])
                    let cleaned = stripHTMLTags(from: content)
                    if cleaned.count > 100 { // Only return if we got substantial content
                        return cleaned
                    }
                }
            }
        }
        
        // Fallback: extract paragraphs and headings
        return extractParagraphs(from: html)
    }
    
    private func extractParagraphs(from html: String) -> String {
        // Extract paragraphs and headings for better content
        var content = ""
        let nsString = html as NSString
        
        // Extract headings (h1-h6) with nested content
        let headingPattern = #"<h[1-6][^>]*>([\s\S]*?)</h[1-6]>"#
        if let regex = try? NSRegularExpression(pattern: headingPattern, options: [.dotMatchesLineSeparators]) {
            let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
            for match in matches where match.numberOfRanges > 1 {
                let range = match.range(at: 1)
                let headingHTML = nsString.substring(with: range)
                let heading = stripHTMLTags(from: headingHTML).trimmingCharacters(in: .whitespacesAndNewlines)
                if !heading.isEmpty && heading.count < 200 && !heading.lowercased().contains("skip to") {
                    content += heading + "\n\n"
                }
            }
        }
        
        // Extract paragraphs with nested tags - get more content
        let paragraphPattern = #"<p[^>]*>([\s\S]*?)</p>"#
        if let regex = try? NSRegularExpression(pattern: paragraphPattern, options: [.dotMatchesLineSeparators]) {
            let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
            var paragraphCount = 0
            var totalLength = 0
            
            for match in matches where match.numberOfRanges > 1 {
                let range = match.range(at: 1)
                let paragraphHTML = nsString.substring(with: range)
                let paragraph = stripHTMLTags(from: paragraphHTML).trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Filter out navigation, cookies, and other non-content text
                let lowercased = paragraph.lowercased()
                if !paragraph.isEmpty 
                    && paragraph.count > 15  // Reduced minimum to get more content
                    && paragraph.count < 2000
                    && !lowercased.contains("cookie")
                    && !lowercased.contains("accept all")
                    && !lowercased.contains("reject all")
                    && !lowercased.contains("skip to")
                    && !lowercased.contains("menu")
                    && !lowercased.contains("close")
                    && !lowercased.contains("privacy policy")
                    && !lowercased.contains("terms of use")
                    && !lowercased.contains("we use cookies")
                    && !lowercased.contains("javascript") {
                    content += paragraph + "\n\n"
                    paragraphCount += 1
                    totalLength += paragraph.count
                    // Get at least 20 paragraphs or until we have 2000+ characters
                    if paragraphCount >= 20 || totalLength >= 2000 {
                        break
                    }
                }
            }
        }
        
        // Extract list items
        let listItemPattern = #"<li[^>]*>([\s\S]*?)</li>"#
        if let regex = try? NSRegularExpression(pattern: listItemPattern, options: [.dotMatchesLineSeparators]) {
            let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
            for match in matches where match.numberOfRanges > 1 {
                let range = match.range(at: 1)
                let itemHTML = nsString.substring(with: range)
                let item = stripHTMLTags(from: itemHTML).trimmingCharacters(in: .whitespacesAndNewlines)
                if !item.isEmpty && item.count > 20 && item.count < 500 {
                    content += "• \(item)\n\n"
                }
            }
        }
        
        if content.isEmpty {
            // Final fallback: strip all HTML tags from main content area
            return stripHTMLTags(from: html)
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func stripHTMLTags(from html: String) -> String {
        // Simple HTML tag removal with better handling
        var text = html
        // Remove script and style tags and their content
        text = text.replacingOccurrences(of: #"<script[^>]*>[\s\S]*?</script>"#, with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: #"<style[^>]*>[\s\S]*?</style>"#, with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: #"<nav[^>]*>[\s\S]*?</nav>"#, with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: #"<header[^>]*>[\s\S]*?</header>"#, with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: #"<footer[^>]*>[\s\S]*?</footer>"#, with: "", options: .regularExpression)
        // Remove HTML tags
        text = text.replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression)
        // Decode HTML entities
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&#39;", with: "'")
        text = text.replacingOccurrences(of: "&apos;", with: "'")
        // Clean up whitespace
        text = text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}


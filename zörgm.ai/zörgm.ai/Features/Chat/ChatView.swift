//
//  ChatView.swift
//  zörgm.ai
//
//  Created by Chitra Joshy on 17/11/25.
//  Features/Chat/ChatView.swift
//

import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // White background
                    Color.white
                        .ignoresSafeArea()
                    
                    // First blurred circular gradient (LHS): #F7BAFFCC
                    // width: 676, height: 676, top: 670px, left: -396px
                    Circle()
                        .fill(Color(red: 247/255, green: 186/255, blue: 255/255, opacity: 1.0))
                        .frame(width: 676, height: 676)
                        .position(
                            x: -396 + 676/2,  // left: -396px, center = left + width/2
                            y: 670 + 676/2    // top: 670px, center = top + height/2
                        )
                        .blur(radius: 180)
                        .ignoresSafeArea()
                    
                    // Second blurred circular gradient (RHS): #FFBACE80
                    // width: 676, height: 676, top: 572px, left: 63px
                    Circle()
                        .fill(Color(red: 255/255, green: 186/255, blue: 206/255, opacity: 1.0))
                        .frame(width: 676, height: 676)
                        .position(
                            x: 63 + 676/2,    // left: 63px, center = left + width/2
                            y: 572 + 676/2    // top: 572px, center = top + height/2
                        )
                        .blur(radius: 180)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                    if !viewModel.hasStartedConversation {
                        // Landing Page View
                        landingPageView
                    } else {
                        // Chat Messages View
                        chatMessagesView
                    }
                    
                    // Input Area (always visible)
                    inputArea
                    }
                }
            }
            .background(Color.white)
            .toolbar {
                if viewModel.hasStartedConversation {
                    ToolbarItem(placement: .navigationBarLeading) {
                        HStack(spacing: 6) {
                            Image("ZorgmLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                            Text("Zorgm")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            viewModel.startNewChat()
                        }) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                        }
                    }
                } else {
                    // Hide navigation bar on landing page
                    ToolbarItem(placement: .principal) {
                        EmptyView()
                    }
                }
            }
            .toolbar(viewModel.hasStartedConversation ? .visible : .hidden, for: .navigationBar)
        }
    }
    
    // MARK: - Landing Page View
    
    private var landingPageView: some View {
        GeometryReader { geometry in
            ZStack {
                ScrollView {
                    VStack(spacing: 40) {
                        Spacer()
                            .frame(height: 60)
                        
                        // Logo and Name
                        HStack(spacing: 12) {
                            // Logo (Zörgm logo from assets)
                            Image("ZorgmLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                            
                            Text("Zörgm")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 40)
                        
                        // Search Bar
                        HStack(spacing: 12) {
                            TextField("Ask me anything...", text: $viewModel.inputText)
                                .textFieldStyle(.plain)
                                .font(.system(size: 16))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color(.systemBackground))
                                .cornerRadius(30)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                .focused($isInputFocused)
                                .onSubmit {
                                    if !viewModel.inputText.isEmpty {
                                        viewModel.sendMessage()
                                    }
                                }
                                .submitLabel(.search)
                            
                            if !viewModel.inputText.isEmpty {
                                Button(action: {
                                    viewModel.sendMessage()
                                    isInputFocused = false
                                }) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Descriptive Text
                        VStack(spacing: 8) {
                            Text("Education only. General health guidance with citations. Not medical advice.")
                                .font(.custom("Space Grotesk", size: 12))
                                .fontWeight(.regular)
                                .lineSpacing(6) // line-height: 18px - font-size: 12px = 6px spacing
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                        }
                        .padding(.horizontal, 40)
                        
                        // Spacer to push content up
                        Spacer()
                            .frame(height: max(0, geometry.size.height - 450))
                    }
                }
                
                // Footer fixed at bottom
                VStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Text("Laennec AI Ltd, Registered in England and Wales.")
                            .font(.custom("Space Grotesk", size: 12))
                            .fontWeight(.regular)
                            .lineSpacing(6) // line-height: 18px - font-size: 12px = 6px spacing
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Link("Privacy Policy", destination: URL(string: "https://zorgm.ai/privacy")!)
                            .font(.custom("Space Grotesk", size: 12))
                            .fontWeight(.regular)
                            .lineSpacing(6)
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    // MARK: - Chat Messages View
    
    private var chatMessagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    
                    if viewModel.isLoading {
                        HStack {
                            ProgressView()
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            Text("Thinking...")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading)
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _ in
                if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color.white)
    }
    
    // MARK: - Input Area
    
    private var inputArea: some View {
        Group {
            if viewModel.hasStartedConversation {
                VStack(spacing: 0) {
                    // Disclaimer box
                    HStack {
                        Spacer()
                        Text("Education only. General health guidance with citations. Not medical advice.")
                            .font(.custom("Space Grotesk", size: 12))
                            .fontWeight(.regular)
                            .foregroundColor(.purple)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.purple.opacity(0.1))
                            )
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    
                    Divider()
                    
                    HStack(spacing: 12) {
                        TextField("Ask me anything...", text: $viewModel.inputText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(20)
                            .focused($isInputFocused)
                            .lineLimit(1...4)
                            .onSubmit {
                                if !viewModel.inputText.isEmpty {
                                    viewModel.sendMessage()
                                }
                            }
                            .submitLabel(.send)
                        
                        Button(action: {
                            // Microphone action (placeholder)
                            isInputFocused = false
                        }) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.white)
                }
            }
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                if !message.isUser {
                    HStack(spacing: 6) {
                        Image("ZorgmLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 14, height: 14)
                        Text("Zörgm")
                            .font(.system(size: 11))
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(message.content.replacingOccurrences(of: "**", with: ""))
                    .font(.system(size: 14))
                    .foregroundColor(message.isUser ? .primary : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.isUser
                            ? Color(.systemGray5)  // Light grey for user messages
                            : Color(.systemBackground)
                    )
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                
            }
            
            if !message.isUser {
                Spacer(minLength: 50)
            }
        }
    }
}

// MARK: - Zörgm Logo View

struct ZorgmLogoView: View {
    let size: CGFloat
    
    init(size: CGFloat = 50) {
        self.size = size
    }
    
    var body: some View {
        // Symmetrical knot pattern - single continuous line forming intertwined loops
        Path { path in
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius: CGFloat = size * 0.4
            
            // Create symmetrical figure-8 knot pattern
            // Start from top-left
            path.move(to: CGPoint(x: center.x - radius * 0.5, y: center.y - radius))
            
            // Top loop - curve right and down
            path.addCurve(
                to: CGPoint(x: center.x + radius * 0.5, y: center.y - radius * 0.3),
                control1: CGPoint(x: center.x - radius * 0.2, y: center.y - radius * 0.7),
                control2: CGPoint(x: center.x + radius * 0.2, y: center.y - radius * 0.5)
            )
            
            // Cross to bottom-left
            path.addCurve(
                to: CGPoint(x: center.x - radius * 0.5, y: center.y + radius * 0.3),
                control1: CGPoint(x: center.x + radius * 0.3, y: center.y),
                control2: CGPoint(x: center.x - radius * 0.3, y: center.y)
            )
            
            // Bottom loop - curve right and up
            path.addCurve(
                to: CGPoint(x: center.x + radius * 0.5, y: center.y + radius),
                control1: CGPoint(x: center.x - radius * 0.2, y: center.y + radius * 0.5),
                control2: CGPoint(x: center.x + radius * 0.2, y: center.y + radius * 0.7)
            )
            
            // Cross back to top-left (completing the knot)
            path.addCurve(
                to: CGPoint(x: center.x - radius * 0.5, y: center.y - radius),
                control1: CGPoint(x: center.x + radius * 0.3, y: center.y),
                control2: CGPoint(x: center.x - radius * 0.3, y: center.y)
            )
        }
        .stroke(Color.orange, style: StrokeStyle(lineWidth: size * 0.12, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
    }
}

// MARK: - Wave Mask View

struct WaveMaskView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base rectangle
                Rectangle()
                    .fill(Color.white)
                
                // Wave fade mask at top
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let fadeHeight = height * 0.25  // Top 25% for wave fade
                    let amplitude: CGFloat = 15  // Wave amplitude
                    let frequency: CGFloat = 4  // Number of waves
                    
                    // Start from top-left
                    path.move(to: CGPoint(x: 0, y: 0))
                    
                    // Create smooth wave along top edge
                    let points = 200
                    for i in 0...points {
                        let x = CGFloat(i) / CGFloat(points) * width
                        let normalizedX = x / width
                        // Sine wave that fades out
                        let waveOffset = sin(normalizedX * .pi * frequency) * amplitude * (1 - normalizedX * 0.2)
                        // Gradually increase Y to create fade
                        let baseY = fadeHeight * normalizedX * normalizedX
                        let y = baseY + waveOffset * (1 - normalizedX)
                        
                        if i == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    
                    // Complete to bottom-right
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color.clear, location: 0.0),
                            .init(color: Color.clear, location: 0.1),
                            .init(color: Color.white.opacity(0.2), location: 0.2),
                            .init(color: Color.white.opacity(0.5), location: 0.35),
                            .init(color: Color.white.opacity(0.8), location: 0.5),
                            .init(color: Color.white, location: 0.65),
                            .init(color: Color.white, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }
}

#Preview {
    ChatView()
}


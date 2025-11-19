//
//  LoginView.swift
//  zörgm.ai
//
//  Created by Chitra Joshy on 18/11/25.
//  Features/Auth/LoginView.swift
//

import SwiftUI

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showSignUp: Bool = false
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool
    
    init(isAuthenticated: Binding<Bool> = .constant(false)) {
        _isAuthenticated = isAuthenticated
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // White background
                    Color.white
                        .ignoresSafeArea()
                    
                    // First blurred circular gradient (LHS): #F7BAFFCC
                    Circle()
                        .fill(Color(red: 247/255, green: 186/255, blue: 255/255, opacity: 1.0))
                        .frame(width: 676, height: 676)
                        .position(
                            x: -396 + 676/2,
                            y: 670 + 676/2
                        )
                        .blur(radius: 180)
                        .ignoresSafeArea()
                    
                    // Second blurred circular gradient (RHS): #FFBACE80
                    Circle()
                        .fill(Color(red: 255/255, green: 186/255, blue: 206/255, opacity: 1.0))
                        .frame(width: 676, height: 676)
                        .position(
                            x: 63 + 676/2,
                            y: 572 + 676/2
                        )
                        .blur(radius: 180)
                        .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 40) {
                            Spacer()
                                .frame(height: 60)
                            
                            // Logo and Name
                            HStack(spacing: 12) {
                                Image("ZorgmLogo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                                
                                Text("Zörgm")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            .padding(.top, 40)
                            
                            // Login Form
                            VStack(spacing: 20) {
                                // Email Field
                                TextField("Email", text: $email)
                                    .textFieldStyle(.plain)
                                    .font(.custom("Inter", size: 14))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(30)
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    .focused($isEmailFocused)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                
                                // Password Field
                                SecureField("Password", text: $password)
                                    .textFieldStyle(.plain)
                                    .font(.custom("Inter", size: 14))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(30)
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    .focused($isPasswordFocused)
                                
                                // Login Button
                                Button(action: {
                                    // Handle login - for now, just authenticate
                                    isAuthenticated = true
                                }) {
                                    Text("Login")
                                        .font(.custom("Inter", size: 16))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color.accentColor)
                                        .cornerRadius(30)
                                }
                                .padding(.top, 10)
                                
                                // Sign Up Link
                                HStack {
                                    Text("Don't have an account?")
                                        .font(.custom("Inter", size: 14))
                                        .foregroundColor(.secondary)
                                    
                                    Button(action: {
                                        showSignUp = true
                                    }) {
                                        Text("Sign Up")
                                            .font(.custom("Inter", size: 14))
                                            .fontWeight(.semibold)
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .padding(.top, 10)
                            }
                            .padding(.horizontal, 20)
                            
                            Spacer()
                                .frame(height: max(0, geometry.size.height - 500))
                            
                            // Footer
                            VStack(spacing: 8) {
                                Text("Laennec AI Ltd, Registered in England and Wales.")
                                    .font(.custom("Space Grotesk", size: 12))
                                    .fontWeight(.regular)
                                    .lineSpacing(6)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                Link("Privacy Policy", destination: URL(string: "https://zorgm.ai/privacy")!)
                                    .font(.custom("Space Grotesk", size: 12))
                                    .fontWeight(.regular)
                                    .lineSpacing(6)
                                    .foregroundColor(.blue)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.bottom, 180)
                        }
                    }
                }
            }
            .background(Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSignUp) {
                SignUpView(isAuthenticated: $isAuthenticated)
            }
        }
    }
}

#Preview {
    LoginView()
}


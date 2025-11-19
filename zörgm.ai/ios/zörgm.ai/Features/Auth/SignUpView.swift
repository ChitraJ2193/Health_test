//
//  SignUpView.swift
//  zörgm.ai
//
//  Created by Chitra Joshy on 18/11/25.
//  Features/Auth/SignUpView.swift
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isAuthenticated: Bool
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @FocusState private var focusedField: Field?
    
    init(isAuthenticated: Binding<Bool> = .constant(false)) {
        _isAuthenticated = isAuthenticated
    }
    
    enum Field {
        case name, email, password, confirmPassword
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
                            
                            // Sign Up Form
                            VStack(spacing: 20) {
                                // Name Field
                                TextField("Full Name", text: $name)
                                    .textFieldStyle(.plain)
                                    .font(.custom("Inter", size: 14))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(30)
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    .focused($focusedField, equals: .name)
                                
                                // Email Field
                                TextField("Email", text: $email)
                                    .textFieldStyle(.plain)
                                    .font(.custom("Inter", size: 14))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(30)
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    .focused($focusedField, equals: .email)
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
                                    .focused($focusedField, equals: .password)
                                
                                // Confirm Password Field
                                SecureField("Confirm Password", text: $confirmPassword)
                                    .textFieldStyle(.plain)
                                    .font(.custom("Inter", size: 14))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(30)
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    .focused($focusedField, equals: .confirmPassword)
                                
                                // Sign Up Button
                                Button(action: {
                                    // Handle sign up - for now, just authenticate
                                    isAuthenticated = true
                                    dismiss()
                                }) {
                                    Text("Sign Up")
                                        .font(.custom("Inter", size: 16))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color.accentColor)
                                        .cornerRadius(30)
                                }
                                .padding(.top, 10)
                            }
                            .padding(.horizontal, 20)
                            
                            Spacer()
                                .frame(height: max(0, geometry.size.height - 600))
                            
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

#Preview {
    SignUpView()
}


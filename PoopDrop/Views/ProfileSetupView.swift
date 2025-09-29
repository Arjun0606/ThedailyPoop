import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var username = ""
    @State private var dateOfBirth = Date()
    @State private var selectedGender: Gender = .male
    @State private var customGenderText: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingDatePicker = false
    @State private var showingError = false
    @State private var usernameAvailable = true
    @State private var checkingUsername = false
    @State private var showingPhotoEditor = false
    @State private var selectedImage: UIImage? = nil
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [Color.black, Color.brown.opacity(0.4)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 16) {
                        Text("💩")
                            .font(.system(size: 80))
                        
                        Text("Complete Your Profile")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Just a few more details to get you started!")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Profile photo
                    VStack(spacing: 12) {
                        ZStack {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
                                    .onTapGesture { showingPhotoEditor = true }
                            } else {
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 120, height: 120)
                                    .overlay(Text("Tap to add\nphoto").font(.caption).foregroundColor(.white.opacity(0.7)))
                                    .onTapGesture { showingPhotoEditor = true }
                            }
                        }
                    }
                    
                    // Form fields
                    VStack(spacing: 24) {
                        // Username field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack {
                                Text("@")
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.body)
                                
                                TextField("username", text: $username)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .foregroundColor(.white)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .onChange(of: username) { _ in
                                        checkUsernameAvailability()
                                    }
                                
                                if checkingUsername {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else if !username.isEmpty {
                                    Image(systemName: usernameAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(usernameAvailable ? .green : .red)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(usernameAvailable ? Color.clear : Color.red, lineWidth: 1)
                            )
                            
                            if !usernameAvailable && !username.isEmpty {
                                Text("Username not available")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Date of Birth
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date of Birth")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Button(action: {
                                showingDatePicker.toggle()
                            }) {
                                HStack {
                                    Text(dateOfBirth.formatted(date: .abbreviated, time: .omitted))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "calendar")
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        
                        // Gender selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gender")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 12) {
                                ForEach(Gender.allCases, id: \.self) { gender in
                                    Button(action: {
                                        selectedGender = gender
                                    }) {
                                        Text(gender.rawValue)
                                            .font(.body)
                                            .foregroundColor(selectedGender == gender ? .black : .white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 12)
                                            .background(selectedGender == gender ? Color.white : Color.white.opacity(0.1))
                                            .cornerRadius(20)
                                    }
                                }
                            }
                            if selectedGender == .custom {
                                TextField("Enter your gender", text: $customGenderText)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    // Continue button
                    VStack(spacing: 16) {
                        Button(action: completeProfile) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.black)
                                } else {
                                    Text("Start Dropping! 💩")
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canContinue ? Color.white : Color.white.opacity(0.3))
                            .cornerRadius(12)
                        }
                        .disabled(!canContinue || isLoading)
                        
                        // Removed skip – profile is mandatory
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showingPhotoEditor) {
            ProfilePictureEditor(selectedImage: $selectedImage, isPresented: $showingPhotoEditor) { _ in }
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerSheet(selectedDate: $dateOfBirth, isPresented: $showingDatePicker)
        }
        .alert("Profile Setup Error", isPresented: $showingError) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .onChange(of: errorMessage) { error in
            showingError = error != nil
        }
    }
    
    private var canContinue: Bool {
        !username.isEmpty && usernameAvailable && !checkingUsername
    }
    
    private func checkUsernameAvailability() {
        guard !username.isEmpty else {
            usernameAvailable = true
            return
        }
        
        // Basic validation first
        let isValidFormat = username.count >= 3 && 
                           username.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" } &&
                           !username.hasPrefix("_") && 
                           !username.hasSuffix("_")
        
        guard isValidFormat else {
            usernameAvailable = false
            return
        }
        
        checkingUsername = true
        
        // Check with CloudKit
        Task {
            do {
                let available = try await CloudKitManager.shared.isUsernameAvailable(username)
                await MainActor.run {
                    usernameAvailable = available
                    checkingUsername = false
                }
            } catch {
                await MainActor.run {
                    usernameAvailable = false
                    checkingUsername = false
                    print("Username availability check failed: \(error)")
                }
            }
        }
    }
    
    private func completeProfile() {
        guard canContinue else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Update current user with profile information
        guard var currentUser = authManager.currentUser else {
            errorMessage = "No user found"
            isLoading = false
            return
        }
        
        currentUser.username = username
        currentUser.dateOfBirth = dateOfBirth
        currentUser.gender = selectedGender
        if let img = selectedImage, let data = img.pngData() {
            let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("avatar_\(UUID().uuidString).png")
            try? data.write(to: tmp)
            currentUser.avatarURL = tmp
        }
        
        Task {
            do {
                try await CloudKitManager.shared.saveUser(currentUser)
                await MainActor.run {
                    authManager.currentUser = currentUser
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save profile: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Date of Birth",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Date of Birth")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    ProfileSetupView {
        print("Profile setup completed")
    }
    .environmentObject(AuthenticationManager())
}

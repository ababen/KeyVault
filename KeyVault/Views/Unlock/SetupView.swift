import SwiftUI

/// First-launch view where the user creates their master password.
struct SetupView: View {
    @EnvironmentObject private var appState: AppState
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var error: String?
    @State private var showPassword = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("Welcome to KeyVault")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Create a master password to encrypt your vault.\nThis password will be stored securely in your Mac's Keychain\nfor Touch ID unlock.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                HStack {
                    if showPassword {
                        TextField("Master Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("Master Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                    }
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)
                }

                if showPassword {
                    TextField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                } else {
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .frame(maxWidth: 320)

            if let error {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            passwordStrengthIndicator

            Button("Create Vault") {
                createVault()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(password.isEmpty || confirmPassword.isEmpty)
            .keyboardShortcut(.return)

            Spacer()
        }
        .padding(40)
        .frame(minWidth: 480, minHeight: 440)
    }

    @ViewBuilder
    private var passwordStrengthIndicator: some View {
        if !password.isEmpty {
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(level < passwordStrength ? strengthColor : Color.gray.opacity(0.3))
                        .frame(height: 4)
                }
                Text(strengthLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 320)
        }
    }

    private var passwordStrength: Int {
        var strength = 0
        if password.count >= 8 { strength += 1 }
        if password.count >= 12 { strength += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { strength += 1 }
        if password.rangeOfCharacter(from: .punctuationCharacters) != nil ||
           password.rangeOfCharacter(from: .symbols) != nil { strength += 1 }
        return strength
    }

    private var strengthColor: Color {
        switch passwordStrength {
        case 0...1: return .red
        case 2: return .orange
        case 3: return .yellow
        default: return .green
        }
    }

    private var strengthLabel: String {
        switch passwordStrength {
        case 0...1: return "Weak"
        case 2: return "Fair"
        case 3: return "Good"
        default: return "Strong"
        }
    }

    private func createVault() {
        do {
            try appState.setup(password: password, confirmPassword: confirmPassword)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

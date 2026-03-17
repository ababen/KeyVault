import SwiftUI

/// Unlock screen with Touch ID and manual password fallback.
struct UnlockView: View {
    @EnvironmentObject private var appState: AppState
    @State private var password = ""
    @State private var error: String?
    @State private var showPasswordField = false
    @State private var attemptedBiometric = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            Text("KeyVault is Locked")
                .font(.title)
                .fontWeight(.semibold)

            if !showPasswordField {
                Button {
                    unlockWithBiometric()
                } label: {
                    Label("Unlock with Touch ID", systemImage: "touchid")
                        .frame(minWidth: 200)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Use Master Password") {
                    withAnimation { showPasswordField = true }
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }

            if showPasswordField {
                VStack(spacing: 12) {
                    SecureField("Master Password", text: $password)
                        .frame(maxWidth: 280)
                        .onSubmit { unlockWithPassword() }

                    Button("Unlock") {
                        unlockWithPassword()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(password.isEmpty)
                    .keyboardShortcut(.return)

                    Button("Back to Touch ID") {
                        withAnimation {
                            showPasswordField = false
                            password = ""
                            error = nil
                        }
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                }
            }

            if let error {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            Spacer()
        }
        .padding(40)
        .frame(minWidth: 480, idealWidth: 480, minHeight: 400, idealHeight: 400)
        .onAppear {
            if !attemptedBiometric {
                attemptedBiometric = true
                unlockWithBiometric()
            }
        }
    }

    private func unlockWithBiometric() {
        appState.unlockWithBiometric()
        if !appState.isUnlocked {
            withAnimation { showPasswordField = true }
            error = appState.error
        }
    }

    private func unlockWithPassword() {
        do {
            try appState.unlockWithPassword(password)
        } catch {
            self.error = error.localizedDescription
            password = ""
        }
    }
}


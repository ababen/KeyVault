#!/bin/bash
# KeyVault Project Setup
# This script generates the Xcode project using xcodegen.
# If xcodegen is not installed, it provides instructions.

set -e

cd "$(dirname "$0")"

if command -v xcodegen &> /dev/null; then
    echo "Generating Xcode project..."
    xcodegen generate
    echo "Done! Open KeyVault.xcodeproj in Xcode."
    open KeyVault.xcodeproj
else
    echo "xcodegen is not installed."
    echo ""
    echo "Option 1: Install xcodegen and run this script again:"
    echo "  brew install xcodegen"
    echo "  ./setup.sh"
    echo ""
    echo "Option 2: Create the project manually in Xcode:"
    echo "  1. Open Xcode → File → New → Project"
    echo "  2. Choose macOS → App"
    echo "  3. Set Product Name: KeyVault"
    echo "  4. Interface: SwiftUI, Language: Swift"
    echo "  5. Check 'Use SwiftData'"
    echo "  6. Save to this directory's PARENT (~/Documents/GitHub/)"
    echo "  7. Delete the auto-generated files (ContentView.swift, Item.swift, KeyVaultApp.swift)"
    echo "  8. In Xcode, right-click the KeyVault group → Add Files → select all .swift files from KeyVault/"
    echo "  9. Add the entitlements file and Info.plist to the project"
    echo "  10. Build & Run (⌘R)"
fi

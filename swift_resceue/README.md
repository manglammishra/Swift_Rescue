<img width="256" height="256" alt="icon_128x128@2x" src="https://github.com/user-attachments/assets/90133f83-b4f6-41c6-aab9-25d0859d2a47" />

# SwiftRescue

A decentralized peer-to-peer emergency communication app with dual transport architecture: local Bluetooth mesh networks for offline communication and internet-based Nostr protocol for global reach. No accounts, no phone numbers, no central servers. Built to keep people connected during emergencies.



📲 App Store: SwiftRescue

📲 Play Store: SwiftRescue

### Getting a copy you can trust

Install from a trusted app store, or build from source you have verified. A compiled build from anywhere else cannot be verified — see [Verifying SwiftRescue](docs/VERIFYING-A-BUILD.md) for how to check source against the per-release hash manifest, and for what to do if that is the only build you can get.

This matters more than it usually would: this repository has been the target of takedown demands, and when a repository or releases page disappears, mirrors appear that nobody can check.

## License

This project is released into the public domain. See the [LICENSE](LICENSE) file for details.

## Features

- **Dual Transport Architecture**: Bluetooth mesh for offline + Nostr protocol for internet-based messaging
- **Location-Based Channels**: Geographic chat rooms using geohash coordinates over global Nostr relays
- **Intelligent Message Routing**: Automatically chooses the best transport (Bluetooth → Nostr fallback)
- **Decentralized Mesh Network**: Automatic peer discovery and multi-hop message relay over Bluetooth LE
- **Privacy First**: No accounts, no phone numbers, no central servers. Note that the mesh uses a persistent per-device identifier derived from your identity key — see the [whitepaper](WHITEPAPER.md) on identity and metadata for what a nearby radio can observe
- **Private Message End-to-End Encryption**: [Noise Protocol](https://noiseprotocol.org) for mesh, SwiftRescue private envelopes for Nostr fallback
- **IRC-Style Commands**: Familiar `/slap`, `/msg`, `/who` style interface
- **Universal App**: Native support for iOS and macOS
- **Emergency Wipe**: Triple-tap to instantly clear all data
- **Performance Optimizations**: LZ4 message compression, adaptive battery modes, and optimized networking

## Technical Architecture

SwiftRescue uses a **hybrid messaging architecture** with two complementary transport layers.

### Bluetooth Mesh Network (Offline)

- **Local Communication**: Direct peer-to-peer communication within Bluetooth range
- **Multi-hop Relay**: Messages route through nearby devices (maximum 7 hops)
- **No Internet Required**: Works completely offline in disaster scenarios
- **Noise Protocol Encryption**: End-to-end encryption with forward secrecy for live sessions. Store-and-forward mail is sealed without it — see the whitepaper
- **Binary Protocol**: Compact packet format optimized for Bluetooth Low Energy constraints
- **Automatic Discovery**: Peer discovery and connection management
- **Adaptive Power**: Battery-optimized duty cycling

### Nostr Protocol (Internet)

- **Global Reach**: Connect with users worldwide via internet relays
- **Location Channels**: Geographic chat rooms using geohash coordinates
- **440+ Relay Network**: Distributed across the globe for reliability
- **SwiftRescue Private Envelopes**: App-specific encrypted private messages over Nostr relays
- **Ephemeral Keys**: Fresh cryptographic identity per geohash area

SwiftRescue's private-envelope format is proprietary and is **not** NIP-17, NIP-44, or NIP-59 compatible. It uses Nostr as a relay transport but only interoperates with SwiftRescue clients: private payloads travel inside kind-1059 events whose `v2:`-prefixed content is a SwiftRescue-specific XChaCha20-Poly1305 construction, not NIP-44 encryption.

### Channel Types

#### `mesh #bluetooth`

- **Transport**: Bluetooth Low Energy mesh network
- **Scope**: Local devices within multi-hop range
- **Internet**: Not required
- **Use Case**: Offline communication, emergencies, disasters, and remote areas

#### Location Channels (`block #dr5rsj7`, `neighborhood #dr5rs`, `country #dr`)

- **Transport**: Nostr protocol over the internet
- **Scope**: Geographic areas defined by geohash precision
  - `block` (7 characters): City-block level
  - `neighborhood` (6 characters): District/neighborhood
  - `city` (5 characters): City level
  - `province` (4 characters): State/province
  - `region` (2 characters): Country/large region
- **Internet**: Required (connects to Nostr relays)
- **Use Case**: Location-based community chat, local emergencies, and regional discussions

### Direct Message Routing

Private messages use **intelligent transport selection**.

1. **Bluetooth First** (preferred when available)
   - Direct connection with an established Noise session
   - Fast, local communication

2. **Nostr Fallback** (when Bluetooth is unavailable)
   - Uses the recipient's Nostr public key
   - SwiftRescue-specific private-envelope encryption
   - Routes through the global relay network

3. **Smart Queuing** (when neither is available)
   - Messages are queued until a transport becomes available
   - Automatic delivery when a connection is established

For detailed protocol documentation, see the [Technical Whitepaper](WHITEPAPER.md).

## Setup

### Option 1: Using Xcode

```bash
open SwiftRescue.xcodeproj
```

For a signed device build, create your ignored local configuration and replace the example team ID with your Apple Developer Team ID:

```bash
cp Configs/Local.xcconfig.example Configs/Local.xcconfig
```

`Local.xcconfig.example` derives unique app and App Group identifiers from that team ID. The entitlement files already reference `$(APP_GROUP_ID)`, so tracked project or entitlement files do not need to be edited.

Useful command-line checks from the repository root:

```bash
# macOS Debug build without signing
xcodebuild -project SwiftRescue.xcodeproj -scheme "SwiftRescue (macOS)" \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build

# Full SwiftPM test suite
swift test

# iOS simulator tests
xcodebuild -project SwiftRescue.xcodeproj -scheme "SwiftRescue (iOS)" \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

If `iPhone 17` is unavailable, choose an installed simulator from:

```bash
xcodebuild -showdestinations -project SwiftRescue.xcodeproj -scheme "SwiftRescue (iOS)"
```

### Option 2: Using `just`

```bash
brew install just
just check
just run
```

`just build` and `just run` use the current `SwiftRescue (macOS)` scheme and keep Xcode output in the ignored `.DerivedData/` directory. They never patch source, project, configuration, or entitlement files.

`just clean` removes only `.DerivedData/` and `.build/`. It does not invoke Git or restore tracked files, so uncommitted work is preserved. `just test` runs the SwiftPM suite and `just test-ios` runs the iPhone 17 simulator suite.

## Localization

- App localizations live in `SwiftRescue/Localizable.xcstrings`.
- Share extension strings are separate in `SwiftRescueShareExtension/Localization/Localizable.xcstrings`.
- Prefer keys that describe intent, such as `app_info.features.offline.title`, and reuse existing ones where possible.
- Run `xcodebuild -project SwiftRescue.xcodeproj -scheme "SwiftRescue (macOS)" -configuration Debug CODE_SIGNING_ALLOWED=NO build` to compile-check any localization updates.

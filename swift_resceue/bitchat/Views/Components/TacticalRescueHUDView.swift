//
// TacticalRescueHUDView.swift
// SwiftRescue
//
// Tactical Emergency HUD & Mesh Telemetry Monitor for SwiftRescue
//

import SwiftUI

enum TacticalViewMode: String, CaseIterable, Identifiable {
    case split = "SPLIT"
    case tacticalHUD = "TACTICAL MAP"
    case meshChat = "MESH CHAT"

    var id: String { rawValue }
}

struct TacticalRescueHUDView: View {
    let peerCount: Int
    @Binding var viewMode: TacticalViewMode
    @Binding var activeRoute: String
    var onBroadcastSOS: () -> Void
    var onReportHazard: () -> Void
    var onBroadcastMedicalPoint: () -> Void
    var onBroadcastRouteVerified: () -> Void

    @State private var isExpanded: Bool = false
    @State private var showBroadcastBanner: String? = nil
    @State private var beaconPulsing: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Main Tactical Header Bar
            HStack(spacing: 8) {
                // Status Pill 1: Mesh Status
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color(red: 0.2, green: 0.85, blue: 0.4))
                        .frame(width: 6, height: 6)
                        .scaleEffect(beaconPulsing ? 1.25 : 0.85)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: beaconPulsing)

                    Text("LEO MESH: ACTIVE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color(white: 0.12))
                .cornerRadius(4)

                // Status Pill 2: Node Count
                HStack(spacing: 4) {
                    Text("NODES:")
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundColor(Color(white: 0.6))
                    Text("\(max(peerCount, 1)) ACTIVE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.3, green: 0.85, blue: 0.45))
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color(white: 0.12))
                .cornerRadius(4)

                // Mode Selector (SPLIT | TACTICAL MAP | MESH CHAT)
                HStack(spacing: 2) {
                    ForEach(TacticalViewMode.allCases) { mode in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewMode = mode
                            }
                        }) {
                            Text(mode.rawValue)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(viewMode == mode ? .black : Color(white: 0.75))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(viewMode == mode ? Color.white : Color.clear)
                                .cornerRadius(3)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(2)
                .background(Color(white: 0.14))
                .cornerRadius(5)

                // Route Quick Links (for the Web frontend)
                if viewMode != .meshChat {
                    HStack(spacing: 4) {
                        routeButton(title: "VICTIM", route: "/victim")
                        routeButton(title: "RESCUER", route: "/rescuer")
                        routeButton(title: "SIMULATION", route: "/simulation")
                        routeButton(title: "LEDGER", route: "/sync-status")
                    }
                }

                Spacer()

                // Expand/Collapse HUD Toggle
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isExpanded ? "chevron.up.circle.fill" : "gauge.with.dots.needle.bottom.50percent")
                            .font(.system(size: 11))
                        Text(isExpanded ? "CLOSE HUD" : "TELEMETRY")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(isExpanded ? .white : Color(white: 0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(white: 0.15))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)

                // Critical Rescue Emergency Broadcast Button
                Button(action: {
                    triggerEmergencyBroadcast()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                        Text("CRITICAL RESCUE")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white)
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.red.opacity(0.8), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(red: 0.08, green: 0.08, blue: 0.09))
            .onAppear {
                beaconPulsing = true
            }

            // Notification Flash Banner when an action is triggered
            if let banner = showBroadcastBanner {
                HStack(spacing: 8) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundColor(Color(red: 0.3, green: 0.85, blue: 0.45))
                    Text(banner)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(red: 0.15, green: 0.1, blue: 0.1))
                .transition(.opacity)
            }

            // Expanded Tactical Telemetry Monitor & Active Incident Stack
            if isExpanded {
                VStack(alignment: .leading, spacing: 14) {
                    // Title and Description
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Image(systemName: "waveform.path.ecg")
                                    .foregroundColor(.white)
                                Text("TACTICAL TELEMETRY MONITOR")
                                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            Text("Real-time signal pathing directly simulated from off-grid mountain terrain nodes.")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(Color(white: 0.6))
                        }
                        Spacer()

                        Text("LIVE FEED // 915MHz MESH")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.3, green: 0.85, blue: 0.45))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(red: 0.1, green: 0.25, blue: 0.12))
                            .cornerRadius(3)
                    }

                    // 4 Telemetry Metrics Cards
                    HStack(spacing: 10) {
                        telemetryCard(title: "LEO LATENCY", value: "142", unit: "ms", detail: "Iridium #4")
                        telemetryCard(title: "PACKET RSSI", value: "-68", unit: "dBm", detail: "SNR: +11.4dB")
                        telemetryCard(title: "TILE CACHE", value: "100", unit: "%", detail: "2.4 GB vector")
                        telemetryCard(title: "BATTERY", value: "38", unit: "hrs", detail: "Low-Power HUD")
                    }

                    // Mesh Relay Density Bar
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("Mesh Relay Node Density")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(white: 0.8))
                            Spacer()
                            Text("88% Connected")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(white: 0.18))
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white)
                                    .frame(width: geo.size.width * 0.88, height: 6)
                            }
                        }
                        .frame(height: 6)

                        HStack {
                            Text("8 hops")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(Color(white: 0.5))
                            Spacer()
                            Text("Max 7 hops limit")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(Color(white: 0.5))
                        }
                    }

                    Divider().background(Color(white: 0.2))

                    // Active Incident Stack Header
                    HStack {
                        Text("ACTIVE INCIDENT STACK")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white)
                        Spacer()
                        Text("3 ACTIVE")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white)
                            .cornerRadius(3)
                    }

                    // Incidents
                    VStack(spacing: 8) {
                        incidentRow(
                            icon: "drop.triangle.fill",
                            title: "Flooded Road",
                            desc: "Flooded Road reported at this location. Re-route via Sector 4.",
                            timeAgo: "895m ago",
                            severity: "LOW",
                            severityColor: Color.white,
                            actionLabel: "Broadcast Hazard",
                            action: {
                                triggerHazardReport()
                            }
                        )

                        incidentRow(
                            icon: "checkmark.shield.fill",
                            title: "Route Verified",
                            desc: "Market Corridor & Van Ness safe for emergency convoys.",
                            timeAgo: "191m ago",
                            severity: "SAFE",
                            severityColor: Color(red: 0.3, green: 0.85, blue: 0.45),
                            actionLabel: "Broadcast Clear",
                            action: {
                                triggerRouteVerified()
                            }
                        )

                        incidentRow(
                            icon: "cross.fill",
                            title: "Medical Point",
                            desc: "Field Medical Triage established. First aid, burn units ready.",
                            timeAgo: "101m ago",
                            severity: "MED",
                            severityColor: Color.orange,
                            actionLabel: "Broadcast Triage",
                            action: {
                                triggerMedicalPoint()
                            }
                        )
                    }

                    // Tactical Action Buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            triggerEmergencyBroadcast()
                        }) {
                            HStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("SOS BROADCAST")
                                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                    Text("DIRECT LEO // ECDSA-P256")
                                        .font(.system(size: 8, design: .monospaced))
                                }
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            triggerHazardReport()
                        }) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("REPORT HAZARD")
                                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                    Text("AUTO RE-ROUTE MESH")
                                        .font(.system(size: 8, design: .monospaced))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(white: 0.18))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(white: 0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
                .background(Color(red: 0.07, green: 0.07, blue: 0.08))
                .border(Color(white: 0.16), width: 1)
            }

            Divider().background(Color(white: 0.16))
        }
    }

    private func routeButton(title: String, route: String) -> some View {
        Button(action: {
            activeRoute = route
        }) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(activeRoute == route ? Color(red: 0.3, green: 0.85, blue: 0.45) : Color(white: 0.6))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(activeRoute == route ? Color.white.opacity(0.12) : Color.clear)
                .cornerRadius(3)
        }
        .buttonStyle(.plain)
    }

    private func telemetryCard(title: String, value: String, unit: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(Color(white: 0.5))

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text(unit)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color(white: 0.6))
            }

            Text(detail)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(Color(white: 0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(white: 0.12))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color(white: 0.2), lineWidth: 1)
        )
    }

    private func incidentRow(
        icon: String,
        title: String,
        desc: String,
        timeAgo: String,
        severity: String,
        severityColor: Color,
        actionLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(severityColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                    Text(timeAgo)
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(Color(white: 0.5))
                    Text(severity)
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(severityColor)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color(white: 0.15))
                        .cornerRadius(2)
                }

                Text(desc)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(Color(white: 0.6))
                    .lineLimit(1)
            }

            Button(action: action) {
                Text(actionLabel)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(white: 0.2))
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(Color(white: 0.11))
        .cornerRadius(4)
    }

    private func triggerEmergencyBroadcast() {
        onBroadcastSOS()
        withAnimation {
            showBroadcastBanner = "🚨 CRITICAL RESCUE SOS RELAYED TO MESH"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation {
                showBroadcastBanner = nil
            }
        }
    }

    private func triggerHazardReport() {
        onReportHazard()
        withAnimation {
            showBroadcastBanner = "⚠️ HAZARD REPORT BROADCAST TO MESH PEERS"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation {
                showBroadcastBanner = nil
            }
        }
    }

    private func triggerMedicalPoint() {
        onBroadcastMedicalPoint()
        withAnimation {
            showBroadcastBanner = "🏥 MEDICAL POINT BROADCAST TO MESH PEERS"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation {
                showBroadcastBanner = nil
            }
        }
    }

    private func triggerRouteVerified() {
        onBroadcastRouteVerified()
        withAnimation {
            showBroadcastBanner = "✅ ROUTE VERIFIED BROADCAST TO MESH PEERS"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation {
                showBroadcastBanner = nil
            }
        }
    }
}

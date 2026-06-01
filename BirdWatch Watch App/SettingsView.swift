//
//  SettingsView.swift
//  BirdWatch Watch App
//
//  Created by Ryan Brunk on 5/27/26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("autoLogAlphaCodes") private var autoLogAlphaCodes = false

    var body: some View {
        List {
            Section(header: Text("Preferences").font(.system(size: 10, weight: .bold)).foregroundColor(.secondary)) {
                Toggle(isOn: $autoLogAlphaCodes) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.ebirdGreen)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-Log Codes")
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .allowsTightening(true)
                            Text("Log bird instantly on exact alpha match")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .allowsTightening(true)
                        }
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .ebirdGreen))
                .padding(.vertical, 8)
                .padding(.horizontal, 2)
                .listRowBackground(Color.clear)
                .glassCard(isActive: autoLogAlphaCodes)
            }
            
            Section(header: Text("Profiles").font(.system(size: 10, weight: .bold)).foregroundColor(.secondary)) {
                NavigationLink(destination: LocationProfilesView()) {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.ebirdGreen)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Location Profiles")
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.semibold)
                            Text("Manage saved birding locations")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .listRowBackground(Color.clear)
                .glassCard(isActive: false)
            }
        }
        .listStyle(.carousel)
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
}

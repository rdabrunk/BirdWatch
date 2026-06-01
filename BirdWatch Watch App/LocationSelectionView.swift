//
//  LocationSelectionView.swift
//  BirdWatch Watch App
//

import SwiftUI
import SwiftData

struct LocationSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("locationProfiles") private var locationProfiles: [String] = []
    @Bindable var checklist: Checklist
    
    var body: some View {
        List {
            Section(header: Text("Default").font(.system(size: 10, weight: .bold)).foregroundColor(.secondary)) {
                Button {
                    WKInterfaceDevice.current().play(.click)
                    checklist.customLocationName = nil
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.ebirdGreen)
                        Text("GPS Coordinates")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                        Spacer()
                        if checklist.customLocationName == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.ebirdGreen)
                                .font(.footnote)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .listRowBackground(Color.clear)
                .glassCard(isActive: checklist.customLocationName == nil)
            }
            
            if !locationProfiles.isEmpty {
                Section(header: Text("Saved Profiles").font(.system(size: 10, weight: .bold)).foregroundColor(.secondary)) {
                    ForEach(locationProfiles, id: \.self) { profile in
                        Button {
                            WKInterfaceDevice.current().play(.click)
                            checklist.customLocationName = profile
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(.ebirdGreen)
                                Text(profile)
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.medium)
                                Spacer()
                                if checklist.customLocationName == profile {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.ebirdGreen)
                                        .font(.footnote)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                        .listRowBackground(Color.clear)
                        .glassCard(isActive: checklist.customLocationName == profile)
                    }
                }
            }
            
            Section(header: Text("Custom").font(.system(size: 10, weight: .bold)).foregroundColor(.secondary)) {
                TextFieldLink(prompt: Text("Location Name")) {
                    HStack {
                        Image(systemName: "pencil")
                            .foregroundColor(.ebirdGreen)
                        Text("Custom Name...")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                        Spacer()
                        if let customName = checklist.customLocationName, !locationProfiles.contains(customName) {
                            Text(customName)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                } onSubmit: { input in
                    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    WKInterfaceDevice.current().play(.click)
                    checklist.customLocationName = trimmed
                    dismiss()
                }
                .listRowBackground(Color.clear)
                .glassCard(isActive: checklist.customLocationName != nil && !locationProfiles.contains(checklist.customLocationName ?? ""))
            }
        }
        .listStyle(.carousel)
        .navigationTitle("Select Location")
    }
}

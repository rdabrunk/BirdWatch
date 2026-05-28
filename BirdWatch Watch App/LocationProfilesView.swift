//
//  LocationProfilesView.swift
//  BirdWatch Watch App
//

import SwiftUI

struct LocationProfilesView: View {
    @AppStorage("locationProfiles") private var locationProfiles: [String] = []
    
    var body: some View {
        List {
            TextFieldLink(prompt: Text("Location Name")) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.body)
                        .foregroundColor(.ebirdGreen)
                    Text("Add Location")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.bold)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            } onSubmit: { input in
                let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                if !locationProfiles.contains(trimmed) {
                    locationProfiles.append(trimmed)
                }
            }
            .listRowBackground(Color.clear)
            .glassCard()
            
            if locationProfiles.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("No Saved Locations")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                    Text("Add locations you visit frequently.")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            } else {
                ForEach(locationProfiles, id: \.self) { profile in
                    Text(profile)
                        .font(.system(.body, design: .rounded))
                        .padding(.vertical, 6)
                }
                .onDelete { indexSet in
                    locationProfiles.remove(atOffsets: indexSet)
                }
            }
        }
        .listStyle(.carousel)
        .navigationTitle("Locations")
    }
}

#Preview {
    NavigationStack {
        LocationProfilesView()
    }
}

import SwiftUI
import QRCodeGenerator

public struct QRDisplayView: View {
    let checklist: Checklist
    
    @EnvironmentObject private var taxonRegistry: TaxonRegistry
    @Environment(\.dismiss) private var dismiss
    
    @State private var qrCode: QRCode? = nil
    @State private var errorMsg: String? = nil
    
    public init(checklist: Checklist) {
        self.checklist = checklist
    }
    
    public var body: some View {
        VStack(spacing: 4) {
            if let qr = qrCode {
                Canvas { context, size in
                    let width = size.width
                    let moduleSize = width / CGFloat(qr.size)
                    
                    for y in 0..<qr.size {
                        for x in 0..<qr.size {
                            if qr.getModule(x: x, y: y) {
                                let rect = CGRect(
                                    x: CGFloat(x) * moduleSize,
                                    y: CGFloat(y) * moduleSize,
                                    width: moduleSize,
                                    height: moduleSize
                                )
                                context.fill(Path(rect), with: .color(.black))
                            }
                        }
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .padding(4)
                .background(Color.white) // White background for maximum scannability
                .cornerRadius(6)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                let version = (qr.size - 17) / 4
                if version > 10 {
                    Text("Large checklist — hold steady")
                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
            } else if let error = errorMsg {
                VStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                    Text("Export failed")
                        .font(.system(.headline, design: .rounded))
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
            } else {
                ProgressView("Generating QR...")
                    .padding(.vertical, 20)
            }
        }
        .padding(4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle()) // Make the whole area tappable
        .onTapGesture {
            WKInterfaceDevice.current().play(.click)
            dismiss()
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        .onAppear {
            generateQR()
        }
    }
    
    private func generateQR() {
        // 1. Get CSV string on main actor first
        let csvString: String
        do {
            let exporter = ChecklistExporter(taxonLookup: taxonRegistry)
            csvString = try exporter.exportToCSV(checklist)
        } catch {
            self.errorMsg = error.localizedDescription
            return
        }
        
        // 2. Perform compression, Base45 encoding, and QR generation on a background task
        Task.detached(priority: .userInitiated) {
            do {
                let data = Data(csvString.utf8)
                let compressed: Data
                do {
                    compressed = try (data as NSData).compressed(using: .zlib) as Data
                } catch {
                    throw ChecklistExportError.compressionFailed(error)
                }
                
                let base45String = Base45.encode(compressed)
                guard let encodedBase45 = base45String.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) else {
                    throw ChecklistExportError.encodingFailed
                }
                
                let baseURL = ChecklistExporter.Configuration.defaultBaseURL
                var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
                urlComponents?.percentEncodedFragment = encodedBase45
                
                guard let finalURL = urlComponents?.url else {
                    throw ChecklistExportError.invalidBaseURL
                }
                
                let qr = try QRCode.encode(text: finalURL.absoluteString, ecl: .low)
                
                await MainActor.run {
                    self.qrCode = qr
                }
            } catch {
                await MainActor.run {
                    self.errorMsg = error.localizedDescription
                }
            }
        }
    }
}

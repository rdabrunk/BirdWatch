import SwiftUI
import QRCodeGenerator

public struct QRDisplayView: View {
    let urlString: String
    
    @State private var qrCode: QRCode? = nil
    @State private var errorMsg: String? = nil
    
    public init(urlString: String) {
        self.urlString = urlString
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 8) {
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
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.white) // White background for maximum scannability
                    .cornerRadius(8)
                    
                    let version = (qr.size - 17) / 4
                    if version > 10 {
                        Text("Large checklist — hold steady in good light")
                            .font(.system(size: 8, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
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
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .navigationTitle("eBird QR Code")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            generateQR()
        }
    }
    
    private func generateQR() {
        do {
            let qr = try QRCode.encode(text: urlString, ecl: .low)
            self.qrCode = qr
        } catch {
            self.errorMsg = error.localizedDescription
        }
    }
}

# QR code as the CSV export mechanism

status: accepted — supersedes ADR-0002

iCloud Drive export (ADR-0002) requires the iCloud Documents entitlement, which is blocked under a free Personal Team provisioning profile. We encode completed checklists as QR codes displayed on the watch screen, which the user scans with their phone camera. The QR links to a self-contained GitHub Pages decoder page (`docs/decoder/`) that decompresses the payload and downloads the eBird-ready CSV.

## Pipeline

Raw eBird CSV (no header row) → Zlib Deflate → Base45 → URL QR code

The QR encodes a URL of the form `https://<user>.github.io/BirdWatch/decoder/#<BASE45DATA>`. The fragment (`#`) is never sent to GitHub's servers; decoding happens entirely in the browser.

## Considered Options

**iCloud Drive (ADR-0002):** Blocked by Personal Team entitlement restrictions. Superseded.

**Companion iPhone app via WatchConnectivity:** Clean UX but a whole new Xcode target to provision and re-sign every seven days under a Personal Team profile. Rejected.

**Direct cloud upload (Dropbox / URLSession):** Requires a third-party account and an API token stored on-device. Rejected to avoid external service dependency.

**Local network server:** Requires the user to run a server script and configure ATS exceptions per IP address. Too much friction for a solo field utility. Rejected.

**Pure Base45 QR (no URL):** Maximally space-efficient — stays in Alphanumeric Mode — but the phone camera surfaces the raw string rather than opening a browser. Rejected in favour of the URL approach for its tap-to-decode UX.

## Consequences

- `SwiftQRCodeGenerator` (pure-Swift, SPM) added as the only new dependency; no paid entitlements required.
- GitHub Pages must be enabled on the BirdWatch repo with `docs/` as the source.
- The URL prefix forces Byte Mode, costing ~1–2 QR versions versus pure alphanumeric. For the target range of 10–40 sightings the result sits in Version 8–10 ("Good" scan reliability on a wrist display).
- Error Correction Level L maximises data density; physical damage is not a concern for a watch screen.
- One QR code per checklist. Batching multiple checklists is out of scope.
- Location fields (Location Name, Latitude, Longitude, State/Province, Country Code) are intentionally blank in the export; the user fills them in eBird post-import.
- eBird Record Format requires **no header row** — row 1 is the first sighting. Protocol values must be lowercase (`stationary`, `traveling`, `incidental`).
- If the compressed payload would produce a QR code above Version 10, the watch displays the code with a warning that scan conditions need to be good. No hard cap.
- Export is accessible from both `ChecklistSummaryView` (end-of-checklist) and `HomeDashboardView` (historical re-export).

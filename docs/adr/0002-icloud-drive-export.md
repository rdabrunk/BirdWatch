# iCloud Drive as the CSV export mechanism

status: superseded by ADR-0003

The watchOS share sheet surfaces only Messages and Mail for CSV data — "Save to Files" is an iOS-only share sheet feature unavailable on watchOS. Rather than building a companion iPhone app or relying on AirDrop proximity, we write the generated CSV directly to the app's iCloud ubiquity container via `FileManager`. The file then appears automatically in Files → iCloud Drive → BirdWatch on the user's iPhone and Mac with no additional action required on the watch.

## Considered Options

**ShareLink (current behaviour):** Relies on the system share sheet. On watchOS this only surfaces Messages and Mail, making the watch→eBird transfer unnecessarily manual. Rejected.

**Companion iPhone app via WatchConnectivity:** Clean UX but a meaningful scope increase — a whole new app target to maintain. Rejected in favour of a watch-only approach.

**QR code:** Watch screen is too small to scan reliably, and a real-world checklist CSV exceeds practical QR code capacity. Rejected.

## Consequences

- The iCloud Documents entitlement must be added to the watch app target.
- Export becomes a passive "save" rather than an active "share" — the file appears in Files automatically rather than being sent somewhere explicitly.
- Sync delay is typically seconds but requires connectivity; offline export is not guaranteed to be immediately accessible on other devices.

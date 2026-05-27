# Dictation-first "Add Bird" flow

Tapping "Add Bird" (or "Add First Bird") immediately presents the system
`presentTextInputController` modal — with `.plain` input mode and dictation
pre-selected — rather than navigating to a search view first. After the user
speaks or types, the top-ranked transcription is used to filter taxa and a
results list is shown for confirmation. Cancelling the modal returns the user
to the active checklist with no navigation side-effect.

## Considered Options

**Navigate-first search (previous behaviour):** Tap → push `AddTaxonView` → tap
search field → type or dictate. Rejected because it requires two taps before
any input begins, and surfacing the full unfiltered taxon list (~10 k entries)
between those two taps is never useful in the field.

**Auto-focus only:** Keep `AddTaxonView` but programmatically focus the
`TextField` on appear so the keyboard appears automatically. Rejected because
this still pushes a navigation destination before input is received, meaning
cancel would land the user on an empty search screen rather than returning them
to the checklist.

## Consequences

- `AddTaxonView` becomes a results-only view that accepts an initial query
  parameter; the search field is retained as a visible fallback for the
  zero-results case so the user can refine manually without re-triggering
  dictation.
- Both entry points in `ActiveChecklistView` (toolbar button and empty-state
  "Add First Bird" button) use the same flow for consistency.
- Emoji input is excluded (`.plain` mode); scribble and keyboard remain
  available as system-provided alternatives on capable hardware.

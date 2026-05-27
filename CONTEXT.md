# BirdWatch

An offline-first watchOS application for high-speed logging of bird observations in the field.

## Language

### Internal Model Language
These strict, taxonomic terms are exclusively used in code architecture (structs, classes, variables, database schemas) to prevent ambiguity during engineering.

**Taxon**:
An entry in our bundled official eBird taxonomy database. It has a unique 4-letter **Alpha Code**, a **Common Name**, a **Scientific Name**, and an **eBird Code**.
_Avoid in code_: Bird, Species, Entry

**Sighting**:
An aggregated record of a specific **Taxon** observed during a **Checklist** session. It tracks a cumulative **Tally** of individuals seen.
_Avoid in code_: Observation, Record, Event

**Checklist**:
A single recording session or trip tracking all **Sightings** logged by a user. It has a defined start time and a state of being active or completed.
_Avoid in code_: Session, Trip Log, Sighting Session

**Location**:
The initial geographic coordinates (Latitude and Longitude) captured at the start of a **Checklist** only when the **Track Location** toggle is enabled. To ensure accuracy, the GPS reading must be fresh—specifically, the coordinate's hardware timestamp must occur at or after the **Checklist**'s start time, ignoring any older cached coordinates provided by the OS.
_Avoid in code_: Position, Coordinates, GPS Point

**Effort Distance**:
The cumulative physical distance covered during a **Checklist**, measured in miles. When **Track Location** is enabled, it is tracked via GPS. If the distance exceeds a defined threshold (e.g., 0.05 miles), the checklist is implicitly classified under the **Traveling** **Protocol Type**; otherwise, it is classified as **Stationary**.
_Avoid in code_: Path, Track, Route Distance, Distance Covered

**Tally**:
The cumulative count of individual birds observed for a specific **Sighting** within a **Checklist**.
_Avoid in code_: Count, Number

### User-Facing Interface Language
These friendly, common birding terms are used in all UI labels, alerts, and user-facing text to maximize joy and familiarity.

**Bird / Species**:
The UI representation for a Taxon. Use "Bird" for individual actions (e.g., "Add Bird") and "Species" for aggregation (e.g., "12 Species").
_Avoid in UI_: Taxon, Taxa

**Count**:
The UI representation for a Tally. (e.g., "Total Count").
_Avoid in UI_: Tally

**Protocol Type**:
The formal classification of the **Checklist** session mapping to eBird's official standards (e.g., **Stationary**, **Traveling**, or **Incidental**), which determines tracking rules and the final export format.
_Avoid_: Method, Activity Type, Mode

**Complete Checklist**:
A boolean status indicating whether the user is reporting all identified birds seen or heard during a **Checklist** session, transforming it into a scientifically valuable record.
_Avoid_: All observations reported, Full log, Full checklist

**Observers Count**:
The total number of people participating in birding and counting during a **Checklist** session.
_Avoid_: Party size, Number of observers, Group count

**Quick Add Shortcut**:
The watchOS 10 Double Tap hand gesture shortcut mapped to opening the "Add Bird" text input from the active checklist view, and to selecting the top-ranked search result on the search view.
_Avoid_: Double Tap, Gesture Tap, Squeeze Select




## Flagged Ambiguities

- **Sighting timestamp**: A `Sighting` model includes a timestamp. Currently, this timestamp is not used in any meaningful way for features or exports, and sightings are aggregated checklist-wide rather than logged as individual sequential events.

## Example Dialogue

**Developer**: When a user taps a species in the search list, do we create a new sighting or increment the existing sighting?
**Domain Expert**: If that species has already been seen on this checklist, we just increment the tally of the existing sighting. If it's the first time they see that species on this trip, we add a new sighting to the active checklist.
**Developer**: Got it. So a checklist has many unique sightings, and each sighting has a tally representing the total count of that taxon seen.
**Domain Expert**: Exactly! And we keep everything offline so it works out in the field without any cellular service.

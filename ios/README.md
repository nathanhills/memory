# Memory for iPhone

Native SwiftUI iPhone app. Navigation, lists, forms, and empty states use system components (`TabView`, `NavigationStack`, `List`, `Form`, `ContentUnavailableView`).

Notes, reminder preferences, and dismissed reminders live on-device with SwiftData. People and events come from the iPhone Contacts and Calendar apps.

## Open in Xcode

1. On a Mac, open `ios/Memory.xcodeproj`.
2. Choose an iPhone simulator (iOS 17+) or a physical iPhone.
3. Select your Team under **Signing & Capabilities** if you are running on a device (`app.memory.ios`).
4. Press Run.

The first launch asks for Contacts, Calendar, and notification permission, then lands on **Today**.

## What you can do

| Tab | Purpose |
| --- | --- |
| Today | Who to remember this week, plus first-sync empty state |
| People | Searchable contacts; open anyone to add a note |
| Reminders | Notes due, birthdays, anniversaries, pre-event context |
| Settings | Sync now, hours-before-event, lock-screen notifications |

Reminders are rebuilt whenever you sync or save a note:

- Optional remind-on date on a note
- Next birthday / anniversary within 30 days
- Upcoming calendar events whose attendees match a contact (by email or name), with that person’s recent notes

## Permissions

The project already declares:

- `NSContactsUsageDescription`
- `NSCalendarsUsageDescription` / `NSCalendarsFullAccessUsageDescription`

Grant access on the Welcome screen. You can retry from Settings if a permission was denied.

## Requirements

- Xcode 16+
- iOS 17+
- iPhone (this target is iPhone-only)

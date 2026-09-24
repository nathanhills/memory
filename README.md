# Memory

Remember what matters about the people in your life. Memory is an **iPhone app** for notes about friends, birthdays, and what to recall before you meet.

The current focus is the native iOS build. A Next.js/Supabase web MVP remains in this repo as earlier work, but iOS is the product to run and iterate on.

## iOS (current)

Open and run:

```text
ios/Memory.xcodeproj
```

Full setup is in [`ios/README.md`](ios/README.md). In short:

1. Open the project in Xcode 16+ on a Mac.
2. Run on an iPhone simulator or device (iOS 17+).
3. Allow Contacts and Calendar on first launch.

People and events come from the iPhone address book and calendars. Notes and reminders stay on-device.

| Tab | Purpose |
| --- | --- |
| Updates | Reminders due now and coming up; settings from the header |
| Contacts | Searchable people; open anyone for notes and shared events |

## Web MVP (earlier)

The Next.js app under the repo root used Google Contacts/Calendar and Supabase. It is not required to run the iPhone app.

```bash
npm install
cp .env.example .env.local
npm run dev
```

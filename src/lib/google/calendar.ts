import { google } from "googleapis";
import { addDays } from "date-fns";
import { googleClient } from "@/lib/google/tokens";

export type ParsedCalendarEvent = {
  google_event_id: string;
  calendar_id: string;
  title: string | null;
  description: string | null;
  location: string | null;
  starts_at: string | null;
  ends_at: string | null;
  all_day: boolean;
  attendee_emails: string[];
  raw: unknown;
};

export async function fetchUpcomingCalendarEvents(
  accessToken: string,
  daysAhead = 90,
): Promise<ParsedCalendarEvent[]> {
  const auth = googleClient(accessToken);
  const calendar = google.calendar({ version: "v3", auth });
  const timeMin = new Date().toISOString();
  const timeMax = addDays(new Date(), daysAhead).toISOString();
  const results: ParsedCalendarEvent[] = [];
  let pageToken: string | undefined;

  do {
    const res = await calendar.events.list({
      calendarId: "primary",
      singleEvents: true,
      orderBy: "startTime",
      timeMin,
      timeMax,
      maxResults: 250,
      pageToken,
    });

    for (const event of res.data.items ?? []) {
      if (!event.id || event.status === "cancelled") continue;

      const allDay = Boolean(event.start?.date && !event.start?.dateTime);
      const startsAt = event.start?.dateTime
        ? event.start.dateTime
        : event.start?.date
          ? new Date(`${event.start.date}T00:00:00.000Z`).toISOString()
          : null;
      const endsAt = event.end?.dateTime
        ? event.end.dateTime
        : event.end?.date
          ? new Date(`${event.end.date}T00:00:00.000Z`).toISOString()
          : null;

      const attendeeEmails = (event.attendees ?? [])
        .map((a) => a.email?.trim().toLowerCase())
        .filter((v): v is string => Boolean(v));

      results.push({
        google_event_id: event.id,
        calendar_id: "primary",
        title: event.summary ?? null,
        description: event.description ?? null,
        location: event.location ?? null,
        starts_at: startsAt,
        ends_at: endsAt,
        all_day: allDay,
        attendee_emails: attendeeEmails,
        raw: event,
      });
    }

    pageToken = res.data.nextPageToken ?? undefined;
  } while (pageToken);

  return results;
}

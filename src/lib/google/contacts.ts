import { google } from "googleapis";
import { googleClient } from "@/lib/google/tokens";

export type ParsedContact = {
  google_resource_name: string;
  display_name: string | null;
  given_name: string | null;
  family_name: string | null;
  emails: string[];
  phones: string[];
  photo_url: string | null;
  birthday_month: number | null;
  birthday_day: number | null;
  birthday_year: number | null;
  anniversary_month: number | null;
  anniversary_day: number | null;
  anniversary_year: number | null;
  raw: unknown;
};

function parseDateParts(date?: {
  year?: number | null;
  month?: number | null;
  day?: number | null;
}) {
  return {
    year: date?.year ?? null,
    month: date?.month ?? null,
    day: date?.day ?? null,
  };
}

export async function fetchGoogleContacts(
  accessToken: string,
): Promise<ParsedContact[]> {
  const auth = googleClient(accessToken);
  const people = google.people({ version: "v1", auth });
  const results: ParsedContact[] = [];
  let pageToken: string | undefined;

  do {
    const res = await people.people.connections.list({
      resourceName: "people/me",
      pageSize: 200,
      pageToken,
      personFields:
        "names,emailAddresses,phoneNumbers,photos,birthdays,events,metadata",
      sortOrder: "FIRST_NAME_ASCENDING",
    });

    for (const person of res.data.connections ?? []) {
      const resourceName = person.resourceName;
      if (!resourceName) continue;

      const primaryName =
        person.names?.find((n) => n.metadata?.primary) ?? person.names?.[0];
      const emails = (person.emailAddresses ?? [])
        .map((e) => e.value?.trim().toLowerCase())
        .filter((v): v is string => Boolean(v));
      const phones = (person.phoneNumbers ?? [])
        .map((p) => p.value?.trim())
        .filter((v): v is string => Boolean(v));
      const photo =
        person.photos?.find((p) => p.metadata?.primary)?.url ??
        person.photos?.[0]?.url ??
        null;

      const birthday =
        person.birthdays?.find((b) => b.metadata?.primary)?.date ??
        person.birthdays?.[0]?.date;
      const birthdayParts = parseDateParts(birthday ?? undefined);

      const anniversaryEvent = person.events?.find(
        (e) => (e.type ?? "").toLowerCase() === "anniversary",
      );
      const anniversaryParts = parseDateParts(anniversaryEvent?.date ?? undefined);

      const joinedName = [primaryName?.givenName, primaryName?.familyName]
        .filter(Boolean)
        .join(" ");

      results.push({
        google_resource_name: resourceName,
        display_name:
          primaryName?.displayName || joinedName || emails[0] || null,
        given_name: primaryName?.givenName ?? null,
        family_name: primaryName?.familyName ?? null,
        emails,
        phones,
        photo_url: photo,
        birthday_month: birthdayParts.month,
        birthday_day: birthdayParts.day,
        birthday_year: birthdayParts.year,
        anniversary_month: anniversaryParts.month,
        anniversary_day: anniversaryParts.day,
        anniversary_year: anniversaryParts.year,
        raw: person,
      });
    }

    pageToken = res.data.nextPageToken ?? undefined;
  } while (pageToken);

  return results;
}

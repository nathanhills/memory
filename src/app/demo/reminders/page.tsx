import { ReminderList } from "@/components/ReminderList";
import { demoReminders } from "@/lib/demo/mock-data";

export default function DemoRemindersPage() {
  return (
    <div>
      <h1 className="font-[family-name:var(--font-display)] text-3xl text-ink">
        Reminders
      </h1>
      <p className="mt-1 mb-8 text-ink-soft">
        Notes due, birthdays, anniversaries, and pre-event context.
      </p>
      <ReminderList reminders={demoReminders} />
    </div>
  );
}

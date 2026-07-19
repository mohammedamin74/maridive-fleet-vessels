/// Injectable wall-clock accessor for day-boundary business logic (cert
/// expiry tiers, task/notification overdue checks). Production code always
/// reads the real time; tests pin [now] to a fixed instant so a boundary
/// like "exactly 30 days left" is deterministic instead of depending on the
/// moment the test happens to run.
DateTime Function() _now = DateTime.now;

DateTime clockNow() => _now();

void setClockForTesting(DateTime Function() now) => _now = now;

void resetClock() => _now = DateTime.now;

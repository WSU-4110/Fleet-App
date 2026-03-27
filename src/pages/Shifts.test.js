import { describe, it, expect, vi, beforeEach } from "vitest";
import { getRangeStart, formatDuration, formatTimestamp } from "./Shifts.jsx";

// Mock firebase/firestore so importing Shifts.jsx doesn't require a real Firebase app
vi.mock("firebase/firestore", () => ({
  collection: vi.fn(),
  query: vi.fn(),
  orderBy: vi.fn(),
  limit: vi.fn(),
  startAfter: vi.fn(),
  where: vi.fn(),
  getDocs: vi.fn(),
  Timestamp: {
    fromDate: (date) => ({ toDate: () => date, _isTimestamp: true }),
  },
}));

vi.mock("../firebase", () => ({ db: {} }));

// Helper: create a fake Firestore Timestamp from a Date
function ts(date) {
  return { toDate: () => date };
}

// ─── getRangeStart ────────────────────────────────────────────────────────────

describe("getRangeStart", () => {
  beforeEach(() => {
    // Fix "now" to 2026-03-26 Wednesday 14:30:00 UTC
    vi.setSystemTime(new Date("2026-03-26T14:30:00.000Z"));
  });

  it('returns null for "all"', () => {
    expect(getRangeStart("all")).toBeNull();
  });

  it('returns midnight today for "today"', () => {
    const result = getRangeStart("today");
    const date = result.toDate();
    expect(date.getHours()).toBe(0);
    expect(date.getMinutes()).toBe(0);
    expect(date.getSeconds()).toBe(0);
    expect(date.getMilliseconds()).toBe(0);
    // same calendar day
    const now = new Date();
    expect(date.getFullYear()).toBe(now.getFullYear());
    expect(date.getMonth()).toBe(now.getMonth());
    expect(date.getDate()).toBe(now.getDate());
  });

  it('returns start of week (Sunday) for "week"', () => {
    const result = getRangeStart("week");
    const date = result.toDate();
    expect(date.getDay()).toBe(0); // Sunday
    expect(date.getHours()).toBe(0);
    expect(date.getMinutes()).toBe(0);
  });

  it('returns 1st of the month for "month"', () => {
    const result = getRangeStart("month");
    const date = result.toDate();
    expect(date.getDate()).toBe(1);
    expect(date.getHours()).toBe(0);
  });
});

// ─── formatDuration ───────────────────────────────────────────────────────────

describe("formatDuration", () => {
  it("returns — when clockIn is missing", () => {
    expect(formatDuration(null, ts(new Date()))).toBe("—");
  });

  it("returns — when clockOut is missing", () => {
    expect(formatDuration(ts(new Date()), null)).toBe("—");
  });

  it("returns — when clockOut is before clockIn", () => {
    const base = new Date("2026-03-12T08:00:00Z");
    const earlier = new Date("2026-03-12T07:00:00Z");
    expect(formatDuration(ts(base), ts(earlier))).toBe("—");
  });

  it("formats seconds only", () => {
    const clockIn = new Date("2026-03-12T08:43:28Z");
    const clockOut = new Date("2026-03-12T08:43:31Z"); // 3 seconds
    expect(formatDuration(ts(clockIn), ts(clockOut))).toBe("3s");
  });

  it("formats minutes and seconds", () => {
    const clockIn = new Date("2026-03-12T08:00:00Z");
    const clockOut = new Date("2026-03-12T08:05:45Z"); // 5m 45s
    expect(formatDuration(ts(clockIn), ts(clockOut))).toBe("5m 45s");
  });

  it("formats hours and minutes (no seconds shown)", () => {
    const clockIn = new Date("2026-03-12T08:00:00Z");
    const clockOut = new Date("2026-03-12T10:30:00Z"); // 2h 30m
    expect(formatDuration(ts(clockIn), ts(clockOut))).toBe("2h 30m");
  });

  it("formats exactly 1 hour", () => {
    const clockIn = new Date("2026-03-12T09:00:00Z");
    const clockOut = new Date("2026-03-12T10:00:00Z");
    expect(formatDuration(ts(clockIn), ts(clockOut))).toBe("1h 0m");
  });

  it("formats exactly 1 minute", () => {
    const clockIn = new Date("2026-03-12T09:00:00Z");
    const clockOut = new Date("2026-03-12T09:01:00Z");
    expect(formatDuration(ts(clockIn), ts(clockOut))).toBe("1m 0s");
  });
});

// ─── formatTimestamp ──────────────────────────────────────────────────────────

describe("formatTimestamp", () => {
  it("returns null for a missing timestamp", () => {
    expect(formatTimestamp(null)).toBeNull();
    expect(formatTimestamp(undefined)).toBeNull();
  });

  it("returns an object with date and time strings", () => {
    const result = formatTimestamp(ts(new Date("2026-03-12T12:43:28.000Z")));
    expect(result).toHaveProperty("date");
    expect(result).toHaveProperty("time");
    expect(typeof result.date).toBe("string");
    expect(typeof result.time).toBe("string");
  });

  it("date string contains the month abbreviation", () => {
    const result = formatTimestamp(ts(new Date("2026-03-12T12:00:00.000Z")));
    expect(result.date).toMatch(/Mar/);
  });

  it("date string contains the year", () => {
    const result = formatTimestamp(ts(new Date("2026-03-12T12:00:00.000Z")));
    expect(result.date).toContain("2026");
  });

  it("time string contains AM or PM", () => {
    const result = formatTimestamp(ts(new Date("2026-03-12T12:00:00.000Z")));
    expect(result.time).toMatch(/AM|PM/);
  });
});

import { useEffect, useState, useCallback } from "react";
import { collection, query, orderBy, limit, startAfter, where, getDocs, Timestamp } from "firebase/firestore";
import { db } from "../firebase";

const PAGE_SIZE = 10;

const PERIODS = [
  { label: "Today", value: "today" },
  { label: "This Week", value: "week" },
  { label: "This Month", value: "month" },
  { label: "All", value: "all" },
];

export function getRangeStart(period) {
  if (period === "all") return null;
  const start = new Date();
  if (period === "today") {
    start.setHours(0, 0, 0, 0);
  } else if (period === "week") {
    start.setDate(start.getDate() - start.getDay());
    start.setHours(0, 0, 0, 0);
  } else if (period === "month") {
    start.setDate(1);
    start.setHours(0, 0, 0, 0);
  }
  return Timestamp.fromDate(start);
}

function buildQuery(period, cursor) {
  const rangeStart = getRangeStart(period);
  const constraints = [orderBy("clockIn", "desc"), limit(PAGE_SIZE + 1)];
  if (rangeStart) constraints.unshift(where("clockIn", ">=", rangeStart));
  if (cursor) constraints.push(startAfter(cursor));
  return query(collection(db, "timesheets"), ...constraints);
}

export function formatDuration(clockIn, clockOut) {
  if (!clockIn || !clockOut) return "—";
  const ms = clockOut.toDate() - clockIn.toDate();
  if (ms < 0) return "—";
  const totalSeconds = Math.floor(ms / 1000);
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;
  if (hours > 0) return `${hours}h ${minutes}m`;
  if (minutes > 0) return `${minutes}m ${seconds}s`;
  return `${seconds}s`;
}

export function formatTimestamp(ts) {
  if (!ts) return null;
  const date = ts.toDate();
  const datePart = date.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });
  const timePart = date.toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit", hour12: true });
  return { date: datePart, time: timePart };
}

export default function Shifts() {
  const [shifts, setShifts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [period, setPeriod] = useState("all");
  const [cursorStack, setCursorStack] = useState([]); // one entry per page boundary
  const [lastDoc, setLastDoc] = useState(null);
  const [hasMore, setHasMore] = useState(false);

  const fetchPage = useCallback(async (period, cursor, stack) => {
    setLoading(true);
    setError("");
    try {
      const snap = await getDocs(buildQuery(period, cursor));
      const docs = snap.docs.slice(0, PAGE_SIZE);
      setShifts(docs.map((d) => ({ id: d.id, ...d.data() })));
      setHasMore(snap.docs.length > PAGE_SIZE);
      setLastDoc(docs[docs.length - 1] ?? null);
      setCursorStack(stack);
    } catch (err) {
      setError("Failed to load shifts.");
    } finally {
      setLoading(false);
    }
  }, []);

  // Reset to page 1 whenever period changes
  useEffect(() => {
    fetchPage(period, null, []);
  }, [period, fetchPage]);

  const handleNext = () => {
    if (!lastDoc) return;
    fetchPage(period, lastDoc, [...cursorStack, lastDoc]);
  };

  const handlePrev = () => {
    const newStack = cursorStack.slice(0, -1);
    const prevCursor = newStack[newStack.length - 1] ?? null;
    fetchPage(period, prevCursor, newStack);
  };

  const page = cursorStack.length + 1;

  return (
    <div>
      <div style={styles.header}>
        <div>
          <h1 style={styles.heading}>Shifts</h1>
          <p style={styles.sub}>
            {loading ? "Loading..." : `Page ${page} · ${shifts.length} record${shifts.length !== 1 ? "s" : ""}`}
          </p>
        </div>
        <div style={styles.filterGroup}>
          {PERIODS.map((p) => (
            <button
              key={p.value}
              onClick={() => setPeriod(p.value)}
              style={period === p.value ? { ...styles.filterBtn, ...styles.filterBtnActive } : styles.filterBtn}
            >
              {p.label}
            </button>
          ))}
        </div>
      </div>

      {error && <div style={styles.error}>⚠️ {error}</div>}

      <div style={styles.tableWrapper}>
        <table style={styles.table}>
          <thead>
            <tr>
              <th style={styles.th}>Employee</th>
              <th style={styles.th}>Clock In</th>
              <th style={styles.th}>Clock Out</th>
              <th style={styles.th}>Duration</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={4} style={styles.loadingCell}>Loading shifts...</td></tr>
            ) : shifts.length === 0 ? (
              <tr><td colSpan={4} style={styles.loadingCell}>No shifts found for this period.</td></tr>
            ) : (
              shifts.map((shift, i) => {
                const inTs = formatTimestamp(shift.clockIn);
                const outTs = formatTimestamp(shift.clockOut);
                return (
                  <tr key={shift.id} style={{ backgroundColor: i % 2 === 0 ? "white" : "#f8faff" }}>
                    <td style={styles.td}>
                      <div style={styles.employeeCell}>
                        <div style={shift.name ? styles.avatar : styles.avatarUnknown}>
                          {shift.name ? shift.name.charAt(0).toUpperCase() : "?"}
                        </div>
                        {shift.name
                          ? <span style={styles.employeeName}>{shift.name}</span>
                          : <span style={styles.noName}>No name on record</span>}
                      </div>
                    </td>
                    <td style={styles.td}>
                      {inTs ? <><span style={styles.tsDate}>{inTs.date}</span><br /><span style={styles.tsTime}>{inTs.time}</span></> : <span style={styles.tsTime}>—</span>}
                    </td>
                    <td style={styles.td}>
                      {outTs ? <><span style={styles.tsDate}>{outTs.date}</span><br /><span style={styles.tsTime}>{outTs.time}</span></> : <span style={styles.tsTime}>—</span>}
                    </td>
                    <td style={styles.td}>
                      <span style={styles.duration}>{formatDuration(shift.clockIn, shift.clockOut)}</span>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>

        <div style={styles.pagination}>
          <button
            onClick={handlePrev}
            disabled={page === 1 || loading}
            style={page === 1 || loading ? { ...styles.pageBtn, ...styles.pageBtnDisabled } : styles.pageBtn}
          >
            ← Previous
          </button>
          <span style={styles.pageLabel}>Page {page}</span>
          <button
            onClick={handleNext}
            disabled={!hasMore || loading}
            style={!hasMore || loading ? { ...styles.pageBtn, ...styles.pageBtnDisabled } : styles.pageBtn}
          >
            Next →
          </button>
        </div>
      </div>
    </div>
  );
}

const styles = {
  header: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "flex-start",
    marginBottom: "28px",
  },
  heading: {
    fontSize: "28px",
    fontWeight: "700",
    color: "#111827",
    margin: "0 0 4px 0",
    fontFamily: "Inter, system-ui, sans-serif",
  },
  sub: {
    color: "#6b7280",
    fontSize: "14px",
    margin: 0,
    fontFamily: "Inter, system-ui, sans-serif",
  },
  filterGroup: {
    display: "flex",
    gap: "6px",
    alignItems: "center",
  },
  filterBtn: {
    padding: "7px 16px",
    borderRadius: "8px",
    border: "1.5px solid #e5e7eb",
    backgroundColor: "white",
    color: "#6b7280",
    fontSize: "13px",
    fontWeight: "500",
    cursor: "pointer",
    fontFamily: "Inter, system-ui, sans-serif",
  },
  filterBtnActive: {
    backgroundColor: "#1e3a8a",
    borderColor: "#1e3a8a",
    color: "white",
    fontWeight: "700",
  },
  error: {
    backgroundColor: "#fef2f2",
    border: "1px solid #fca5a5",
    color: "#b91c1c",
    fontSize: "13px",
    padding: "10px 14px",
    borderRadius: "8px",
    marginBottom: "20px",
    fontFamily: "Inter, system-ui, sans-serif",
  },
  tableWrapper: {
    backgroundColor: "white",
    borderRadius: "14px",
    boxShadow: "0 4px 20px rgba(0,0,0,0.06)",
    overflow: "hidden",
    border: "1px solid #e5e7eb",
  },
  table: {
    width: "100%",
    borderCollapse: "collapse",
    fontFamily: "Inter, system-ui, sans-serif",
  },
  th: {
    padding: "14px 20px",
    textAlign: "left",
    fontSize: "11px",
    fontWeight: "700",
    color: "#6b7280",
    textTransform: "uppercase",
    letterSpacing: "0.6px",
    backgroundColor: "#f9fafb",
    borderBottom: "1px solid #e5e7eb",
  },
  td: {
    padding: "14px 20px",
    borderBottom: "1px solid #f3f4f6",
    verticalAlign: "middle",
  },
  loadingCell: {
    padding: "32px 20px",
    textAlign: "center",
    color: "#9ca3af",
    fontSize: "14px",
  },
  pagination: {
    display: "flex",
    alignItems: "center",
    justifyContent: "flex-end",
    gap: "12px",
    padding: "14px 20px",
    borderTop: "1px solid #f3f4f6",
  },
  pageBtn: {
    padding: "7px 16px",
    borderRadius: "8px",
    border: "1.5px solid #e5e7eb",
    backgroundColor: "white",
    color: "#374151",
    fontSize: "13px",
    fontWeight: "600",
    cursor: "pointer",
    fontFamily: "Inter, system-ui, sans-serif",
  },
  pageBtnDisabled: {
    color: "#d1d5db",
    borderColor: "#f3f4f6",
    cursor: "not-allowed",
  },
  pageLabel: {
    fontSize: "13px",
    color: "#6b7280",
    fontFamily: "Inter, system-ui, sans-serif",
    minWidth: "50px",
    textAlign: "center",
  },
  employeeCell: {
    display: "flex",
    alignItems: "center",
    gap: "10px",
  },
  avatar: {
    width: "34px",
    height: "34px",
    borderRadius: "50%",
    background: "linear-gradient(135deg, #1e3a8a, #2563eb)",
    color: "white",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    fontWeight: "700",
    fontSize: "14px",
    flexShrink: 0,
  },
  avatarUnknown: {
    width: "34px",
    height: "34px",
    borderRadius: "50%",
    background: "#e5e7eb",
    color: "#9ca3af",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    fontWeight: "700",
    fontSize: "14px",
    flexShrink: 0,
  },
  employeeName: {
    fontSize: "14px",
    fontWeight: "600",
    color: "#1e3a8a",
  },
  noName: {
    fontSize: "13px",
    color: "#9ca3af",
    fontStyle: "italic",
  },
  tsDate: {
    fontSize: "13px",
    fontWeight: "600",
    color: "#111827",
  },
  tsTime: {
    fontSize: "12px",
    color: "#6b7280",
  },
  duration: {
    fontSize: "13px",
    fontWeight: "600",
    color: "#059669",
    backgroundColor: "#d1fae5",
    padding: "3px 10px",
    borderRadius: "20px",
    display: "inline-block",
  },
};

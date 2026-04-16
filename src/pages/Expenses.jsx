import { useEffect, useState, useCallback } from "react";
import {
  collection, query, orderBy, limit, startAfter, where,
  getDocs, getDoc, addDoc, deleteDoc, doc, Timestamp,
} from "firebase/firestore";
import { db } from "../firebase";
import { useAuth } from "../AuthContext";

const PAGE_SIZE = 10;

const PERIODS = [
  { label: "Today", value: "today" },
  { label: "This Week", value: "week" },
  { label: "This Month", value: "month" },
  { label: "All", value: "all" },
];

const CATEGORIES = ["Fuel", "Maintenance", "Tolls", "Parking", "Meals", "Other"];

const CATEGORY_COLORS = {
  Fuel:        { bg: "#fef9c3", color: "#854d0e" },
  Maintenance: { bg: "#fee2e2", color: "#b91c1c" },
  Tolls:       { bg: "#ede9fe", color: "#6d28d9" },
  Parking:     { bg: "#dbeafe", color: "#1d4ed8" },
  Meals:       { bg: "#d1fae5", color: "#065f46" },
  Other:       { bg: "#f3f4f6", color: "#374151" },
};

function getCategoryStyle(category) {
  return CATEGORY_COLORS[category] ?? CATEGORY_COLORS.Other;
}

function getRangeStart(period) {
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

function buildQuery(businessId, period, cursor) {
  const rangeStart = getRangeStart(period);
  const constraints = [orderBy("date", "desc"), limit(PAGE_SIZE + 1)];
  if (rangeStart) constraints.unshift(where("date", ">=", rangeStart));
  if (cursor) constraints.push(startAfter(cursor));
  return query(collection(db, "businesses", businessId, "expenses"), ...constraints);
}

function formatDate(ts) {
  if (!ts) return null;
  const date = ts.toDate();
  return {
    date: date.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" }),
    time: date.toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit", hour12: true }),
  };
}

function formatAmount(amount) {
  if (amount == null) return "—";
  return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(amount);
}

const EMPTY_FORM = { employeeName: "", category: "Fuel", vehicleId: "", note: "", amount: "", date: "" };

export default function Expenses() {
  const { businessId } = useAuth();
  const [expenses, setExpenses] = useState([]);
  const [vehicles, setVehicles] = useState({});
  const [vehicleList, setVehicleList] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [period, setPeriod] = useState("all");
  const [cursorStack, setCursorStack] = useState([]);
  const [lastDoc, setLastDoc] = useState(null);
  const [hasMore, setHasMore] = useState(false);

  // Add modal
  const [showModal, setShowModal] = useState(false);
  const [form, setForm] = useState(EMPTY_FORM);
  const [formError, setFormError] = useState("");
  const [saving, setSaving] = useState(false);

  // Delete / select mode
  const [selectMode, setSelectMode] = useState(false);
  const [selected, setSelected] = useState(new Set());
  const [deleting, setDeleting] = useState(false);

  // Fetch vehicle list once for the add modal dropdown
  useEffect(() => {
    if (!businessId) return;
    getDocs(collection(db, "businesses", businessId, "vehicles")).then((snap) => {
      setVehicleList(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
    });
  }, [businessId]);

  const fetchPage = useCallback(async (period, cursor, stack) => {
    if (!businessId) { setLoading(false); return; }
    setLoading(true);
    setError("");
    try {
      const snap = await getDocs(buildQuery(businessId, period, cursor));
      const docs = snap.docs.slice(0, PAGE_SIZE);
      const expenseData = docs.map((d) => ({ id: d.id, ...d.data() }));
      setExpenses(expenseData);
      setHasMore(snap.docs.length > PAGE_SIZE);
      setLastDoc(docs[docs.length - 1] ?? null);
      setCursorStack(stack);

      const uniqueVehicleIds = [...new Set(expenseData.map((e) => e.vehicleId).filter(Boolean))];
      const vehicleEntries = await Promise.all(
        uniqueVehicleIds.map(async (vid) => {
          const snap = await getDoc(doc(db, "businesses", businessId, "vehicles", vid));
          return [vid, snap.exists() ? snap.data() : null];
        })
      );
      setVehicles((prev) => ({ ...prev, ...Object.fromEntries(vehicleEntries) }));
    } catch {
      setError("Failed to load expenses.");
    } finally {
      setLoading(false);
    }
  }, [businessId]);

  useEffect(() => { fetchPage(period, null, []); }, [period, fetchPage]);

  const handleNext = () => { if (!lastDoc) return; fetchPage(period, lastDoc, [...cursorStack, lastDoc]); };
  const handlePrev = () => { const s = cursorStack.slice(0, -1); fetchPage(period, s[s.length - 1] ?? null, s); };

  // Add
  const handleCreate = async () => {
    if (!form.employeeName.trim() || !form.amount || !form.date) {
      setFormError("Employee name, amount, and date are required.");
      return;
    }
    const amount = parseFloat(form.amount);
    if (isNaN(amount) || amount < 0) { setFormError("Enter a valid amount."); return; }
    setSaving(true);
    setFormError("");
    try {
      const dateObj = new Date(form.date);
      await addDoc(collection(db, "businesses", businessId, "expenses"), {
        employeeName: form.employeeName.trim(),
        category: form.category,
        vehicleId: form.vehicleId || null,
        note: form.note.trim(),
        amount,
        date: Timestamp.fromDate(dateObj),
        submittedAt: Timestamp.now(),
        businessId,
      });
      setShowModal(false);
      setForm(EMPTY_FORM);
      fetchPage(period, null, []);
    } catch (err) {
      setFormError(`Failed to save: ${err.message}`);
    } finally {
      setSaving(false);
    }
  };

  // Delete
  const toggleSelect = (id) => {
    setSelected((prev) => { const next = new Set(prev); next.has(id) ? next.delete(id) : next.add(id); return next; });
  };
  const toggleSelectAll = () => {
    setSelected(selected.size === expenses.length ? new Set() : new Set(expenses.map((e) => e.id)));
  };
  const handleDeleteSelected = async () => {
    if (selected.size === 0) return;
    if (!window.confirm(`Delete ${selected.size} expense(s)?`)) return;
    setDeleting(true);
    try {
      await Promise.all([...selected].map((id) => deleteDoc(doc(db, "businesses", businessId, "expenses", id))));
      setSelected(new Set());
      setSelectMode(false);
      fetchPage(period, null, []);
    } catch (err) {
      setError(`Failed to delete: ${err.message}`);
    } finally {
      setDeleting(false);
    }
  };
  const exitSelectMode = () => { setSelectMode(false); setSelected(new Set()); };

  const page = cursorStack.length + 1;
  const total = expenses.reduce((sum, e) => sum + (e.amount ?? 0), 0);
  const allSelected = expenses.length > 0 && selected.size === expenses.length;
  const colSpan = selectMode ? 8 : 7;

  return (
    <div>
      <div style={styles.header}>
        <div>
          <h1 style={styles.heading}>Expenses</h1>
          <p style={styles.sub}>
            {loading
              ? "Loading..."
              : `Page ${page} · ${expenses.length} record${expenses.length !== 1 ? "s" : ""}${expenses.length > 0 ? ` · ${formatAmount(total)} total` : ""}`}
          </p>
        </div>
        <div style={styles.headerRight}>
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
          {selectMode ? (
            <>
              <span style={styles.selectionCount}>{selected.size} selected</span>
              <button style={styles.deleteSelectedBtn} onClick={handleDeleteSelected} disabled={selected.size === 0 || deleting}>
                {deleting ? "Deleting..." : "Delete Selected"}
              </button>
              <button style={styles.cancelSelectBtn} onClick={exitSelectMode}>Cancel</button>
            </>
          ) : (
            <>
              <button style={styles.deleteBtn} onClick={() => setSelectMode(true)}>Delete</button>
              <button style={styles.addBtn} onClick={() => { setShowModal(true); setFormError(""); }}>+ Add Expense</button>
            </>
          )}
        </div>
      </div>

      {error && <div style={styles.error}>⚠️ {error}</div>}

      <div style={styles.tableWrapper}>
        <table style={styles.table}>
          <thead>
            <tr>
              {selectMode && (
                <th style={{ ...styles.th, width: "44px" }}>
                  <input type="checkbox" checked={allSelected} onChange={toggleSelectAll} style={styles.checkbox} />
                </th>
              )}
              <th style={styles.th}>Employee</th>
              <th style={styles.th}>Note</th>
              <th style={styles.th}>Category</th>
              <th style={styles.th}>Vehicle</th>
              <th style={styles.th}>Date</th>
              <th style={styles.th}>Receipt</th>
              <th style={{ ...styles.th, textAlign: "right" }}>Amount</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={colSpan} style={styles.loadingCell}>Loading expenses...</td></tr>
            ) : expenses.length === 0 ? (
              <tr><td colSpan={colSpan} style={styles.loadingCell}>No expenses found for this period.</td></tr>
            ) : (
              expenses.map((exp, i) => {
                const ts = formatDate(exp.date);
                const catStyle = getCategoryStyle(exp.category);
                const isSelected = selected.has(exp.id);
                return (
                  <tr
                    key={exp.id}
                    onClick={selectMode ? () => toggleSelect(exp.id) : undefined}
                    style={{
                      backgroundColor: isSelected ? "#eff6ff" : i % 2 === 0 ? "white" : "#f8faff",
                      cursor: selectMode ? "pointer" : "default",
                    }}
                  >
                    {selectMode && (
                      <td style={styles.td}>
                        <input
                          type="checkbox"
                          checked={isSelected}
                          onChange={() => toggleSelect(exp.id)}
                          onClick={(e) => e.stopPropagation()}
                          style={styles.checkbox}
                        />
                      </td>
                    )}
                    <td style={styles.td}>
                      <div style={styles.employeeCell}>
                        <div style={exp.employeeName ? styles.avatar : styles.avatarUnknown}>
                          {exp.employeeName ? exp.employeeName.charAt(0).toUpperCase() : "?"}
                        </div>
                        {exp.employeeName
                          ? <span style={styles.employeeName}>{exp.employeeName}</span>
                          : <span style={styles.noName}>Unknown</span>}
                      </div>
                    </td>
                    <td style={styles.td}><span style={styles.description}>{exp.note || "—"}</span></td>
                    <td style={styles.td}>
                      {exp.category
                        ? <span style={{ ...styles.categoryBadge, backgroundColor: catStyle.bg, color: catStyle.color }}>{exp.category}</span>
                        : <span style={styles.noName}>—</span>}
                    </td>
                    <td style={styles.td}>
                      {exp.vehicleId && vehicles[exp.vehicleId]
                        ? <span style={styles.vehicleLabel}>{vehicles[exp.vehicleId].emoji} {vehicles[exp.vehicleId].make} {vehicles[exp.vehicleId].model}</span>
                        : <span style={styles.noName}>{exp.vehicleId ? "Loading..." : "—"}</span>}
                    </td>
                    <td style={styles.td}>
                      {ts
                        ? <><span style={styles.tsDate}>{ts.date}</span><br /><span style={styles.tsTime}>{ts.time}</span></>
                        : <span style={styles.tsTime}>—</span>}
                    </td>
                    <td style={styles.td}>
                      {exp.receiptURL
                        ? <a href={exp.receiptURL} target="_blank" rel="noreferrer" style={styles.receiptLink}>View</a>
                        : <span style={styles.noName}>—</span>}
                    </td>
                    <td style={{ ...styles.td, textAlign: "right" }}>
                      <span style={styles.amount}>{formatAmount(exp.amount)}</span>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>

        <div style={styles.pagination}>
          <button onClick={handlePrev} disabled={page === 1 || loading} style={page === 1 || loading ? { ...styles.pageBtn, ...styles.pageBtnDisabled } : styles.pageBtn}>← Previous</button>
          <span style={styles.pageLabel}>Page {page}</span>
          <button onClick={handleNext} disabled={!hasMore || loading} style={!hasMore || loading ? { ...styles.pageBtn, ...styles.pageBtnDisabled } : styles.pageBtn}>Next →</button>
        </div>
      </div>

      {showModal && (
        <div style={styles.overlay}>
          <div style={styles.modal}>
            <h2 style={styles.modalTitle}>Add Expense</h2>
            {formError && <div style={styles.formError}>{formError}</div>}

            <label style={styles.label}>Employee Name</label>
            <input style={styles.input} placeholder="e.g. John Smith" value={form.employeeName} onChange={(e) => setForm({ ...form, employeeName: e.target.value })} />

            <label style={styles.label}>Category</label>
            <select style={styles.input} value={form.category} onChange={(e) => setForm({ ...form, category: e.target.value })}>
              {CATEGORIES.map((c) => <option key={c} value={c}>{c}</option>)}
            </select>

            <label style={styles.label}>Vehicle (optional)</label>
            <select style={styles.input} value={form.vehicleId} onChange={(e) => setForm({ ...form, vehicleId: e.target.value })}>
              <option value="">— None —</option>
              {vehicleList.map((v) => (
                <option key={v.id} value={v.id}>{v.emoji} {v.make} {v.model} ({v.licensePlate})</option>
              ))}
            </select>

            <label style={styles.label}>Note (optional)</label>
            <input style={styles.input} placeholder="e.g. Brakes replacement" value={form.note} onChange={(e) => setForm({ ...form, note: e.target.value })} />

            <label style={styles.label}>Amount ($)</label>
            <input style={styles.input} type="number" min="0" step="0.01" placeholder="0.00" value={form.amount} onChange={(e) => setForm({ ...form, amount: e.target.value })} />

            <label style={styles.label}>Date</label>
            <input style={styles.input} type="datetime-local" value={form.date} onChange={(e) => setForm({ ...form, date: e.target.value })} />

            <div style={styles.modalActions}>
              <button style={styles.cancelBtn} onClick={() => { setShowModal(false); setForm(EMPTY_FORM); }}>Cancel</button>
              <button style={styles.saveBtn} onClick={handleCreate} disabled={saving}>{saving ? "Saving..." : "Save"}</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

const styles = {
  header: { display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "28px" },
  heading: { fontSize: "28px", fontWeight: "700", color: "#111827", margin: "0 0 4px 0", fontFamily: "Inter, system-ui, sans-serif" },
  sub: { color: "#6b7280", fontSize: "14px", margin: 0, fontFamily: "Inter, system-ui, sans-serif" },
  headerRight: { display: "flex", alignItems: "center", gap: "10px", flexWrap: "wrap", justifyContent: "flex-end" },
  filterGroup: { display: "flex", gap: "6px", alignItems: "center" },
  filterBtn: { padding: "7px 16px", borderRadius: "8px", border: "1.5px solid #e5e7eb", backgroundColor: "white", color: "#6b7280", fontSize: "13px", fontWeight: "500", cursor: "pointer", fontFamily: "Inter, system-ui, sans-serif" },
  filterBtnActive: { backgroundColor: "#1e3a8a", borderColor: "#1e3a8a", color: "white", fontWeight: "700" },
  addBtn: { backgroundColor: "#2563eb", color: "white", border: "none", borderRadius: "8px", padding: "10px 18px", fontSize: "14px", fontWeight: "600", cursor: "pointer", fontFamily: "Inter, system-ui, sans-serif" },
  deleteBtn: { backgroundColor: "#fef2f2", color: "#b91c1c", border: "1px solid #fca5a5", borderRadius: "8px", padding: "10px 18px", fontSize: "14px", fontWeight: "600", cursor: "pointer", fontFamily: "Inter, system-ui, sans-serif" },
  selectionCount: { fontSize: "14px", fontWeight: "600", color: "#374151", fontFamily: "Inter, system-ui, sans-serif" },
  deleteSelectedBtn: { backgroundColor: "#dc2626", color: "white", border: "none", borderRadius: "8px", padding: "10px 18px", fontSize: "14px", fontWeight: "600", cursor: "pointer", fontFamily: "Inter, system-ui, sans-serif" },
  cancelSelectBtn: { backgroundColor: "#f3f4f6", color: "#374151", border: "none", borderRadius: "8px", padding: "10px 18px", fontSize: "14px", fontWeight: "600", cursor: "pointer", fontFamily: "Inter, system-ui, sans-serif" },
  checkbox: { width: "16px", height: "16px", cursor: "pointer", accentColor: "#2563eb" },
  error: { backgroundColor: "#fef2f2", border: "1px solid #fca5a5", color: "#b91c1c", fontSize: "13px", padding: "10px 14px", borderRadius: "8px", marginBottom: "20px", fontFamily: "Inter, system-ui, sans-serif" },
  tableWrapper: { backgroundColor: "white", borderRadius: "14px", boxShadow: "0 4px 20px rgba(0,0,0,0.06)", overflow: "hidden", border: "1px solid #e5e7eb" },
  table: { width: "100%", borderCollapse: "collapse", fontFamily: "Inter, system-ui, sans-serif" },
  th: { padding: "14px 20px", textAlign: "left", fontSize: "11px", fontWeight: "700", color: "#6b7280", textTransform: "uppercase", letterSpacing: "0.6px", backgroundColor: "#f9fafb", borderBottom: "1px solid #e5e7eb" },
  td: { padding: "14px 20px", borderBottom: "1px solid #f3f4f6", verticalAlign: "middle" },
  loadingCell: { padding: "32px 20px", textAlign: "center", color: "#9ca3af", fontSize: "14px" },
  employeeCell: { display: "flex", alignItems: "center", gap: "10px" },
  avatar: { width: "34px", height: "34px", borderRadius: "50%", background: "linear-gradient(135deg, #1e3a8a, #2563eb)", color: "white", display: "flex", alignItems: "center", justifyContent: "center", fontWeight: "700", fontSize: "14px", flexShrink: 0 },
  avatarUnknown: { width: "34px", height: "34px", borderRadius: "50%", background: "#e5e7eb", color: "#9ca3af", display: "flex", alignItems: "center", justifyContent: "center", fontWeight: "700", fontSize: "14px", flexShrink: 0 },
  employeeName: { fontSize: "14px", fontWeight: "600", color: "#1e3a8a" },
  noName: { fontSize: "13px", color: "#9ca3af", fontStyle: "italic" },
  description: { fontSize: "14px", color: "#374151" },
  categoryBadge: { fontSize: "12px", fontWeight: "600", padding: "3px 10px", borderRadius: "20px", display: "inline-block" },
  tsDate: { fontSize: "13px", fontWeight: "600", color: "#111827" },
  tsTime: { fontSize: "12px", color: "#6b7280" },
  vehicleLabel: { fontSize: "13px", fontWeight: "600", color: "#111827" },
  receiptLink: { fontSize: "13px", fontWeight: "600", color: "#2563eb", textDecoration: "none" },
  amount: { fontSize: "14px", fontWeight: "700", color: "#111827" },
  pagination: { display: "flex", alignItems: "center", justifyContent: "flex-end", gap: "12px", padding: "14px 20px", borderTop: "1px solid #f3f4f6" },
  pageBtn: { padding: "7px 16px", borderRadius: "8px", border: "1.5px solid #e5e7eb", backgroundColor: "white", color: "#374151", fontSize: "13px", fontWeight: "600", cursor: "pointer", fontFamily: "Inter, system-ui, sans-serif" },
  pageBtnDisabled: { color: "#d1d5db", borderColor: "#f3f4f6", cursor: "not-allowed" },
  pageLabel: { fontSize: "13px", color: "#6b7280", fontFamily: "Inter, system-ui, sans-serif", minWidth: "50px", textAlign: "center" },
  overlay: { position: "fixed", inset: 0, backgroundColor: "rgba(0,0,0,0.4)", display: "flex", alignItems: "center", justifyContent: "center", zIndex: 1000 },
  modal: { backgroundColor: "white", borderRadius: "14px", padding: "32px", width: "420px", boxShadow: "0 20px 60px rgba(0,0,0,0.15)", display: "flex", flexDirection: "column", gap: "12px", maxHeight: "90vh", overflowY: "auto" },
  modalTitle: { fontSize: "20px", fontWeight: "700", color: "#111827", margin: 0, fontFamily: "Inter, system-ui, sans-serif" },
  formError: { backgroundColor: "#fef2f2", border: "1px solid #fca5a5", color: "#b91c1c", fontSize: "13px", padding: "8px 12px", borderRadius: "6px", fontFamily: "Inter, system-ui, sans-serif" },
  label: { fontSize: "13px", fontWeight: "600", color: "#374151", fontFamily: "Inter, system-ui, sans-serif", marginBottom: "-4px" },
  input: { border: "1px solid #d1d5db", borderRadius: "8px", padding: "10px 12px", fontSize: "14px", fontFamily: "Inter, system-ui, sans-serif", outline: "none", width: "100%", boxSizing: "border-box" },
  modalActions: { display: "flex", justifyContent: "flex-end", gap: "10px", marginTop: "8px" },
  cancelBtn: { backgroundColor: "#f3f4f6", color: "#374151", border: "none", borderRadius: "8px", padding: "10px 18px", fontSize: "14px", fontWeight: "600", cursor: "pointer", fontFamily: "Inter, system-ui, sans-serif" },
  saveBtn: { backgroundColor: "#2563eb", color: "white", border: "none", borderRadius: "8px", padding: "10px 18px", fontSize: "14px", fontWeight: "600", cursor: "pointer", fontFamily: "Inter, system-ui, sans-serif" },
};

import { useEffect, useState } from "react";
import { collection, getDocs, addDoc, deleteDoc, doc } from "firebase/firestore";
import { db } from "../firebase";
import { useAuth } from "../AuthContext";

export default function Employees() {
  const { businessId } = useAuth();
  const [employees, setEmployees] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [showModal, setShowModal] = useState(false);
  const [form, setForm] = useState({ username: "", name: "", email: "" });
  const [formError, setFormError] = useState("");
  const [saving, setSaving] = useState(false);
  const [selectMode, setSelectMode] = useState(false);
  const [selected, setSelected] = useState(new Set());
  const [deleting, setDeleting] = useState(false);

  const fetchEmployees = async () => {
    if (!businessId) {
      setLoading(false);
      return;
    }
    try {
      const snapshot = await getDocs(collection(db, "businesses", businessId, "employees"));
      const data = snapshot.docs.map((d) => ({ id: d.id, ...d.data() }));
      setEmployees(data);
    } catch (err) {
      setError("Failed to load employees.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchEmployees();
  }, [businessId]);

  const handleCreate = async () => {
    if (!form.username.trim() || !form.name.trim() || !form.email.trim()) {
      setFormError("All fields are required.");
      return;
    }
    setSaving(true);
    setFormError("");
    try {
      await addDoc(collection(db, "businesses", businessId, "employees"), {
        username: form.username.trim(),
        name: form.name.trim(),
        email: form.email.trim(),
      });
      setForm({ username: "", name: "", email: "" });
      setShowModal(false);
      await fetchEmployees();
    } catch (err) {
      setFormError("Failed to create employee.");
    } finally {
      setSaving(false);
    }
  };

  const toggleSelect = (id) => {
    setSelected((prev) => {
      const next = new Set(prev);
      next.has(id) ? next.delete(id) : next.add(id);
      return next;
    });
  };

  const toggleSelectAll = () => {
    if (selected.size === employees.length) {
      setSelected(new Set());
    } else {
      setSelected(new Set(employees.map((e) => e.id)));
    }
  };

  const handleDeleteSelected = async () => {
    if (selected.size === 0) return;
    if (!window.confirm(`Delete ${selected.size} employee(s)?`)) return;
    setDeleting(true);
    try {
      await Promise.all([...selected].map((id) => deleteDoc(doc(db, "businesses", businessId, "employees", id))));
      setEmployees((prev) => prev.filter((emp) => !selected.has(emp.id)));
      setSelected(new Set());
      setSelectMode(false);
    } catch (err) {
      setError("Failed to delete selected employees.");
    } finally {
      setDeleting(false);
    }
  };

  const exitSelectMode = () => {
    setSelectMode(false);
    setSelected(new Set());
  };

  const allSelected = employees.length > 0 && selected.size === employees.length;
  const colSpan = selectMode ? 4 : 3;

  return (
    <div>
      <div style={styles.header}>
        <div>
          <h1 style={styles.heading}>Employees</h1>
          <p style={styles.sub}>{loading ? "Loading..." : `${employees.length} team members`}</p>
        </div>
        <div style={styles.headerActions}>
          {selectMode ? (
            <>
              <span style={styles.selectionCount}>
                {selected.size} selected
              </span>
              <button
                style={styles.deleteSelectedBtn}
                onClick={handleDeleteSelected}
                disabled={selected.size === 0 || deleting}
              >
                {deleting ? "Deleting..." : "Delete Selected"}
              </button>
              <button style={styles.cancelSelectBtn} onClick={exitSelectMode}>
                Cancel
              </button>
            </>
          ) : (
            <>
              <button style={styles.deleteBtn} onClick={() => setSelectMode(true)}>
                Delete
              </button>
              <button style={styles.addBtn} onClick={() => { setShowModal(true); setFormError(""); }}>
                + Add Employee
              </button>
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
                  <input
                    type="checkbox"
                    checked={allSelected}
                    onChange={toggleSelectAll}
                    style={styles.checkbox}
                  />
                </th>
              )}
              <th style={styles.th}>Username</th>
              <th style={styles.th}>Name</th>
              <th style={styles.th}>Email</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={colSpan} style={styles.loadingCell}>Loading employees...</td>
              </tr>
            ) : employees.length === 0 ? (
              <tr>
                <td colSpan={colSpan} style={styles.loadingCell}>No employees found.</td>
              </tr>
            ) : (
              employees.map((emp, i) => {
                const isSelected = selected.has(emp.id);
                return (
                  <tr
                    key={emp.id}
                    style={{
                      backgroundColor: isSelected
                        ? "#eff6ff"
                        : i % 2 === 0 ? "white" : "#f8faff",
                      cursor: selectMode ? "pointer" : "default",
                    }}
                    onClick={selectMode ? () => toggleSelect(emp.id) : undefined}
                  >
                    {selectMode && (
                      <td style={styles.td}>
                        <input
                          type="checkbox"
                          checked={isSelected}
                          onChange={() => toggleSelect(emp.id)}
                          onClick={(e) => e.stopPropagation()}
                          style={styles.checkbox}
                        />
                      </td>
                    )}
                    <td style={styles.td}>
                      <div style={styles.usernameCell}>
                        <div style={styles.avatar}>
                          {(emp.name || emp.username || "?").charAt(0).toUpperCase()}
                        </div>
                        <span style={styles.username}>@{emp.username}</span>
                      </div>
                    </td>
                    <td style={styles.td}>
                      <span style={styles.name}>{emp.name}</span>
                    </td>
                    <td style={styles.td}>
                      <span style={styles.email}>{emp.email}</span>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      {showModal && (
        <div style={styles.overlay}>
          <div style={styles.modal}>
            <h2 style={styles.modalTitle}>Add Employee</h2>
            {formError && <div style={styles.formError}>{formError}</div>}
            <label style={styles.label}>Username</label>
            <input
              style={styles.input}
              placeholder="e.g. jsmith"
              value={form.username}
              onChange={(e) => setForm({ ...form, username: e.target.value })}
            />
            <label style={styles.label}>Name</label>
            <input
              style={styles.input}
              placeholder="e.g. John Smith"
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
            />
            <label style={styles.label}>Email</label>
            <input
              style={styles.input}
              placeholder="e.g. john@example.com"
              value={form.email}
              onChange={(e) => setForm({ ...form, email: e.target.value })}
            />
            <div style={styles.modalActions}>
              <button style={styles.cancelBtn} onClick={() => { setShowModal(false); setForm({ username: "", name: "", email: "" }); }}>
                Cancel
              </button>
              <button style={styles.saveBtn} onClick={handleCreate} disabled={saving}>
                {saving ? "Saving..." : "Save"}
              </button>
            </div>
          </div>
        </div>
      )}
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
  headerActions: {
    display: "flex",
    alignItems: "center",
    gap: "10px",
  },
  addBtn: {
    backgroundColor: "#2563eb",
    color: "white",
    border: "none",
    borderRadius: "8px",
    padding: "10px 18px",
    fontSize: "14px",
    fontWeight: "600",
    cursor: "pointer",
    fontFamily: "Inter, system-ui, sans-serif",
  },
  deleteBtn: {
    backgroundColor: "#fef2f2",
    color: "#b91c1c",
    border: "1px solid #fca5a5",
    borderRadius: "8px",
    padding: "10px 18px",
    fontSize: "14px",
    fontWeight: "600",
    cursor: "pointer",
    fontFamily: "Inter, system-ui, sans-serif",
  },
  selectionCount: {
    fontSize: "14px",
    fontWeight: "600",
    color: "#374151",
    fontFamily: "Inter, system-ui, sans-serif",
  },
  deleteSelectedBtn: {
    backgroundColor: "#dc2626",
    color: "white",
    border: "none",
    borderRadius: "8px",
    padding: "10px 18px",
    fontSize: "14px",
    fontWeight: "600",
    cursor: "pointer",
    fontFamily: "Inter, system-ui, sans-serif",
    opacity: 1,
  },
  cancelSelectBtn: {
    backgroundColor: "#f3f4f6",
    color: "#374151",
    border: "none",
    borderRadius: "8px",
    padding: "10px 18px",
    fontSize: "14px",
    fontWeight: "600",
    cursor: "pointer",
    fontFamily: "Inter, system-ui, sans-serif",
  },
  checkbox: {
    width: "16px",
    height: "16px",
    cursor: "pointer",
    accentColor: "#2563eb",
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
  usernameCell: {
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
  username: {
    fontSize: "14px",
    fontWeight: "600",
    color: "#1e3a8a",
  },
  name: {
    fontSize: "14px",
    fontWeight: "500",
    color: "#111827",
  },
  email: {
    fontSize: "14px",
    color: "#6b7280",
  },
  overlay: {
    position: "fixed",
    inset: 0,
    backgroundColor: "rgba(0,0,0,0.4)",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    zIndex: 1000,
  },
  modal: {
    backgroundColor: "white",
    borderRadius: "14px",
    padding: "32px",
    width: "400px",
    boxShadow: "0 20px 60px rgba(0,0,0,0.15)",
    display: "flex",
    flexDirection: "column",
    gap: "12px",
  },
  modalTitle: {
    fontSize: "20px",
    fontWeight: "700",
    color: "#111827",
    margin: 0,
    fontFamily: "Inter, system-ui, sans-serif",
  },
  formError: {
    backgroundColor: "#fef2f2",
    border: "1px solid #fca5a5",
    color: "#b91c1c",
    fontSize: "13px",
    padding: "8px 12px",
    borderRadius: "6px",
    fontFamily: "Inter, system-ui, sans-serif",
  },
  label: {
    fontSize: "13px",
    fontWeight: "600",
    color: "#374151",
    fontFamily: "Inter, system-ui, sans-serif",
    marginBottom: "-4px",
  },
  input: {
    border: "1px solid #d1d5db",
    borderRadius: "8px",
    padding: "10px 12px",
    fontSize: "14px",
    fontFamily: "Inter, system-ui, sans-serif",
    outline: "none",
  },
  modalActions: {
    display: "flex",
    justifyContent: "flex-end",
    gap: "10px",
    marginTop: "8px",
  },
  cancelBtn: {
    backgroundColor: "#f3f4f6",
    color: "#374151",
    border: "none",
    borderRadius: "8px",
    padding: "10px 18px",
    fontSize: "14px",
    fontWeight: "600",
    cursor: "pointer",
    fontFamily: "Inter, system-ui, sans-serif",
  },
  saveBtn: {
    backgroundColor: "#2563eb",
    color: "white",
    border: "none",
    borderRadius: "8px",
    padding: "10px 18px",
    fontSize: "14px",
    fontWeight: "600",
    cursor: "pointer",
    fontFamily: "Inter, system-ui, sans-serif",
  },
};

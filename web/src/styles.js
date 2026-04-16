// styles.js
export const authStyles = {
    container: {
        height: "100vh",
        display: "flex",
        justifyContent: "center",
        alignItems: "center",
        background: "linear-gradient(135deg,#e8edf7,#f4f6fb)",
        fontFamily: "Inter, sans-serif"
    },
    card: {
        display: "flex",
        width: "900px",
        borderRadius: "20px",
        overflow: "hidden",
        boxShadow: "0 25px 60px rgba(0,0,0,0.12)"
    },
    leftSection: {
        width: "380px",
        background: "linear-gradient(160deg,#1e3a8a,#2563eb)",
        padding: "60px",
        color: "white",
        display: "flex",
        flexDirection: "column",
        justifyContent: "center"
    },
    logoMark: { fontSize: "40px", marginBottom: "20px" },
    title: { fontSize: "36px", fontWeight: "800", marginBottom: "15px" },
    subtitle: { fontSize: "15px", opacity: 0.85 },
    rightSection: {
        flex: 1,
        padding: "60px",
        background: "white",
        display: "flex",
        flexDirection: "column",
        justifyContent: "center"
    },
    formTitle: { fontSize: "26px", fontWeight: "700" },
    formSubtitle: { marginBottom: "30px", color: "#6b7280" },
    form: { display: "flex", flexDirection: "column" },
    label: { fontSize: "13px", fontWeight: "600", marginBottom: "5px" },
    input: {
        padding: "12px",
        marginBottom: "18px",
        borderRadius: "10px",
        border: "1px solid #e5e7eb",
        background: "#f9fafb"
    },
    button: {
        padding: "13px",
        borderRadius: "10px",
        border: "none",
        background: "linear-gradient(135deg,#1e3a8a,#2563eb)",
        color: "white",
        fontWeight: "700",
        cursor: "pointer"
    },
    linkRow: { marginTop: "12px", fontSize: "13px", textAlign: "center" },
    link: { color: "#2563eb", fontWeight: "600", cursor: "pointer" },
    error: {
        background: "#fef2f2",
        padding: "10px",
        borderRadius: "8px",
        marginBottom: "10px",
        color: "#b91c1c"
    },
    success: {
        background: "#ecfdf5",
        padding: "10px",
        borderRadius: "8px",
        marginBottom: "10px",
        color: "#065f46"
    }
};
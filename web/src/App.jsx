// Reference React client — one Skill on the web surface via the Agent API.
// Renders the structured order-status Response as an SLDS-styled card (you own the UI;
// the API returns data). Inline styles only — no SLDS CSS dependency (kept dependency-light).
import { useState } from "react";
import { startSession, sendMessage, endSession, lookupOrder } from "./agentApi.js";

const agentId = import.meta.env.VITE_AGENT_ID;
const myDomain = import.meta.env.VITE_SF_MYDOMAIN;

// SLDS-ish palette (from the workshop style conventions)
const C = {
  brand: "#0176d3", brandDark: "#014486", navy: "#032d60", slate: "#444444",
  border: "#e5e5e5", panel: "#f3f3f3", tint: "#eef4ff", white: "#ffffff",
  green: "#2e7d32", amber: "#e65100", red: "#c62828", greyText: "#5c5c5c",
};
const FONT = "'Salesforce Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif";

// Map an order status to an SLDS-style badge colour.
function statusColor(s) {
  const v = (s || "").toLowerCase();
  if (v.includes("deliver")) return C.green;
  if (v.includes("ship")) return C.brand;
  if (v.includes("exception")) return C.red;
  if (v.includes("process")) return C.amber;
  return C.slate;
}
// Read the Skill's STRUCTURED output off the Agent API response — the reliable source of
// truth (the API returns data; you render the UI). The agent's prose intentionally carries
// no status detail (v4 calls show_command instead), so we read result[0].value(.card).
// Falls back to scraping prose only if no structured action output is present.
function extractOrder(resp, query) {
  const value = resp?.messages?.[0]?.result?.[0]?.value;
  const c = value?.card || value; // prefer the card object; else the flat value
  if (c && (c.status || c.orderNumber)) {
    return {
      order: c.orderNumber || null,
      status: c.status || null,
      summary: c.summary || null,
      recordId: c.recordId || null,
    };
  }
  // fallback: no structured output — scrape the prose
  const msg = resp?.messages?.[0]?.message ?? "";
  const status = (msg.match(/\b(Processing|Shipped|Delivered|Exception)\b/i) || [])[0] || null;
  const order =
    (msg.match(/\bOR-\d+\b/) || [])[0] ||
    (query.match(/\bOR-\d+\b/i) || [])[0] || null;
  return { order, status, summary: null, recordId: null };
}

export default function App() {
  const [q, setQ] = useState("What is the status of order OR-1003?");
  const [resp, setResp] = useState(null);
  const [recordUrl, setRecordUrl] = useState(null);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState(null);

  async function ask() {
    setBusy(true); setErr(null); setResp(null); setRecordUrl(null);
    let sessionId;
    try {
      ({ sessionId } = await startSession({ agentId, myDomain }));
      const r = await sendMessage({ sessionId, text: q });
      setResp(r);
      // Resolve the record link. The structured output usually carries recordId directly;
      // fall back to the /lookup SOQL path by order number if it doesn't.
      const { order: orderNum, recordId } = extractOrder(r, q);
      if (recordId) {
        setRecordUrl(`${myDomain}/lightning/r/Order__c/${recordId}/view`);
      } else if (orderNum) {
        lookupOrder(orderNum).then((x) => setRecordUrl(x.recordUrl));
      }
    } catch (e) {
      setErr(e.message);
    } finally {
      if (sessionId) await endSession({ sessionId }).catch(() => {});
      setBusy(false);
    }
  }

  const prose = resp?.messages?.[0]?.message ?? "";
  const { status, order, summary } = resp ? extractOrder(resp, q) : {};
  // Prefer the Skill's structured summary; fall back to the agent's prose.
  const message = summary || prose;

  return (
    <div style={{ fontFamily: FONT, background: C.panel, minHeight: "100vh", padding: "2rem 1rem" }}>
      <main style={{ maxWidth: 620, margin: "0 auto" }}>
        <div style={{ fontSize: "0.68rem", letterSpacing: "0.1em", textTransform: "uppercase", color: C.slate }}>
          Headless 360 · Web surface
        </div>
        <h1 style={{ color: C.navy, fontSize: "1.5rem", fontWeight: 700, margin: "2px 0 16px" }}>Order Assistant</h1>

        {/* Ask box */}
        <div style={{ display: "flex", gap: 8 }}>
          <input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && !busy && ask()}
            placeholder="Ask about an order, e.g. OR-1003"
            style={{ flex: 1, padding: "8px 12px", border: `1px solid ${C.border}`, borderRadius: 4, fontSize: "0.95rem", fontFamily: FONT }}
          />
          <button
            onClick={ask}
            disabled={busy}
            style={{ background: busy ? C.brandDark : C.brand, color: C.white, border: 0, padding: "8px 18px", borderRadius: 4, fontWeight: 600, cursor: busy ? "default" : "pointer", fontFamily: FONT }}
          >
            {busy ? "Asking…" : "Ask the agent"}
          </button>
        </div>

        {err && (
          <div style={{ marginTop: 16, background: "#fef1f1", border: `1px solid ${C.red}`, borderRadius: 6, padding: 12, color: C.red, fontSize: "0.9rem" }}>
            {err}
          </div>
        )}

        {/* SLDS-style record card */}
        {resp && (
          <div style={{ marginTop: 16, background: C.white, border: `1px solid ${C.border}`, borderRadius: 8, boxShadow: "0 2px 4px rgba(0,0,0,0.07)", overflow: "hidden" }}>
            {/* card header */}
            <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "12px 16px", borderBottom: `1px solid ${C.border}` }}>
              <div style={{ width: 30, height: 30, borderRadius: 6, background: C.brand, color: C.white, display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 700, fontSize: "0.9rem" }}>◱</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: "0.7rem", letterSpacing: "0.06em", textTransform: "uppercase", color: C.greyText }}>Order</div>
                <div style={{ color: C.navy, fontWeight: 700, fontSize: "1rem", lineHeight: 1.1 }}>{order || "Order status"}</div>
              </div>
              {status && (
                <span style={{ background: statusColor(status), color: C.white, fontSize: "0.72rem", fontWeight: 600, padding: "3px 10px", borderRadius: 999, textTransform: "uppercase", letterSpacing: "0.04em" }}>
                  {status}
                </span>
              )}
            </div>
            {/* card body — the agent's response */}
            <div style={{ padding: "16px" }}>
              <div style={{ fontSize: "0.68rem", letterSpacing: "0.1em", textTransform: "uppercase", color: C.slate, marginBottom: 6 }}>Agent response</div>
              <div style={{ color: C.navy, fontSize: "0.98rem", lineHeight: 1.5 }}>{message || "(no message in response)"}</div>
            </div>
            {/* footer — deep link to the record (parity with the Slack card) */}
            <div style={{ padding: "10px 16px", background: C.tint, borderTop: `1px solid ${C.border}`, display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12 }}>
              <span style={{ fontSize: "0.75rem", color: C.slate }}>Rendered from the headless Agent API — no Salesforce UI.</span>
              {recordUrl && (
                <a href={recordUrl} target="_blank" rel="noreferrer"
                  style={{ background: C.white, color: C.brand, border: `1px solid ${C.brand}`, borderRadius: 4, padding: "5px 12px", fontSize: "0.82rem", fontWeight: 600, textDecoration: "none", whiteSpace: "nowrap" }}>
                  View in Salesforce ↗
                </a>
              )}
            </div>
          </div>
        )}

        {/* Raw JSON below — the teaching moment: exactly what the Agent API returned. */}
        {resp && (
          <details style={{ marginTop: 12 }}>
            <summary style={{ cursor: "pointer", color: C.slate, fontSize: "0.85rem" }}>Raw Agent API response (JSON)</summary>
            <pre style={{ background: "#f8fafc", border: `1px solid ${C.border}`, borderRadius: 6, padding: 12, marginTop: 8, whiteSpace: "pre-wrap", fontSize: "0.78rem", color: "#181818" }}>
              {JSON.stringify(resp, null, 2)}
            </pre>
          </details>
        )}
      </main>
    </div>
  );
}

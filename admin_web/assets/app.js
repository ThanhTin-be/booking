// ─── API helpers ──────────────────────────────────────────────────────────────
function computeDefaultApiBaseUrl() {
  const { origin, port, pathname, hostname, protocol } = window.location;
  if (pathname.startsWith("/admin")) return origin;
  if (port && port !== "3000") return `${protocol}//${hostname}:3000`;
  return origin;
}
const DEFAULT_API_BASE_URL = computeDefaultApiBaseUrl();

function normalizeAdminApiBaseUrl(url) {
  return String(url || "").trim().replace(/\/$/, "").replace(/\/api$/, "");
}
function getApiBaseUrl() {
  const stored = (localStorage.getItem("ADMIN_API_BASE_URL") || "").trim();
  const ns = normalizeAdminApiBaseUrl(stored);
  const nd = normalizeAdminApiBaseUrl(DEFAULT_API_BASE_URL);
  const uiOrigin = normalizeAdminApiBaseUrl(window.location.origin);
  const servedByBackend = window.location.pathname.startsWith("/admin");
  if (!servedByBackend && ns && ns === uiOrigin) return nd;
  return (ns || nd).replace(/\/$/, "");
}
function setApiBaseUrl(url) { localStorage.setItem("ADMIN_API_BASE_URL", normalizeAdminApiBaseUrl(url)); }
function getToken() { return localStorage.getItem("ADMIN_TOKEN") || ""; }
function setToken(t) { localStorage.setItem("ADMIN_TOKEN", t || ""); }
function clearAuth() { localStorage.removeItem("ADMIN_TOKEN"); }

async function parseJsonSafe(res) {
  const text = await res.text();
  if (!text) return null;
  try { return JSON.parse(text); } catch { return { raw: text }; }
}

async function apiFetch(path, { method = "GET", query, body, formData, headers } = {}) {
  const base = getApiBaseUrl();
  const url = new URL(`${base}${path.startsWith("/") ? "" : "/"}${path}`);
  if (query) for (const [k, v] of Object.entries(query)) {
    if (v === undefined || v === null || v === "") continue;
    url.searchParams.set(k, String(v));
  }
  const token = getToken();
  const isFormData = formData instanceof FormData;
  const res = await fetch(url.toString(), {
    method,
    headers: {
      ...(body && !isFormData ? { "Content-Type": "application/json" } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(headers || {}),
    },
    body: isFormData ? formData : (body ? JSON.stringify(body) : undefined),
  });
  const data = await parseJsonSafe(res);
  if (!res.ok) {
    const err = new Error(data?.message || `HTTP ${res.status}`);
    err.status = res.status; err.data = data;
    throw err;
  }
  return data;
}

async function loginAsAdmin({ email, password }) {
  const data = await apiFetch("/api/auth/login", { method: "POST", body: { email, password } });
  const token = data?.token || "";
  if (!token) throw new Error("Login failed: missing token");
  if (data?.user?.role !== "admin") throw new Error("Tài khoản này không có quyền admin");
  setToken(token);
  return data;
}

// ─── Icons ────────────────────────────────────────────────────────────────────
const icons = {
  dashboard: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/></svg>`,
  users:     `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>`,
  courts:    `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>`,
  bookings:  `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>`,
  payments:  `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>`,
  discounts: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"/><line x1="7" y1="7" x2="7.01" y2="7"/></svg>`,
  settings:  `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>`,
  refresh:   `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg>`,
  logout:    `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>`,
  plus:      `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>`,
  edit:      `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>`,
  trash:     `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg>`,
  x:         `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>`,
  wallet:    `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><path d="M1 10h22"/><circle cx="18" cy="15" r="1"/></svg>`,
  search:    `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>`,
  chevRight: `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 18 15 12 9 6"/></svg>`,
  menu:      `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="18" x2="21" y2="18"/></svg>`,
  bell:      `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>`,
  trophy:    `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6"/><path d="M18 9h1.5a2.5 2.5 0 0 0 0-5H18"/><path d="M4 22h16"/><path d="M10 22V14a2 2 0 0 1 4 0v8"/><path d="M6 2h12v7a6 6 0 0 1-12 0V2z"/></svg>`,
};

const routes = [
  { id: "dashboard", label: "Dashboard",  icon: icons.dashboard },
  { id: "users",     label: "Users",       icon: icons.users },
  { id: "courts",    label: "Courts",      icon: icons.courts },
  { id: "bookings",  label: "Bookings",    icon: icons.bookings },
  { id: "payments",  label: "Payments",    icon: icons.payments },
  { id: "discounts", label: "Discounts",   icon: icons.discounts },
  { id: "wallets",   label: "Wallets",     icon: icons.wallet },
  { id: "settings",  label: "Settings",    icon: icons.settings },
];

// ─── Helpers ──────────────────────────────────────────────────────────────────
function h(html) {
  const t = document.createElement("template");
  t.innerHTML = html.trim();
  return t.content.firstElementChild;
}
function qs(sel, root = document) { return root.querySelector(sel); }
function escapeHtml(s) {
  return String(s ?? "")
    .replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;").replaceAll("'", "&#039;");
}
function formatMoney(v) { return Number(v || 0).toLocaleString("vi-VN") + "đ"; }
function getGreeting() {
  const h = new Date().getHours();
  if (h < 12) return "Chào buổi sáng";
  if (h < 18) return "Chào buổi chiều";
  return "Chào buổi tối";
}
function formatDateVN() {
  return new Date().toLocaleDateString("vi-VN", { weekday: "long", year: "numeric", month: "long", day: "numeric" });
}

// ─── Badge ────────────────────────────────────────────────────────────────────
function badge(text, tone = "slate") {
  const tones = {
    slate:  { bg: "#f1f3f9", color: "#5a6384", dot: "#8b93a8" },
    green:  { bg: "#ecfdf5", color: "#059669", dot: "#10b981" },
    red:    { bg: "#fef2f2", color: "#dc2626", dot: "#ef4444" },
    amber:  { bg: "#fffbeb", color: "#d97706", dot: "#f59e0b" },
    blue:   { bg: "#eff6ff", color: "#2563eb", dot: "#3b82f6" },
    purple: { bg: "#f5f3ff", color: "#7c3aed", dot: "#8b5cf6" },
  };
  const t = tones[tone] || tones.slate;
  return `<span class="badge" style="background:${t.bg};color:${t.color};">
    <span class="badge-dot" style="background:${t.dot};"></span>
    ${escapeHtml(text)}
  </span>`;
}

function statusBadge(kind, value) {
  const v = String(value || "").toLowerCase();
  const map = {
    booking:  { pending: ["Pending","amber"], confirmed: ["Confirmed","green"], cancelled: ["Cancelled","red"], completed: ["Completed","blue"] },
    user:     { active: ["Active","green"], locked: ["Locked","red"] },
    payment:  { pending: ["Pending","amber"], completed: ["Completed","green"], failed: ["Failed","red"], refunded: ["Refunded","purple"] },
    discount: { active: ["Active","green"], expired: ["Expired","amber"], disabled: ["Disabled","red"] },
    court:    { active: ["Active","green"], maintenance: ["Maintenance","amber"] },
  };
  const conf = map[kind]?.[v] || [v || "-", "slate"];
  return badge(conf[0], conf[1]);
}

// ─── Routing ──────────────────────────────────────────────────────────────────
function currentRouteId() {
  const hash = window.location.hash || "#/dashboard";
  const id = hash.replace("#/", "").split("?")[0] || "dashboard";
  return routes.some((r) => r.id === id) ? id : "dashboard";
}
function setRoute(id) { window.location.hash = `#/${id}`; }

// ─── Modal system ─────────────────────────────────────────────────────────────
function openModal({ title, body, onConfirm, confirmLabel = "Lưu", confirmClass = "btn-primary", size = "480px" }) {
  const existing = document.getElementById("globalModal");
  if (existing) existing.remove();

  const modal = h(`
    <div id="globalModal" class="modal-overlay">
      <div class="modal-container" style="max-width:${size};">
        <div style="padding:22px 28px 0;display:flex;align-items:center;justify-content:space-between;">
          <div style="font-size:16px;font-weight:800;color:var(--text-primary);letter-spacing:-0.02em;">${title}</div>
          <button id="modalClose" style="background:none;border:none;cursor:pointer;color:var(--text-muted);padding:6px;border-radius:8px;display:flex;align-items:center;justify-content:center;transition:all var(--transition-fast);" onmouseover="this.style.background='var(--surface-hover)'" onmouseout="this.style.background='none'">${icons.x}</button>
        </div>
        <div style="padding:22px 28px;max-height:70vh;overflow-y:auto;" id="modalBody">${body}</div>
        ${onConfirm ? `<div style="padding:0 28px 22px;display:flex;gap:10px;justify-content:flex-end;">
          <button id="modalCancel" class="btn-ghost">Huỷ</button>
          <button id="modalConfirm" class="${confirmClass}">${confirmLabel}</button>
        </div>` : `<div style="padding:0 28px 22px;display:flex;justify-content:flex-end;"><button id="modalCancel" class="btn-ghost">Đóng</button></div>`}
      </div>
    </div>
  `);

  document.body.appendChild(modal);
  const close = () => modal.remove();
  qs("#modalClose", modal).onclick = close;
  qs("#modalCancel", modal).onclick = close;
  modal.addEventListener("click", (e) => { if (e.target === modal) close(); });

  if (onConfirm) {
    qs("#modalConfirm", modal).onclick = async () => {
      const btn = qs("#modalConfirm", modal);
      btn.disabled = true;
      btn.textContent = "Đang xử lý…";
      try {
        await onConfirm(modal);
        close();
      } catch (err) {
        toast("error", "Lỗi", err.message);
        btn.disabled = false;
        btn.textContent = confirmLabel;
      }
    };
  }
  return modal;
}

function confirmDialog(title, message, onConfirm) {
  openModal({
    title,
    body: `<p style="color:var(--text-secondary);font-size:14px;margin:0;line-height:1.6;">${escapeHtml(message)}</p>`,
    onConfirm,
    confirmLabel: "Xác nhận",
    confirmClass: "btn-danger",
  });
}

// ─── Toast ────────────────────────────────────────────────────────────────────
function toast(type, title, detail) {
  const host = qs("#toastHost");
  if (!host) return;
  const styles = {
    error:   { bg: "#fef2f2", border: "#fecaca", color: "#dc2626", icon: "✗" },
    success: { bg: "#ecfdf5", border: "#a7f3d0", color: "#059669", icon: "✓" },
    info:    { bg: "#eff6ff", border: "#bfdbfe", color: "#2563eb", icon: "i" },
  };
  const s = styles[type] || styles.info;
  const el = h(`<div class="toast-item" style="background:${s.bg};border:1px solid ${s.border};color:${s.color};">
    <div style="display:flex;align-items:flex-start;gap:12px;">
      <span style="width:22px;height:22px;border-radius:50%;background:${s.color};color:#fff;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:800;flex-shrink:0;margin-top:1px;">${s.icon}</span>
      <div style="flex:1;"><div style="font-weight:700;font-size:13.5px;">${escapeHtml(title)}</div>${detail ? `<div style="font-size:12.5px;opacity:0.85;margin-top:3px;">${escapeHtml(detail)}</div>` : ""}</div>
    </div>
  </div>`);
  host.appendChild(el);
  setTimeout(() => { el.style.transition = "opacity 0.3s, transform 0.3s"; el.style.opacity = "0"; el.style.transform = "translateX(20px)"; setTimeout(() => el.remove(), 300); }, 3500);
}


// ─── Layout components ───────────────────────────────────────────────────────
const metricThemes = [
  { bg: "#6366f1", light: "rgba(99,102,241,0.1)", gradient: "linear-gradient(90deg, #6366f1, #818cf8)", glyph: "📋" },
  { bg: "#10b981", light: "rgba(16,185,129,0.1)", gradient: "linear-gradient(90deg, #10b981, #34d399)", glyph: "💰" },
  { bg: "#f59e0b", light: "rgba(245,158,11,0.1)", gradient: "linear-gradient(90deg, #f59e0b, #fbbf24)", glyph: "👤" },
  { bg: "#3b82f6", light: "rgba(59,130,246,0.1)", gradient: "linear-gradient(90deg, #3b82f6, #60a5fa)", glyph: "🏟️" },
];

function renderCardGrid(cards) {
  return `<div class="metrics-grid">
    ${cards.map((c, i) => {
      const t = metricThemes[i % metricThemes.length];
      return `<div class="metric-card" style="--card-gradient:${t.gradient};">
        <div class="metric-card-icon" style="background:${t.light};">
          <span style="font-size:20px;">${t.glyph}</span>
        </div>
        <div class="metric-card-label">${escapeHtml(c.label)}</div>
        <div class="metric-card-value">${escapeHtml(c.value)}</div>
        ${c.hint ? `<div class="metric-card-hint">${escapeHtml(c.hint)}</div>` : ""}
      </div>`;
    }).join("")}
  </div>`;
}

function renderTable({ columns, rows, rowKey }) {
  if (!rows || rows.length === 0) {
    return `<div class="admin-card">
      <div class="empty-state">
        <div class="empty-state-icon">📭</div>
        <div class="empty-state-text">Không có dữ liệu</div>
      </div>
    </div>`;
  }
  return `<div class="admin-card"><div style="overflow-x:auto;">
    <table class="admin-table">
      <thead><tr>${columns.map((c) => `<th>${escapeHtml(c.label)}</th>`).join("")}</tr></thead>
      <tbody>
        ${rows.map((r) => {
          const key = rowKey ? rowKey(r) : r?.id || r?._id || Math.random();
          return `<tr data-rowkey="${escapeHtml(key)}">${columns.map((c) => `<td>${c.render(r)}</td>`).join("")}</tr>`;
        }).join("")}
      </tbody>
    </table>
  </div></div>`;
}

function renderPagination({ page, totalPages, total, limit, onPageChange }) {
  if (!totalPages || totalPages <= 1) return '';
  const from = (page - 1) * limit + 1;
  const to = Math.min(page * limit, total);
  const pages = [];
  const addPage = (p) => { if (!pages.includes(p)) pages.push(p); };
  addPage(1);
  for (let i = Math.max(2, page - 1); i <= Math.min(totalPages - 1, page + 1); i++) addPage(i);
  if (totalPages > 1) addPage(totalPages);

  let btns = '';
  btns += `<button class="pagination-btn" data-page="${page - 1}" ${page <= 1 ? 'disabled' : ''}>‹</button>`;
  let last = 0;
  for (const p of pages) {
    if (p - last > 1) btns += `<span class="pagination-ellipsis">…</span>`;
    btns += `<button class="pagination-btn${p === page ? ' active' : ''}" data-page="${p}">${p}</button>`;
    last = p;
  }
  btns += `<button class="pagination-btn" data-page="${page + 1}" ${page >= totalPages ? 'disabled' : ''}>›</button>`;

  const id = 'pg_' + Math.random().toString(36).slice(2, 8);
  setTimeout(() => {
    const el = document.getElementById(id);
    if (!el) return;
    el.addEventListener('click', (e) => {
      const btn = e.target.closest('button[data-page]');
      if (!btn || btn.disabled) return;
      onPageChange(Number(btn.dataset.page));
    });
  }, 0);

  return `<div id="${id}" class="pagination-bar">
    <span class="pagination-info">Hiển thị ${from}–${to} trên ${total} kết quả</span>
    <div class="pagination-controls">${btns}</div>
  </div>`;
}

function field(label, inputHtml) {
  return `<div style="display:flex;flex-direction:column;gap:6px;">
    <label style="font-size:11.5px;font-weight:700;color:var(--text-muted);text-transform:uppercase;letter-spacing:0.06em;">${escapeHtml(label)}</label>
    ${inputHtml}
  </div>`;
}
function inp(id, type = "text", value = "", placeholder = "") {
  return `<input id="${id}" type="${type}" class="admin-input" value="${escapeHtml(value)}" placeholder="${escapeHtml(placeholder)}" />`;
}
function sel(id, options, current) {
  return `<select id="${id}" class="admin-select">${options.map(([v, l]) => `<option value="${escapeHtml(v)}" ${v === current ? "selected" : ""}>${escapeHtml(l)}</option>`).join("")}</select>`;
}

// ─── Auth ─────────────────────────────────────────────────────────────────────
async function ensureAuthed() {
  if (getToken()) return true;
  qs("#loginModal").style.display = "flex";
  return false;
}
function closeLogin() { qs("#loginModal").style.display = "none"; }

// ─── Layout ───────────────────────────────────────────────────────────────────
function layout() {
  const routeId = currentRouteId();
  const token = getToken();
  const mainRoutes = routes.filter((r) => r.id !== "settings");
  const currentRoute = routes.find((r) => r.id === routeId);

  return `
  <div style="display:flex;min-height:100vh;">
    <aside id="sidebar">
      <div class="sidebar-logo">
        <div class="sidebar-logo-icon">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/><line x1="2" y1="12" x2="22" y2="12"/></svg>
        </div>
        <div class="sidebar-logo-text">
          <h1>Booking Admin</h1>
          <span>${escapeHtml(getApiBaseUrl().replace(/https?:\/\//, ""))}</span>
        </div>
      </div>

      <div class="sidebar-section-label">Main Menu</div>
      <nav>
        ${mainRoutes.map((r) => `<a href="#/${r.id}" class="nav-item${r.id === routeId ? " active" : ""}">
          <span class="nav-icon">${r.icon}</span>
          <span class="nav-label">${escapeHtml(r.label)}</span>
        </a>`).join("")}
      </nav>

      <div class="sidebar-divider"></div>
      <div class="sidebar-section-label">System</div>
      <nav>
        <a href="#/settings" class="nav-item${routeId === "settings" ? " active" : ""}">
          <span class="nav-icon">${icons.settings}</span>
          <span class="nav-label">Settings</span>
        </a>
      </nav>

      <div class="sidebar-user">
        <div style="display:flex;align-items:center;gap:12px;">
          <div class="sidebar-user-avatar">A</div>
          <div style="flex:1;min-width:0;">
            <div style="font-size:13px;font-weight:700;color:#fff;">Administrator</div>
            <div style="font-size:11px;color:rgba(255,255,255,0.35);margin-top:2px;">Super Admin</div>
          </div>
        </div>
      </div>
    </aside>

    <main id="mainContent">
      <header id="topbar">
        <div class="topbar-left">
          <button id="btnSidebarToggle" class="topbar-btn" style="display:none;padding:8px 10px;">${icons.menu}</button>
          <div>
            <div class="route-title">${escapeHtml(currentRoute?.label || "Dashboard")}</div>
            <div class="route-subtitle" id="subTitle"></div>
          </div>
        </div>
        <div class="topbar-right">
          <span class="status-pill">Live</span>
          <button id="btnRefresh" class="topbar-btn">${icons.refresh}<span>Refresh</span></button>
          ${token ? `<button id="btnLogout" class="topbar-btn danger">${icons.logout}<span>Logout</span></button>` : ""}
        </div>
      </header>

      <div class="breadcrumb">
        <a href="#/dashboard">Dashboard</a>
        ${routeId !== "dashboard" ? `<span class="breadcrumb-sep">${icons.chevRight}</span><span style="font-weight:600;color:var(--text-primary);">${escapeHtml(currentRoute?.label || "")}</span>` : ""}
      </div>

      <div id="contentArea">
        <div id="toastHost"></div>
        <div id="content"></div>
      </div>

      <footer class="admin-footer">
        Booking Admin Dashboard v2.0 — © ${new Date().getFullYear()}
      </footer>
    </main>
  </div>

  <div id="loginModal" style="position:fixed;inset:0;z-index:100;display:none;align-items:center;justify-content:center;padding:20px;background:rgba(10,12,20,0.75);backdrop-filter:blur(12px);-webkit-backdrop-filter:blur(12px);">
    <div class="login-box">
      <div style="display:flex;align-items:center;gap:14px;margin-bottom:32px;">
        <div style="width:48px;height:48px;border-radius:14px;background:linear-gradient(135deg,#6366f1,#4f46e5);display:flex;align-items:center;justify-content:center;box-shadow:0 6px 20px rgba(99,102,241,0.4);">
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/><line x1="2" y1="12" x2="22" y2="12"/></svg>
        </div>
        <div>
          <div style="font-size:20px;font-weight:800;color:var(--text-primary);letter-spacing:-0.02em;">Đăng nhập Admin</div>
          <div style="font-size:13px;color:var(--text-muted);margin-top:3px;">Tài khoản có role <strong style="color:var(--accent);">admin</strong></div>
        </div>
      </div>
      <form id="loginForm" style="display:flex;flex-direction:column;gap:18px;">
        <div>
          <label style="font-size:12px;font-weight:700;color:var(--text-secondary);display:block;margin-bottom:7px;">Email</label>
          <input name="email" type="email" class="admin-input" placeholder="admin@example.com" required />
        </div>
        <div>
          <label style="font-size:12px;font-weight:700;color:var(--text-secondary);display:block;margin-bottom:7px;">Mật khẩu</label>
          <input name="password" type="password" class="admin-input" placeholder="••••••••" required />
        </div>
        <button type="submit" class="btn-primary" style="margin-top:6px;width:100%;padding:12px;font-size:14px;justify-content:center;">Đăng nhập</button>
      </form>
    </div>
  </div>
  `;
}


// ─── Dashboard ────────────────────────────────────────────────────────────────
async function renderDashboard() {
  qs("#subTitle").textContent = "Tổng quan hệ thống — 30 ngày gần nhất";
  const data = await apiFetch("/api/admin/dashboard/overview");
  const m = data?.metrics || {};
  const top = data?.topCourts || [];
  const bookingBreakdown = data?.breakdown?.bookingsByStatus || [];
  const paymentBreakdown = data?.breakdown?.paymentsByStatus || [];
  const tierBreakdown = data?.breakdown?.usersByTier || [];
  const topUsers = data?.topUsersByPoints || [];

  const cards = [
    { label: "Total Bookings", value: String(m.bookingsTotal ?? 0) },
    { label: "Revenue",        value: formatMoney(m.revenue ?? 0), hint: `${m.revenuePaymentsCount ?? 0} payments` },
    { label: "New Users",      value: String(m.newUsersTotal ?? 0) },
    { label: "Courts",         value: String(m.courtsTotal ?? 0) },
  ];

  const tierColors = { member: "#94a3b8", silver: "#60a5fa", gold: "#fbbf24", platinum: "#a78bfa" };
  const tierBg = { member: "rgba(148,163,184,0.1)", silver: "rgba(96,165,250,0.1)", gold: "rgba(251,191,36,0.1)", platinum: "rgba(167,139,250,0.1)" };

  return `
    <div class="welcome-banner">
      <div style="position:relative;z-index:1;">
        <div style="font-size:24px;font-weight:800;letter-spacing:-0.03em;margin-bottom:4px;">${getGreeting()}, Admin! 👋</div>
        <div style="font-size:14px;opacity:0.85;">${formatDateVN()}</div>
      </div>
    </div>

    ${renderCardGrid(cards)}

    <div style="display:grid;grid-template-columns:1fr 1fr;gap:20px;margin-top:24px;">
      <div class="admin-card">
        <div class="admin-card-header">
          <div class="card-icon" style="background:rgba(99,102,241,0.1);">📊</div>
          Bookings by Status
        </div>
        <div class="admin-card-body">
          ${bookingBreakdown.length === 0 ? `<div style="color:var(--text-muted);font-size:13px;">Không có dữ liệu</div>` :
            bookingBreakdown.map((x) => {
              const s = x?._id || "-";
              const pct = m.bookingsTotal ? Math.round((x.count / m.bookingsTotal) * 100) : 0;
              const colors = { pending: "#f59e0b", confirmed: "#10b981", cancelled: "#ef4444", completed: "#3b82f6" };
              const color = colors[s] || "#6366f1";
              return `<div style="margin-bottom:16px;">
                <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:8px;">
                  <div style="display:flex;align-items:center;gap:8px;">${statusBadge("booking", s)}</div>
                  <span style="font-size:14px;font-weight:800;color:var(--text-primary);">${escapeHtml(x.count || 0)} <span style="font-size:11px;font-weight:600;color:var(--text-muted);">(${pct}%)</span></span>
                </div>
                <div class="chart-bar"><div class="chart-bar-fill animated" style="width:${pct}%;background:${color};"></div></div>
              </div>`;
            }).join("")}
        </div>
      </div>

      <div class="admin-card">
        <div class="admin-card-header">
          <div class="card-icon" style="background:rgba(16,185,129,0.1);">💳</div>
          Payments by Status
        </div>
        <div class="admin-card-body">
          ${paymentBreakdown.length === 0 ? `<div style="color:var(--text-muted);font-size:13px;">Không có dữ liệu</div>` :
            paymentBreakdown.map((x) => {
              const s = x?._id || "-";
              return `<div style="display:flex;align-items:center;justify-content:space-between;padding:12px 0;border-bottom:1px solid var(--border-light);">
                <div style="display:flex;align-items:center;gap:8px;">${statusBadge("payment", s)}</div>
                <div style="text-align:right;">
                  <div style="font-size:14px;font-weight:800;color:var(--text-primary);">${escapeHtml(x.count || 0)}</div>
                  <div style="font-size:11px;color:var(--text-muted);">${escapeHtml(formatMoney(x.totalAmount || 0))}</div>
                </div>
              </div>`;
            }).join("")}
        </div>
      </div>
    </div>

    <div style="display:grid;grid-template-columns:1fr 1fr;gap:20px;margin-top:20px;">
      <div class="admin-card">
        <div class="admin-card-header">
          <div class="card-icon" style="background:rgba(245,158,11,0.1);">🏆</div>
          Top Courts
        </div>
        ${renderTable({
          columns: [
            { label: "#", render: (r, i) => `<span style="font-weight:800;color:var(--accent);font-size:15px;">${top.indexOf(r) + 1}</span>` },
            { label: "Court", render: (r) => `<div><div style="font-weight:700;">${escapeHtml(r.courtName || "-")}</div><div style="font-size:12px;color:var(--text-muted);">${escapeHtml(r.category || "")}</div></div>` },
            { label: "Bookings", render: (r) => `<span style="font-weight:700;">${escapeHtml(r.bookings)}</span>` },
            { label: "Revenue", render: (r) => `<span style="font-weight:700;color:var(--success);">${escapeHtml(formatMoney(r.revenue))}</span>` },
          ],
          rows: top,
        })}
      </div>

      <div class="admin-card">
        <div class="admin-card-header">
          <div class="card-icon" style="background:rgba(139,92,246,0.1);">⭐</div>
          Top Users by Points
        </div>
        <div class="admin-card-body" style="padding:0;">
          ${topUsers.length === 0 ? `<div style="padding:24px;text-align:center;color:var(--text-muted);font-size:13px;">Không có dữ liệu</div>` :
            `<table class="admin-table"><thead><tr><th>#</th><th>User</th><th>Points</th><th>Tier</th></tr></thead><tbody>
            ${topUsers.map((u, i) => `<tr>
              <td><span style="font-weight:800;color:var(--accent);font-size:15px;">${i + 1}</span></td>
              <td><div style="font-weight:700;">${escapeHtml(u.fullName || "-")}</div><div style="font-size:12px;color:var(--text-muted);">${escapeHtml(u.email || "")}</div></td>
              <td><span style="font-weight:800;color:var(--accent);font-size:14px;">${escapeHtml(String(u.points || 0))}</span></td>
              <td>${badge(u.tier || "member", { member: "slate", silver: "blue", gold: "amber", platinum: "purple" }[u.tier] || "slate")}</td>
            </tr>`).join("")}
            </tbody></table>`}
        </div>
      </div>
    </div>

    ${tierBreakdown.length > 0 ? `
    <div class="admin-card" style="margin-top:20px;">
      <div class="admin-card-header">
        <div class="card-icon" style="background:rgba(99,102,241,0.1);">👥</div>
        Users by Tier
      </div>
      <div class="admin-card-body">
        <div style="display:flex;gap:16px;flex-wrap:wrap;">
          ${tierBreakdown.map(t => {
            const tier = t._id || "member";
            const color = tierColors[tier] || "#94a3b8";
            const bg = tierBg[tier] || "rgba(148,163,184,0.1)";
            return `<div style="flex:1;min-width:140px;background:${bg};border-radius:var(--radius-md);padding:16px 20px;text-align:center;border:1px solid ${color}22;">
              <div style="font-size:28px;font-weight:800;color:${color};">${t.users || 0}</div>
              <div style="font-size:12px;font-weight:700;text-transform:uppercase;letter-spacing:0.06em;color:var(--text-muted);margin-top:4px;">${escapeHtml(tier)}</div>
            </div>`;
          }).join("")}
        </div>
      </div>
    </div>` : ""}
  `;
}

// ─── Users ────────────────────────────────────────────────────────────────────
async function renderUsers() {
  qs("#subTitle").textContent = "Quản lý người dùng — tìm kiếm, khoá/mở, đổi quyền, tạo, xoá";

  const wrapper = h(`<div style="display:flex;flex-direction:column;gap:20px;">
    <div class="admin-card">
      <div class="admin-card-body">
        <div style="display:flex;flex-wrap:wrap;gap:12px;align-items:flex-end;">
          <div style="flex:1;min-width:200px;">
            <label style="font-size:11.5px;font-weight:700;color:var(--text-muted);text-transform:uppercase;letter-spacing:0.06em;display:block;margin-bottom:6px;">Tìm kiếm</label>
            <input id="q" class="admin-input" placeholder="Tên / email / số điện thoại…" />
          </div>
          <div>
            <label style="font-size:11.5px;font-weight:700;color:var(--text-muted);text-transform:uppercase;letter-spacing:0.06em;display:block;margin-bottom:6px;">Trạng thái</label>
            <select id="status" class="admin-select"><option value="">Tất cả</option><option value="active">Active</option><option value="locked">Locked</option></select>
          </div>
          <div>
            <label style="font-size:11.5px;font-weight:700;color:var(--text-muted);text-transform:uppercase;letter-spacing:0.06em;display:block;margin-bottom:6px;">Quyền</label>
            <select id="role" class="admin-select"><option value="">Tất cả</option><option value="customer">Customer</option><option value="admin">Admin</option></select>
          </div>
          <button id="btnSearch" class="btn-primary">${icons.search} Tìm kiếm</button>
          <button id="btnCreateUser" class="btn-primary">${icons.plus} Tạo user</button>
        </div>
      </div>
    </div>
    <div id="usersTable"></div>
  </div>`);

  let currentPage = 1;
  const PAGE_LIMIT = 15;

  async function load(page) {
    if (page) currentPage = page;
    const q = qs("#q", wrapper).value.trim();
    const status = qs("#status", wrapper).value;
    const role = qs("#role", wrapper).value;
    const data = await apiFetch("/api/admin/users", { query: { q, status, role, page: currentPage, limit: PAGE_LIMIT } });
    const users = data?.users || [];
    const pg = data?.pagination || {};
    qs("#usersTable", wrapper).innerHTML = renderTable({
      columns: [
        { label: "User", render: (u) => `<div style="display:flex;align-items:center;gap:12px;">
          <div class="avatar" style="width:38px;height:38px;border-radius:10px;background:linear-gradient(135deg,#6366f1,#8b5cf6);font-size:14px;">${escapeHtml((u.fullName || "?")[0].toUpperCase())}</div>
          <div><div style="font-weight:700;">${escapeHtml(u.fullName || "-")}</div><div style="font-size:12px;color:var(--text-muted);">${escapeHtml(u.email || "")}</div>${u.phone ? `<div style="font-size:12px;color:var(--text-muted);">${escapeHtml(u.phone)}</div>` : ""}</div>
        </div>` },
        { label: "Role", render: (u) => badge(u.role || "-", u.role === "admin" ? "purple" : "slate") },
        { label: "Status", render: (u) => statusBadge("user", u.status) },
        { label: "Actions", render: (u) => `<div style="display:flex;gap:6px;flex-wrap:wrap;">
          <button data-act="toggleLock" data-id="${escapeHtml(u._id)}" data-status="${escapeHtml(u.status)}" class="${u.status === "locked" ? "btn-sm" : "btn-danger"}">${u.status === "locked" ? "🔓 Unlock" : "🔒 Lock"}</button>
          <button data-act="toggleRole" data-id="${escapeHtml(u._id)}" data-role="${escapeHtml(u.role)}" class="btn-sm">${u.role === "admin" ? "👤 → Customer" : "⭐ → Admin"}</button>
          <button data-act="editUser" data-id="${escapeHtml(u._id)}" data-name="${escapeHtml(u.fullName || "")}" data-email="${escapeHtml(u.email || "")}" data-phone="${escapeHtml(u.phone || "")}" class="btn-sm">${icons.edit} Sửa</button>
          <button data-act="deleteUser" data-id="${escapeHtml(u._id)}" data-name="${escapeHtml(u.fullName || u.email || "-")}" class="btn-danger">${icons.trash} Xoá</button>
        </div>` },
      ],
      rows: users,
    }) + renderPagination({ page: pg.page || currentPage, totalPages: pg.totalPages || 1, total: pg.total || users.length, limit: PAGE_LIMIT, onPageChange: (p) => load(p).catch((e) => toast("error", "Lỗi", e.message)) });
  }

  wrapper.addEventListener("click", async (e) => {
    const btn = e.target.closest("button[data-act]");
    if (!btn) return;
    const act = btn.dataset.act;
    const id = btn.dataset.id;
    try {
      if (act === "toggleLock") {
        const next = btn.dataset.status === "locked" ? "active" : "locked";
        await apiFetch(`/api/admin/users/${id}/status`, { method: "PATCH", body: { status: next } });
        toast("success", "Cập nhật thành công", "Trạng thái user đã thay đổi");
        await load();
      }
      if (act === "toggleRole") {
        const next = btn.dataset.role === "admin" ? "customer" : "admin";
        await apiFetch(`/api/admin/users/${id}/role`, { method: "PATCH", body: { role: next } });
        toast("success", "Cập nhật thành công", "Quyền user đã thay đổi");
        await load();
      }
      if (act === "editUser") {
        openModal({
          title: "✏️ Chỉnh sửa user",
          body: `<div style="display:flex;flex-direction:column;gap:16px;">
            ${field("Họ tên", inp("editName", "text", btn.dataset.name, "Nguyễn Văn A"))}
            ${field("Email", inp("editEmail", "email", btn.dataset.email, "user@example.com"))}
            ${field("Số điện thoại", inp("editPhone", "text", btn.dataset.phone, "0912345678"))}
          </div>`,
          onConfirm: async (modal) => {
            const body = {
              fullName: qs("#editName", modal).value.trim(),
              email: qs("#editEmail", modal).value.trim(),
              phone: qs("#editPhone", modal).value.trim(),
            };
            await apiFetch(`/api/admin/users/${id}`, { method: "PATCH", body });
            toast("success", "Đã cập nhật", "Thông tin user đã được lưu");
            await load();
          },
          confirmLabel: "Lưu thay đổi",
        });
      }
      if (act === "deleteUser") {
        confirmDialog("🗑️ Xoá user", `Bạn có chắc muốn xoá "${btn.dataset.name}"? Hành động này không thể hoàn tác.`, async () => {
          await apiFetch(`/api/admin/users/${id}`, { method: "DELETE" });
          toast("success", "Đã xoá", "User đã được xoá thành công");
          await load();
        });
      }
    } catch (err) { toast("error", "Lỗi", err.message); }
  });

  qs("#btnSearch", wrapper).onclick = () => load(1).catch((e) => toast("error", "Lỗi", e.message));
  qs("#q", wrapper).addEventListener("keydown", (e) => { if (e.key === "Enter") load(1).catch((err) => toast("error", "Lỗi", err.message)); });

  qs("#btnCreateUser", wrapper).onclick = () => {
    openModal({
      title: "➕ Tạo user mới",
      body: `<div style="display:flex;flex-direction:column;gap:16px;">
        ${field("Họ tên", inp("newName", "text", "", "Nguyễn Văn A"))}
        ${field("Email", inp("newEmail", "email", "", "user@example.com"))}
        ${field("Số điện thoại", inp("newPhone", "text", "", "0912345678"))}
        ${field("Mật khẩu", inp("newPassword", "password", "", "••••••••"))}
        ${field("Quyền", sel("newRole", [["customer","Customer"],["admin","Admin"]], "customer"))}
      </div>`,
      onConfirm: async (modal) => {
        const body = {
          fullName: qs("#newName", modal).value.trim(),
          email: qs("#newEmail", modal).value.trim(),
          phone: qs("#newPhone", modal).value.trim(),
          password: qs("#newPassword", modal).value.trim(),
          role: qs("#newRole", modal).value,
        };
        await apiFetch("/api/admin/users", { method: "POST", body });
        toast("success", "Đã tạo", "User mới đã được tạo thành công");
        await load();
      },
      confirmLabel: "Tạo user",
    });
  };

  await load();
  return wrapper;
}


// ─── Courts ───────────────────────────────────────────────────────────────────
async function renderCourts() {
  qs("#subTitle").textContent = "Quản lý sân — tạo, chỉnh sửa, xoá, đổi trạng thái";
  const wrapper = h(`<div style="display:flex;flex-direction:column;gap:20px;">
    <div style="display:flex;justify-content:flex-end;">
      <button id="btnCreateCourt" class="btn-primary">${icons.plus} Thêm sân mới</button>
    </div>
    <div id="courtsTable"></div>
  </div>`);

  let currentPage = 1;
  const PAGE_LIMIT = 15;

  async function load(page) {
    if (page) currentPage = page;
    const data = await apiFetch("/api/admin/courts", { query: { page: currentPage, limit: PAGE_LIMIT } });
    const courts = data?.courts || data?.items || [];
    const pg = data?.pagination || {};
    qs("#courtsTable", wrapper).innerHTML = renderTable({
      columns: [
        { label: "Sân", render: (c) => `<div><div style="font-weight:700;">${escapeHtml(c.name || "-")}</div><div style="font-size:12px;color:var(--text-muted);">${escapeHtml(c.address || "")}</div></div>` },
        { label: "Loại", render: (c) => `<span style="font-weight:600;">${escapeHtml(c.category || "-")}</span>` },
        { label: "Trạng thái", render: (c) => statusBadge("court", c.status) },
        { label: "Giá/slot", render: (c) => `<span style="font-weight:700;color:var(--success);">${escapeHtml(formatMoney(c.pricePerSlot))}</span>` },
        { label: "Giờ mở", render: (c) => `<span class="font-mono" style="font-size:12px;background:#f4f5fb;padding:4px 10px;border-radius:6px;">${escapeHtml(c.openTime || "")} – ${escapeHtml(c.closeTime || "")}</span>` },
        { label: "Actions", render: (c) => `<div style="display:flex;gap:6px;flex-wrap:wrap;">
          <button data-act="editCourt" data-id="${escapeHtml(c._id)}" data-json="${escapeHtml(JSON.stringify(c))}" class="btn-sm">${icons.edit} Sửa</button>
          <button data-act="toggleCourtStatus" data-id="${escapeHtml(c._id)}" data-status="${escapeHtml(c.status)}" class="btn-sm">${c.status === "maintenance" ? "✅ Kích hoạt" : "🔧 Bảo trì"}</button>
          <button data-act="deleteCourt" data-id="${escapeHtml(c._id)}" data-name="${escapeHtml(c.name || "-")}" class="btn-danger">${icons.trash} Xoá</button>
        </div>` },
      ],
      rows: courts,
    }) + renderPagination({ page: pg.page || currentPage, totalPages: pg.totalPages || 1, total: pg.total || courts.length, limit: PAGE_LIMIT, onPageChange: (p) => load(p).catch((e) => toast("error", "Lỗi", e.message)) });
  }

  function courtForm(c = {}) {
    const existingImages = Array.isArray(c.images) ? c.images : [];
    const existingLogo = c.logoUrl || '';
    const baseUrl = getApiBaseUrl();
    return `<div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;">
      ${field("Tên sân", inp("fName", "text", c.name || "", "Sân A1"))}
      ${field("Loại", inp("fCategory", "text", c.category || "", "Cầu lông / Padel…"))}
      ${field("Địa chỉ", `<input id="fAddress" type="text" class="admin-input" value="${escapeHtml(c.address || "")}" placeholder="123 Đường…" style="grid-column:span 2;" />`)}
      ${field("Giá/slot (VND)", inp("fPrice", "number", c.pricePerSlot || "", "150000"))}
      ${field("Trạng thái", sel("fStatus", [["active","Active"],["maintenance","Bảo trì"]], c.status || "active"))}
      ${field("Giờ mở", inp("fOpenTime", "time", c.openTime || "06:00"))}
      ${field("Giờ đóng", inp("fCloseTime", "time", c.closeTime || "22:00"))}
      <div style="grid-column:span 2;">
        ${field("Ảnh sân (tối đa 5 ảnh)", `<input id="fImages" type="file" accept="image/*" multiple class="admin-input" style="padding:8px;" />`)}
        ${existingImages.length > 0 ? `<div id="existingImages" style="display:flex;gap:8px;flex-wrap:wrap;margin-top:8px;">
          ${existingImages.map((img, i) => `<div style="position:relative;">
            <img src="${escapeHtml(baseUrl + img)}" style="width:80px;height:80px;object-fit:cover;border-radius:8px;border:1px solid var(--border);" />
            <button type="button" data-remove-img="${i}" style="position:absolute;top:-6px;right:-6px;width:18px;height:18px;border-radius:50%;background:var(--danger);color:#fff;border:none;cursor:pointer;font-size:10px;display:flex;align-items:center;justify-content:center;">✕</button>
          </div>`).join('')}
        </div>` : ''}
      </div>
      <div style="grid-column:span 2;">
        ${field("Logo sân", `<input id="fLogo" type="file" accept="image/*" class="admin-input" style="padding:8px;" />`)}
        ${existingLogo ? `<div id="existingLogo" style="margin-top:8px;">
          <img src="${escapeHtml(baseUrl + existingLogo)}" style="width:80px;height:80px;object-fit:cover;border-radius:8px;border:1px solid var(--border);" />
        </div>` : ''}
      </div>
    </div>`;
  }

  wrapper.addEventListener("click", async (e) => {
    const btn = e.target.closest("button[data-act]");
    if (!btn) return;
    const act = btn.dataset.act;
    const id = btn.dataset.id;
    try {
      if (act === "editCourt") {
        const c = JSON.parse(btn.dataset.json || "{}");
        let removedImageIndexes = [];
        const modal = openModal({
          title: "✏️ Chỉnh sửa sân", body: courtForm(c), size: "620px",
          onConfirm: async (modal) => {
            const courtBody = { name: qs("#fName", modal).value.trim(), category: qs("#fCategory", modal).value.trim(), address: qs("#fAddress", modal).value.trim(), pricePerSlot: Number(qs("#fPrice", modal).value), status: qs("#fStatus", modal).value, openTime: qs("#fOpenTime", modal).value, closeTime: qs("#fCloseTime", modal).value };
            const imgInput = qs("#fImages", modal); const logoInput = qs("#fLogo", modal);
            const hasNewFiles = (imgInput.files.length > 0) || (logoInput.files.length > 0);
            if (hasNewFiles) {
              const fd = new FormData();
              for (const f of imgInput.files) fd.append("images", f);
              for (const f of logoInput.files) fd.append("logo", f);
              const uploadRes = await apiFetch("/api/admin/courts/upload-images", { method: "POST", formData: fd });
              if (uploadRes.images && uploadRes.images.length > 0) {
                const kept = (Array.isArray(c.images) ? c.images : []).filter((_, i) => !removedImageIndexes.includes(i));
                courtBody.images = [...kept, ...uploadRes.images];
              }
              if (uploadRes.logoUrl) courtBody.logoUrl = uploadRes.logoUrl;
            } else if (removedImageIndexes.length > 0) {
              courtBody.images = (Array.isArray(c.images) ? c.images : []).filter((_, i) => !removedImageIndexes.includes(i));
            }
            await apiFetch(`/api/admin/courts/${id}`, { method: "PATCH", body: courtBody });
            toast("success", "Đã cập nhật", "Thông tin sân đã được lưu"); await load();
          }, confirmLabel: "Lưu thay đổi",
        });
        modal.addEventListener("click", (e) => { const rmBtn = e.target.closest("button[data-remove-img]"); if (!rmBtn) return; removedImageIndexes.push(Number(rmBtn.dataset.removeImg)); rmBtn.parentElement.remove(); });
      }
      if (act === "toggleCourtStatus") {
        const next = btn.dataset.status === "maintenance" ? "active" : "maintenance";
        await apiFetch(`/api/admin/courts/${id}/status`, { method: "PATCH", body: { status: next } });
        toast("success", "Cập nhật thành công", "Trạng thái sân đã thay đổi"); await load();
      }
      if (act === "deleteCourt") {
        confirmDialog("🗑️ Xoá sân", `Bạn có chắc muốn xoá sân "${btn.dataset.name}"?`, async () => {
          await apiFetch(`/api/admin/courts/${id}`, { method: "DELETE" });
          toast("success", "Đã xoá", "Sân đã được xoá thành công"); await load();
        });
      }
    } catch (err) { toast("error", "Lỗi", err.message); }
  });

  qs("#btnCreateCourt", wrapper).onclick = () => {
    openModal({
      title: "➕ Thêm sân mới", body: courtForm(), size: "620px",
      onConfirm: async (modal) => {
        const courtBody = { name: qs("#fName", modal).value.trim(), category: qs("#fCategory", modal).value.trim(), address: qs("#fAddress", modal).value.trim(), pricePerSlot: Number(qs("#fPrice", modal).value), status: qs("#fStatus", modal).value, openTime: qs("#fOpenTime", modal).value, closeTime: qs("#fCloseTime", modal).value };
        const imgInput = qs("#fImages", modal); const logoInput = qs("#fLogo", modal);
        if (imgInput.files.length > 0 || logoInput.files.length > 0) {
          const fd = new FormData();
          for (const f of imgInput.files) fd.append("images", f);
          for (const f of logoInput.files) fd.append("logo", f);
          const uploadRes = await apiFetch("/api/admin/courts/upload-images", { method: "POST", formData: fd });
          if (uploadRes.images) courtBody.images = uploadRes.images;
          if (uploadRes.logoUrl) courtBody.logoUrl = uploadRes.logoUrl;
        }
        await apiFetch("/api/admin/courts", { method: "POST", body: courtBody });
        toast("success", "Đã tạo", "Sân mới đã được thêm thành công"); await load();
      }, confirmLabel: "Thêm sân",
    });
  };

  await load();
  return wrapper;
}

// ─── Bookings ─────────────────────────────────────────────────────────────────
async function renderBookings() {
  qs("#subTitle").textContent = "Quản lý booking — tạo thủ công, đổi trạng thái, xoá";
  const wrapper = h(`<div style="display:flex;flex-direction:column;gap:20px;">
    <div class="admin-card">
      <div class="admin-card-body">
        <div style="display:flex;flex-wrap:wrap;gap:12px;align-items:flex-end;">
          <div style="flex:1;min-width:180px;">
            <label style="font-size:11.5px;font-weight:700;color:var(--text-muted);text-transform:uppercase;letter-spacing:0.06em;display:block;margin-bottom:6px;">Trạng thái</label>
            <select id="bStatus" class="admin-select"><option value="">Tất cả</option><option value="pending">Pending</option><option value="confirmed">Confirmed</option><option value="cancelled">Cancelled</option><option value="completed">Completed</option></select>
          </div>
          <div style="flex:1;min-width:180px;">
            <label style="font-size:11.5px;font-weight:700;color:var(--text-muted);text-transform:uppercase;letter-spacing:0.06em;display:block;margin-bottom:6px;">Tìm kiếm</label>
            <input id="bQ" class="admin-input" placeholder="Mã booking / email khách…" />
          </div>
          <button id="btnBSearch" class="btn-primary">${icons.search} Tìm kiếm</button>
          <button id="btnCreateBooking" class="btn-primary">${icons.plus} Tạo booking</button>
        </div>
      </div>
    </div>
    <div id="bookingsTable"></div>
  </div>`);

  let currentPage = 1;
  const PAGE_LIMIT = 15;

  async function load(page) {
    if (page) currentPage = page;
    const status = qs("#bStatus", wrapper).value;
    const q = qs("#bQ", wrapper).value.trim();
    const data = await apiFetch("/api/admin/bookings", { query: { status, q, page: currentPage, limit: PAGE_LIMIT } });
    const bookings = data?.bookings || data?.items || [];
    const pg = data?.pagination || {};
    qs("#bookingsTable", wrapper).innerHTML = renderTable({
      columns: [
        { label: "Mã đặt", render: (b) => `<div style="display:flex;align-items:center;gap:10px;">
          <div class="avatar" style="width:38px;height:38px;border-radius:10px;background:linear-gradient(135deg,#6366f1,#818cf8);">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
          </div>
          <div>
            <div style="font-weight:800;font-family:'JetBrains Mono',monospace;font-size:13px;color:var(--accent);">${escapeHtml(b.bookingCode || "-")}</div>
            <div style="font-size:11.5px;color:var(--text-muted);margin-top:2px;">📅 ${escapeHtml(b.date || "")} · 🕐 ${escapeHtml(b.startTime || "")}–${escapeHtml(b.endTime || "")}</div>
          </div>
        </div>` },
        { label: "Sân", render: (b) => `<div><div style="font-weight:700;">${escapeHtml(b.court?.name || "-")}</div><div style="font-size:11.5px;color:var(--text-muted);">${escapeHtml(b.court?.category || "")}</div></div>` },
        { label: "Khách", render: (b) => `<div style="display:flex;align-items:center;gap:8px;">
          <div class="avatar" style="width:30px;height:30px;border-radius:8px;background:linear-gradient(135deg,#f59e0b,#f97316);font-size:12px;">${escapeHtml((b.user?.fullName || "?")[0].toUpperCase())}</div>
          <div><div style="font-weight:700;font-size:13px;">${escapeHtml(b.user?.fullName || "-")}</div><div style="font-size:11.5px;color:var(--text-muted);">${escapeHtml(b.user?.email || "")}</div></div>
        </div>` },
        { label: "Thanh toán", render: (b) => {
          const hasDis = (b.discountAmount || 0) > 0;
          return `<div>
            <div style="font-weight:800;font-size:14px;color:var(--success);">${escapeHtml(formatMoney(b.finalPrice))}</div>
            ${hasDis ? `<div style="font-size:11px;color:var(--warning);margin-top:2px;">🏷️ -${escapeHtml(formatMoney(b.discountAmount))}</div>` : ""}
          </div>`;
        }},
        { label: "Trạng thái", render: (b) => statusBadge("booking", b.status) },
        { label: "Thao tác", render: (b) => `<div style="display:flex;gap:6px;flex-wrap:wrap;">
          <button data-act="viewBooking" data-json="${escapeHtml(JSON.stringify(b))}" class="btn-primary" style="font-size:11.5px;padding:5px 12px;box-shadow:none;">👁 Chi tiết</button>
          <button data-act="changeBookingStatus" data-id="${escapeHtml(b._id)}" data-status="${escapeHtml(b.status)}" class="btn-sm" style="font-size:11.5px;">${icons.edit} Trạng thái</button>
          <button data-act="deleteBooking" data-id="${escapeHtml(b._id)}" data-code="${escapeHtml(b.bookingCode || "-")}" class="btn-danger" style="font-size:11.5px;">${icons.trash}</button>
        </div>` },
      ],
      rows: bookings,
    }) + renderPagination({ page: pg.page || currentPage, totalPages: pg.totalPages || 1, total: pg.total || bookings.length, limit: PAGE_LIMIT, onPageChange: (p) => load(p).catch((e) => toast("error", "Lỗi", e.message)) });
  }

  wrapper.addEventListener("click", async (e) => {
    const btn = e.target.closest("button[data-act]");
    if (!btn) return;
    const act = btn.dataset.act;
    const id = btn.dataset.id;
    try {
      if (act === "changeBookingStatus") {
        openModal({
          title: "🔄 Đổi trạng thái booking",
          body: `<div style="display:flex;flex-direction:column;gap:16px;">
            <div style="font-size:13px;color:var(--text-secondary);">Chọn trạng thái mới cho booking này:</div>
            ${field("Trạng thái", sel("newBStatus", [["pending","⏳ Pending"],["confirmed","✅ Confirmed"],["cancelled","❌ Cancelled"],["completed","🏁 Completed"]], btn.dataset.status))}
            ${field("Ghi chú (tuỳ chọn)", `<input id="statusNote" type="text" class="admin-input" placeholder="Lý do thay đổi…" />`)}
          </div>`,
          onConfirm: async (modal) => {
            const body = { status: qs("#newBStatus", modal).value };
            const note = qs("#statusNote", modal).value.trim();
            if (note) body.note = note;
            await apiFetch(`/api/admin/bookings/${id}/status`, { method: "PATCH", body });
            toast("success", "Đã cập nhật", "Trạng thái booking đã thay đổi"); await load();
          }, confirmLabel: "Cập nhật",
        });
      }
      if (act === "viewBooking") {
        const bId = JSON.parse(btn.dataset.json || "{}")?._id;
        if (!bId) { toast("error", "Lỗi", "Không tìm thấy ID booking"); return; }
        try {
          const detail = await apiFetch(`/api/admin/bookings/${bId}`);
          const b = detail?.booking || {};
          const u = b.user || {};
          const w = u.wallet || {};
          const d = b.discount || null;
          const payments = b.payments || [];
          const slots = b.timeSlots || [];
          const tierColors = { member: "slate", silver: "blue", gold: "amber", platinum: "purple", diamond: "green" };
          const slotsBySubCourt = {};
          for (const s of slots) { const scName = s.subCourt?.name || b.subCourt?.name || "—"; if (!slotsBySubCourt[scName]) slotsBySubCourt[scName] = []; slotsBySubCourt[scName].push(s); }

          const slotsHtml = Object.keys(slotsBySubCourt).length > 0
            ? Object.entries(slotsBySubCourt).map(([scName, scSlots]) => `<div style="background:var(--info-light);border-radius:8px;padding:10px 12px;margin-bottom:6px;border:1px solid rgba(59,130,246,0.1);"><div style="display:flex;align-items:center;gap:6px;margin-bottom:6px;"><span style="width:6px;height:6px;border-radius:50%;background:var(--info);"></span><span style="font-weight:700;font-size:12.5px;color:var(--info);">${escapeHtml(scName)}</span><span style="font-size:11px;color:var(--text-muted);margin-left:auto;">${scSlots.length} slot</span></div><div style="display:flex;flex-wrap:wrap;gap:4px;">${scSlots.map(s => `<span class="font-mono" style="display:inline-block;background:#fff;color:var(--info);padding:3px 8px;border-radius:6px;font-size:12px;border:1px solid rgba(59,130,246,0.15);">${escapeHtml(s.startTime||"")}-${escapeHtml(s.endTime||"")} (${escapeHtml(formatMoney(s.price||0))})</span>`).join("")}</div></div>`).join("")
            : `<span style="color:var(--text-muted);">—</span>`;

          const paymentsHtml = payments.length > 0
            ? `<table style="width:100%;font-size:12.5px;border-collapse:collapse;margin-top:6px;"><thead><tr style="border-bottom:1px solid var(--border-light);"><th style="text-align:left;padding:6px 8px;color:var(--text-muted);font-size:11px;font-weight:700;">PT THANH TOÁN</th><th style="text-align:left;padding:6px 8px;color:var(--text-muted);font-size:11px;font-weight:700;">SỐ TIỀN</th><th style="text-align:left;padding:6px 8px;color:var(--text-muted);font-size:11px;font-weight:700;">TRẠNG THÁI</th><th style="text-align:left;padding:6px 8px;color:var(--text-muted);font-size:11px;font-weight:700;">THỜI GIAN</th></tr></thead><tbody>${payments.map(p => `<tr style="border-bottom:1px solid var(--border-light);"><td style="padding:8px;">${escapeHtml(p.method||"-")}</td><td style="padding:8px;font-weight:700;color:var(--success);">${escapeHtml(formatMoney(p.amount||0))}</td><td style="padding:8px;">${statusBadge("payment", p.status)}</td><td style="padding:8px;" class="font-mono" style="font-size:11px;">${escapeHtml(p.paidAt ? new Date(p.paidAt).toLocaleString("vi-VN") : "—")}</td></tr>`).join("")}</tbody></table>`
            : `<div style="color:var(--text-muted);font-size:13px;padding:8px 0;">Chưa có thanh toán</div>`;

          const discountHtml = d
            ? `<div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;"><div><span style="color:var(--text-muted);font-size:11px;">MÃ VOUCHER</span><div class="font-mono" style="font-weight:700;color:var(--warning);">${escapeHtml(d.code||"-")}</div></div><div><span style="color:var(--text-muted);font-size:11px;">LOẠI GIẢM GIÁ</span><div>${escapeHtml(d.discountType === "percent" ? d.discountValue+"%" : formatMoney(d.discountValue||0))}</div></div><div><span style="color:var(--text-muted);font-size:11px;">MÔ TẢ</span><div>${escapeHtml(d.description||"—")}</div></div><div><span style="color:var(--text-muted);font-size:11px;">SỐ TIỀN GIẢM</span><div style="font-weight:700;color:var(--success);">-${escapeHtml(formatMoney(b.discountAmount||0))}</div></div></div>`
            : `<div style="color:var(--text-muted);font-size:13px;">Không sử dụng voucher</div>`;

          openModal({
            title: `📋 Booking ${escapeHtml(b.bookingCode || "")}`, size: "720px",
            body: `<div class="detail-grid">
              <div style="background:linear-gradient(135deg,#6366f1,#4f46e5);border-radius:14px;padding:20px 22px;color:#fff;position:relative;overflow:hidden;">
                <div style="position:absolute;top:-20px;right:-20px;width:100px;height:100px;border-radius:50%;background:rgba(255,255,255,0.1);"></div>
                <div style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:10px;">
                  <div>
                    <div style="font-size:11px;text-transform:uppercase;letter-spacing:0.1em;opacity:0.7;margin-bottom:4px;">Mã Booking</div>
                    <div class="font-mono" style="font-size:22px;font-weight:800;letter-spacing:0.02em;">${escapeHtml(b.bookingCode||"-")}</div>
                  </div>
                  <div style="text-align:right;">${statusBadge("booking", b.status)}<div style="font-size:12px;opacity:0.8;margin-top:6px;">📅 ${escapeHtml(b.date||"-")} · 🕐 ${escapeHtml(b.startTime||"")} – ${escapeHtml(b.endTime||"")}</div></div>
                </div>
              </div>
              <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;">
                <div class="detail-section"><div class="detail-section-title"><span>👤</span>Người đặt</div>
                  <div style="display:flex;align-items:center;gap:10px;margin-bottom:10px;">
                    <div class="avatar" style="width:36px;height:36px;border-radius:10px;background:linear-gradient(135deg,#f59e0b,#f97316);font-size:14px;">${escapeHtml((u.fullName||"?")[0].toUpperCase())}</div>
                    <div><div style="font-weight:700;font-size:14px;">${escapeHtml(u.fullName||"-")}</div><div style="font-size:12px;color:var(--text-muted);">${escapeHtml(u.email||"-")}</div></div>
                  </div>
                  <div style="display:grid;grid-template-columns:1fr 1fr;gap:6px;font-size:12.5px;">
                    <div><span style="color:var(--text-muted);font-size:10.5px;text-transform:uppercase;">Điện thoại</span><div style="font-weight:500;margin-top:2px;">${escapeHtml(u.phone||b.contactPhone||"-")}</div></div>
                    <div><span style="color:var(--text-muted);font-size:10.5px;text-transform:uppercase;">Hạng</span><div style="margin-top:2px;">${badge(w.tier||"member", tierColors[w.tier]||"slate")}</div></div>
                  </div>
                </div>
                <div class="detail-section"><div class="detail-section-title"><span>🏟️</span>Thông tin sân</div>
                  <div style="font-weight:700;font-size:15px;margin-bottom:4px;">${escapeHtml(b.court?.name||"-")}</div>
                  <div style="font-size:12px;color:var(--text-muted);margin-bottom:8px;">${escapeHtml(b.court?.category||"")} · ${escapeHtml(b.court?.address||"")}</div>
                  <div style="display:grid;grid-template-columns:1fr 1fr;gap:6px;font-size:12.5px;">
                    <div><span style="color:var(--text-muted);font-size:10.5px;text-transform:uppercase;">Sân con</span><div style="font-weight:500;margin-top:2px;">${escapeHtml(b.subCourt?.name||"—")}</div></div>
                    <div><span style="color:var(--text-muted);font-size:10.5px;text-transform:uppercase;">Tổng slot</span><div style="font-weight:500;margin-top:2px;">${slots.length} slot</div></div>
                  </div>
                </div>
              </div>
              <div class="detail-section"><div class="detail-section-title"><span>⏰</span>Chi tiết theo sân con</div>${slotsHtml}</div>
              <div style="background:var(--success-light);border-radius:12px;padding:16px 18px;border:1px solid #a7f3d0;">
                <div class="detail-section-title" style="color:var(--success);"><span>💰</span>Tổng kết thanh toán</div>
                <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:10px;">
                  <div style="background:#fff;border-radius:8px;padding:10px 12px;text-align:center;border:1px solid #dcfce7;"><div style="font-size:10.5px;color:var(--text-muted);text-transform:uppercase;margin-bottom:4px;">Tạm tính</div><div style="font-size:16px;font-weight:800;">${escapeHtml(formatMoney(b.totalPrice||0))}</div></div>
                  <div style="background:#fff;border-radius:8px;padding:10px 12px;text-align:center;border:1px solid #dcfce7;"><div style="font-size:10.5px;color:var(--text-muted);text-transform:uppercase;margin-bottom:4px;">Giảm giá</div><div style="font-size:16px;font-weight:800;color:var(--warning);">-${escapeHtml(formatMoney(b.discountAmount||0))}</div></div>
                  <div style="background:#fff;border-radius:8px;padding:10px 12px;text-align:center;border:1px solid #dcfce7;"><div style="font-size:10.5px;color:var(--text-muted);text-transform:uppercase;margin-bottom:4px;">Thành tiền</div><div style="font-size:18px;font-weight:900;color:var(--success);">${escapeHtml(formatMoney(b.finalPrice||0))}</div></div>
                </div>
              </div>
              <div class="detail-section"><div class="detail-section-title"><span>💳</span>Lịch sử thanh toán</div>${paymentsHtml}</div>
              <div class="detail-section"><div class="detail-section-title"><span>🏷️</span>Thông tin ưu đãi</div>${discountHtml}</div>
            </div>`,
          });
        } catch (err) { toast("error", "Lỗi", err.message); }
      }
      if (act === "deleteBooking") {
        confirmDialog("🗑️ Xoá booking", `Bạn có chắc muốn xoá booking "${btn.dataset.code}"?`, async () => {
          await apiFetch(`/api/admin/bookings/${id}`, { method: "DELETE" });
          toast("success", "Đã xoá", "Booking đã được xoá thành công"); await load();
        });
      }
    } catch (err) { toast("error", "Lỗi", err.message); }
  });

  qs("#btnBSearch", wrapper).onclick = () => load(1).catch((e) => toast("error", "Lỗi", e.message));
  qs("#bQ", wrapper).addEventListener("keydown", (e) => { if (e.key === "Enter") load(1).catch((err) => toast("error", "Lỗi", err.message)); });

  qs("#btnCreateBooking", wrapper).onclick = async () => {
    let courtOptions = [["", "-- Chọn sân --"]];
    try { const cd = await apiFetch("/api/admin/courts", { query: { page: 1, limit: 100 } }); const courts = cd?.courts || cd?.items || []; courtOptions = [["", "-- Chọn sân --"], ...courts.map((c) => [c._id, c.name])]; } catch {}
    openModal({
      title: "➕ Tạo booking thủ công", size: "560px",
      body: `<div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;">
        ${field("Chọn sân", sel("cbCourt", courtOptions, ""))}
        ${field("User ID / Email", inp("cbUser", "text", "", "user@example.com"))}
        ${field("Ngày", inp("cbDate", "date", new Date().toISOString().split("T")[0]))}
        ${field("Giờ bắt đầu", inp("cbStart", "time", "08:00"))}
        ${field("Giờ kết thúc", inp("cbEnd", "time", "09:00"))}
        ${field("Trạng thái", sel("cbStatus", [["pending","Pending"],["confirmed","Confirmed"]], "pending"))}
        ${field("Ghi chú", inp("cbNote", "text", "", "Ghi chú tuỳ chọn…"))}
      </div>`,
      onConfirm: async (modal) => {
        const body = { courtId: qs("#cbCourt", modal).value, userId: qs("#cbUser", modal).value.trim(), date: qs("#cbDate", modal).value, startTime: qs("#cbStart", modal).value, endTime: qs("#cbEnd", modal).value, status: qs("#cbStatus", modal).value, note: qs("#cbNote", modal).value.trim() };
        await apiFetch("/api/admin/bookings", { method: "POST", body });
        toast("success", "Đã tạo", "Booking mới đã được tạo thành công"); await load();
      }, confirmLabel: "Tạo booking",
    });
  };

  await load();
  return wrapper;
}


// ─── Payments ─────────────────────────────────────────────────────────────────
async function renderPayments() {
  qs("#subTitle").textContent = "Lịch sử thanh toán — chỉnh trạng thái, xem chi tiết";
  const wrapper = h(`<div style="display:flex;flex-direction:column;gap:20px;">
    <div class="admin-card"><div class="admin-card-body">
      <div style="display:flex;flex-wrap:wrap;gap:12px;align-items:flex-end;">
        <div style="flex:1;min-width:180px;">
          <label style="font-size:11.5px;font-weight:700;color:var(--text-muted);text-transform:uppercase;letter-spacing:0.06em;display:block;margin-bottom:6px;">Trạng thái</label>
          <select id="pStatus" class="admin-select"><option value="">Tất cả</option><option value="pending">Pending</option><option value="completed">Completed</option><option value="failed">Failed</option><option value="refunded">Refunded</option></select>
        </div>
        <div style="flex:1;min-width:180px;">
          <label style="font-size:11.5px;font-weight:700;color:var(--text-muted);text-transform:uppercase;letter-spacing:0.06em;display:block;margin-bottom:6px;">Tìm kiếm</label>
          <input id="pQ" class="admin-input" placeholder="Email / booking code…" />
        </div>
        <button id="btnPSearch" class="btn-primary">${icons.search} Tìm kiếm</button>
      </div>
    </div></div>
    <div id="paymentsTable"></div>
  </div>`);

  let currentPage = 1;
  const PAGE_LIMIT = 15;

  async function load(page) {
    if (page) currentPage = page;
    const status = qs("#pStatus", wrapper).value;
    const q = qs("#pQ", wrapper).value.trim();
    const data = await apiFetch("/api/admin/payments", { query: { status, q, page: currentPage, limit: PAGE_LIMIT } });
    const payments = data?.payments || data?.items || [];
    const pg = data?.pagination || {};
    qs("#paymentsTable", wrapper).innerHTML = renderTable({
      columns: [
        { label: "Số tiền", render: (p) => `<div><div style="font-weight:800;color:var(--success);font-size:14px;">${escapeHtml(formatMoney(p.amount))}</div><div style="font-size:12px;color:var(--text-muted);">${escapeHtml(p.method || "")}</div></div>` },
        { label: "Trạng thái", render: (p) => statusBadge("payment", p.status) },
        { label: "Khách", render: (p) => `<div><div style="font-weight:600;">${escapeHtml(p.user?.fullName || "-")}</div><div style="font-size:12px;color:var(--text-muted);">${escapeHtml(p.user?.email || "")}</div></div>` },
        { label: "Booking", render: (p) => `<span class="font-mono" style="font-size:12px;color:var(--accent);font-weight:700;">${escapeHtml(p.booking?.bookingCode || "-")}</span>` },
        { label: "Ngày TT", render: (p) => `<span class="font-mono" style="font-size:12px;">${escapeHtml(p.paidAt || "")}</span>` },
        { label: "Actions", render: (p) => `<div style="display:flex;gap:6px;">
          <button data-act="changePayStatus" data-id="${escapeHtml(p._id)}" data-status="${escapeHtml(p.status)}" class="btn-sm">${icons.edit} Trạng thái</button>
          <button data-act="viewPayment" data-json="${escapeHtml(JSON.stringify(p))}" class="btn-sm">👁 Chi tiết</button>
        </div>` },
      ],
      rows: payments,
    }) + renderPagination({ page: pg.page || currentPage, totalPages: pg.totalPages || 1, total: pg.total || payments.length, limit: PAGE_LIMIT, onPageChange: (p) => load(p).catch((e) => toast("error", "Lỗi", e.message)) });
  }

  wrapper.addEventListener("click", async (e) => {
    const btn = e.target.closest("button[data-act]");
    if (!btn) return;
    try {
      if (btn.dataset.act === "changePayStatus") {
        openModal({
          title: "🔄 Đổi trạng thái thanh toán",
          body: `<div style="display:flex;flex-direction:column;gap:16px;">
            ${field("Trạng thái mới", sel("newPStatus", [["pending","⏳ Pending"],["completed","✅ Completed"],["failed","❌ Failed"],["refunded","↩️ Refunded"]], btn.dataset.status))}
          </div>`,
          onConfirm: async (modal) => {
            await apiFetch(`/api/admin/payments/${btn.dataset.id}/status`, { method: "PATCH", body: { status: qs("#newPStatus", modal).value } });
            toast("success", "Đã cập nhật", "Trạng thái thanh toán đã thay đổi"); await load();
          }, confirmLabel: "Cập nhật",
        });
      }
      if (btn.dataset.act === "viewPayment") {
        const p = JSON.parse(btn.dataset.json || "{}");
        openModal({
          title: "💳 Chi tiết thanh toán",
          body: `<div style="display:grid;grid-template-columns:1fr 1fr;gap:14px;font-size:13.5px;">
            <div><span style="color:var(--text-muted);font-size:12px;font-weight:700;">SỐ TIỀN</span><div style="font-weight:800;color:var(--success);font-size:16px;margin-top:4px;">${escapeHtml(formatMoney(p.amount))}</div></div>
            <div><span style="color:var(--text-muted);font-size:12px;font-weight:700;">TRẠNG THÁI</span><div style="margin-top:4px;">${statusBadge("payment", p.status)}</div></div>
            <div><span style="color:var(--text-muted);font-size:12px;font-weight:700;">PHƯƠNG THỨC</span><div style="margin-top:4px;">${escapeHtml(p.method || "-")}</div></div>
            <div><span style="color:var(--text-muted);font-size:12px;font-weight:700;">NGÀY TT</span><div style="margin-top:4px;">${escapeHtml(p.paidAt || "-")}</div></div>
            <div><span style="color:var(--text-muted);font-size:12px;font-weight:700;">KHÁCH HÀNG</span><div style="font-weight:700;margin-top:4px;">${escapeHtml(p.user?.fullName || "-")}</div><div style="font-size:12px;color:var(--text-muted);">${escapeHtml(p.user?.email || "")}</div></div>
            <div><span style="color:var(--text-muted);font-size:12px;font-weight:700;">BOOKING</span><div class="font-mono" style="color:var(--accent);font-weight:700;margin-top:4px;">${escapeHtml(p.booking?.bookingCode || "-")}</div></div>
          </div>`,
        });
      }
    } catch (err) { toast("error", "Lỗi", err.message); }
  });

  qs("#btnPSearch", wrapper).onclick = () => load(1).catch((e) => toast("error", "Lỗi", e.message));
  await load();
  return wrapper;
}

// ─── Discounts ────────────────────────────────────────────────────────────────
async function renderDiscounts() {
  qs("#subTitle").textContent = "Quản lý mã giảm giá — tạo, chỉnh sửa, xoá, đổi trạng thái";
  const wrapper = h(`<div style="display:flex;flex-direction:column;gap:20px;">
    <div style="display:flex;justify-content:flex-end;">
      <button id="btnCreateDiscount" class="btn-primary">${icons.plus} Tạo mã giảm giá</button>
    </div>
    <div id="discountsTable"></div>
  </div>`);

  let currentPage = 1;
  const PAGE_LIMIT = 15;

  async function load(page) {
    if (page) currentPage = page;
    const data = await apiFetch("/api/admin/discounts", { query: { page: currentPage, limit: PAGE_LIMIT } });
    const discounts = data?.discounts || data?.items || [];
    const pg = data?.pagination || {};
    qs("#discountsTable", wrapper).innerHTML = renderTable({
      columns: [
        { label: "Mã", render: (d) => `<div><div class="font-mono" style="font-weight:800;color:var(--accent);">${escapeHtml(d.code || "-")}</div><div style="font-size:12px;color:var(--text-muted);">${escapeHtml(d.description || "")}</div></div>` },
        { label: "Loại", render: (d) => `<span style="font-weight:600;">${escapeHtml(d.discountType || "-")}</span>` },
        { label: "Giá trị", render: (d) => `<span style="font-weight:800;color:var(--warning);">${escapeHtml(d.discountType === "percent" ? `${d.discountValue || 0}%` : formatMoney(d.discountValue))}</span>` },
        { label: "Lượt dùng", render: (d) => `<span>${escapeHtml(d.usedCount || 0)} / ${escapeHtml(d.maxUsage || "∞")}</span>` },
        { label: "Trạng thái", render: (d) => statusBadge("discount", d.status) },
        { label: "Hết hạn", render: (d) => `<span class="font-mono" style="font-size:12px;">${escapeHtml(d.validTo ? d.validTo.substring(0, 10) : "")}</span>` },
        { label: "Actions", render: (d) => `<div style="display:flex;gap:6px;flex-wrap:wrap;">
          <button data-act="editDiscount" data-id="${escapeHtml(d._id)}" data-json="${escapeHtml(JSON.stringify(d))}" class="btn-sm">${icons.edit} Sửa</button>
          <button data-act="toggleDiscount" data-id="${escapeHtml(d._id)}" data-status="${escapeHtml(d.status)}" class="btn-sm">${d.status === "disabled" ? "✅ Kích hoạt" : "🚫 Vô hiệu"}</button>
          <button data-act="deleteDiscount" data-id="${escapeHtml(d._id)}" data-code="${escapeHtml(d.code || "-")}" class="btn-danger">${icons.trash} Xoá</button>
        </div>` },
      ],
      rows: discounts,
    }) + renderPagination({ page: pg.page || currentPage, totalPages: pg.totalPages || 1, total: pg.total || discounts.length, limit: PAGE_LIMIT, onPageChange: (p) => load(p).catch((e) => toast("error", "Lỗi", e.message)) });
  }

  function discountForm(d = {}) {
    return `<div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;">
      ${field("Mã voucher", inp("dCode", "text", d.code || "", "SUMMER20"))}
      ${field("Mô tả", inp("dDesc", "text", d.description || "", "Giảm 20% mùa hè"))}
      ${field("Loại giảm giá", sel("dType", [["percent","Phần trăm (%)"],["fixed","Số tiền cố định"]], d.discountType || "percent"))}
      ${field("Giá trị", inp("dValue", "number", d.discountValue || "", "20"))}
      ${field("Số lượt tối đa", inp("dMax", "number", d.maxUsage || "", "100"))}
      ${field("Đơn tối thiểu (VND)", inp("dMinOrder", "number", d.minOrderValue || "", "0"))}
      ${field("Hiệu lực từ", inp("dFrom", "date", d.validFrom ? d.validFrom.substring(0, 10) : ""))}
      ${field("Hết hạn", inp("dTo", "date", d.validTo ? d.validTo.substring(0, 10) : ""))}
      ${field("Trạng thái", sel("dStatus", [["active","Active"],["disabled","Vô hiệu"]], d.status || "active"))}
    </div>`;
  }

  wrapper.addEventListener("click", async (e) => {
    const btn = e.target.closest("button[data-act]");
    if (!btn) return;
    const act = btn.dataset.act; const id = btn.dataset.id;
    try {
      if (act === "editDiscount") {
        const d = JSON.parse(btn.dataset.json || "{}");
        openModal({
          title: "✏️ Chỉnh sửa mã giảm giá", body: discountForm(d), size: "560px",
          onConfirm: async (modal) => {
            const body = { code: qs("#dCode", modal).value.trim(), description: qs("#dDesc", modal).value.trim(), discountType: qs("#dType", modal).value, discountValue: Number(qs("#dValue", modal).value), maxUsage: Number(qs("#dMax", modal).value) || null, minOrderValue: Number(qs("#dMinOrder", modal).value) || 0, validFrom: qs("#dFrom", modal).value || null, validTo: qs("#dTo", modal).value || null, status: qs("#dStatus", modal).value };
            await apiFetch(`/api/admin/discounts/${id}`, { method: "PATCH", body });
            toast("success", "Đã cập nhật", "Mã giảm giá đã được lưu"); await load();
          }, confirmLabel: "Lưu thay đổi",
        });
      }
      if (act === "toggleDiscount") {
        const next = btn.dataset.status === "disabled" ? "active" : "disabled";
        await apiFetch(`/api/admin/discounts/${id}/status`, { method: "PATCH", body: { status: next } });
        toast("success", "Cập nhật thành công"); await load();
      }
      if (act === "deleteDiscount") {
        confirmDialog("🗑️ Xoá mã giảm giá", `Bạn có chắc muốn xoá mã "${btn.dataset.code}"?`, async () => {
          await apiFetch(`/api/admin/discounts/${id}`, { method: "DELETE" });
          toast("success", "Đã xoá"); await load();
        });
      }
    } catch (err) { toast("error", "Lỗi", err.message); }
  });

  qs("#btnCreateDiscount", wrapper).onclick = () => {
    openModal({
      title: "➕ Tạo mã giảm giá", body: discountForm(), size: "560px",
      onConfirm: async (modal) => {
        const body = { code: qs("#dCode", modal).value.trim(), description: qs("#dDesc", modal).value.trim(), discountType: qs("#dType", modal).value, discountValue: Number(qs("#dValue", modal).value), maxUsage: Number(qs("#dMax", modal).value) || null, minOrderValue: Number(qs("#dMinOrder", modal).value) || 0, validFrom: qs("#dFrom", modal).value || null, validTo: qs("#dTo", modal).value || null, status: qs("#dStatus", modal).value };
        await apiFetch("/api/admin/discounts", { method: "POST", body });
        toast("success", "Đã tạo", "Mã giảm giá mới đã được tạo"); await load();
      }, confirmLabel: "Tạo mã",
    });
  };

  await load();
  return wrapper;
}

// ─── Wallets ──────────────────────────────────────────────────────────────────
function tierBadge(tier) {
  const map = { member: ["Member","slate"], silver: ["Silver","blue"], gold: ["Gold","amber"], platinum: ["Platinum","purple"] };
  const conf = map[tier] || ["Member", "slate"];
  return badge(conf[0], conf[1]);
}

async function renderWallets() {
  qs("#subTitle").textContent = "Quản lý ví — số dư, điểm thưởng, hạng thành viên";
  const wrapper = h(`<div style="display:flex;flex-direction:column;gap:20px;">
    <div id="walletsSummary"></div>
    <div class="admin-card"><div class="admin-card-body">
      <div style="display:flex;flex-wrap:wrap;gap:12px;align-items:flex-end;">
        <div style="flex:1;min-width:200px;">
          <label style="font-size:11.5px;font-weight:700;color:var(--text-muted);text-transform:uppercase;letter-spacing:0.06em;display:block;margin-bottom:6px;">Tìm kiếm</label>
          <input id="wQ" class="admin-input" placeholder="Tên / email người dùng…" />
        </div>
        <div>
          <label style="font-size:11.5px;font-weight:700;color:var(--text-muted);text-transform:uppercase;letter-spacing:0.06em;display:block;margin-bottom:6px;">Hạng</label>
          <select id="wTier" class="admin-select"><option value="">Tất cả</option><option value="member">Member</option><option value="silver">Silver</option><option value="gold">Gold</option><option value="platinum">Platinum</option></select>
        </div>
        <button id="btnWSearch" class="btn-primary">${icons.search} Tìm kiếm</button>
      </div>
    </div></div>
    <div id="walletsTable"></div>
  </div>`);

  let currentPage = 1;
  const PAGE_LIMIT = 15;

  async function load(page) {
    if (page) currentPage = page;
    const q = qs("#wQ", wrapper).value.trim();
    const tier = qs("#wTier", wrapper).value;
    const data = await apiFetch("/api/admin/wallets", { query: { q, tier, page: currentPage, limit: PAGE_LIMIT } });
    const wallets = data?.wallets || [];
    const summary = data?.summary || {};
    const pg = data?.pagination || {};
    const tierCounts = summary.tierCounts || {};
    const tierSummary = ["member","silver","gold","platinum"].map((t) => `${t[0].toUpperCase()+t.slice(1)}: ${tierCounts[t]||0}`).join(" · ");

    qs("#walletsSummary", wrapper).innerHTML = renderCardGrid([
      { label: "Tổng ví", value: String(summary.totalWallets || 0) },
      { label: "Tổng số dư", value: formatMoney(summary.totalBalance || 0) },
      { label: "Tổng điểm", value: String(summary.totalPoints || 0).replace(/\B(?=(\d{3})+(?!\d))/g, ".") },
      { label: "Phân bố hạng", value: String(summary.totalWallets || 0), hint: tierSummary },
    ]);

    qs("#walletsTable", wrapper).innerHTML = renderTable({
      columns: [
        { label: "Người dùng", render: (w) => {
          const u = w.user || {};
          return `<div style="display:flex;align-items:center;gap:12px;">
            <div class="avatar" style="width:38px;height:38px;border-radius:10px;background:linear-gradient(135deg,#6366f1,#8b5cf6);font-size:14px;">${escapeHtml((u.fullName || "?")[0].toUpperCase())}</div>
            <div><div style="font-weight:700;">${escapeHtml(u.fullName || "-")}</div><div style="font-size:12px;color:var(--text-muted);">${escapeHtml(u.email || "")}</div>${u.phone ? `<div style="font-size:12px;color:var(--text-muted);">${escapeHtml(u.phone)}</div>` : ""}</div>
          </div>`;
        }},
        { label: "Số dư", render: (w) => `<span style="font-weight:800;color:var(--success);font-size:14px;">${escapeHtml(formatMoney(w.balance))}</span>` },
        { label: "Điểm", render: (w) => `<span style="font-weight:800;color:var(--accent);font-size:14px;">${escapeHtml(String(w.points || 0))}</span>` },
        { label: "Hạng", render: (w) => tierBadge(w.tier) },
        { label: "Actions", render: (w) => `<button data-act="editWallet" data-id="${escapeHtml(w._id)}" data-balance="${w.balance || 0}" data-points="${w.points || 0}" data-tier="${escapeHtml(w.tier || "member")}" data-username="${escapeHtml(w.user?.fullName || "-")}" class="btn-sm">${icons.edit} Sửa</button>` },
      ],
      rows: wallets,
    }) + renderPagination({ page: pg.page || currentPage, totalPages: pg.totalPages || 1, total: pg.total || wallets.length, limit: PAGE_LIMIT, onPageChange: (p) => load(p).catch((e) => toast("error", "Lỗi", e.message)) });
  }

  wrapper.addEventListener("click", async (e) => {
    const btn = e.target.closest("button[data-act]");
    if (!btn || btn.dataset.act !== "editWallet") return;
    const tierInfo = { member: "0 – 499 điểm", silver: "500 – 1.499 điểm", gold: "1.500 – 2.999 điểm", platinum: "3.000+ điểm" };
    openModal({
      title: `💰 Chỉnh sửa ví — ${btn.dataset.username}`,
      body: `<div style="display:flex;flex-direction:column;gap:16px;">
        <div class="detail-section">
          <div class="detail-section-title">Hạng hiện tại</div>
          <div style="display:flex;align-items:center;gap:8px;">${tierBadge(btn.dataset.tier)}<span style="font-size:12px;color:var(--text-muted);">(${tierInfo[btn.dataset.tier] || ""})</span></div>
        </div>
        ${field("Số dư (VND)", inp("editBalance", "number", btn.dataset.balance, "0"))}
        ${field("Điểm thưởng", inp("editPoints", "number", btn.dataset.points, "0"))}
        <div style="padding:12px 14px;background:var(--info-light);border-radius:10px;border:1px solid #bfdbfe;">
          <div style="font-size:12px;color:var(--info);font-weight:600;">ℹ️ Hạng sẽ tự động cập nhật khi thay đổi điểm:</div>
          <div style="font-size:11.5px;color:var(--text-secondary);margin-top:4px;">Member: 0–499 · Silver: 500–1.499 · Gold: 1.500–2.999 · Platinum: 3.000+</div>
        </div>
      </div>`,
      onConfirm: async (modal) => {
        const body = { balance: Number(qs("#editBalance", modal).value), points: Number(qs("#editPoints", modal).value) };
        if (isNaN(body.balance) || body.balance < 0) throw new Error("Số dư không hợp lệ");
        if (isNaN(body.points) || body.points < 0) throw new Error("Điểm không hợp lệ");
        await apiFetch(`/api/admin/wallets/${btn.dataset.id}`, { method: "PATCH", body });
        toast("success", "Đã cập nhật", "Thông tin ví đã được lưu"); await load();
      }, confirmLabel: "Lưu thay đổi",
    });
  });

  qs("#btnWSearch", wrapper).onclick = () => load(1).catch((e) => toast("error", "Lỗi", e.message));
  qs("#wQ", wrapper).addEventListener("keydown", (e) => { if (e.key === "Enter") load(1).catch((err) => toast("error", "Lỗi", err.message)); });
  await load();
  return wrapper;
}

// ─── Settings ─────────────────────────────────────────────────────────────────
async function renderSettings() {
  qs("#subTitle").textContent = "Cấu hình API và xác thực";
  const apiBase = getApiBaseUrl();
  const token = getToken();
  return `<div style="max-width:640px;display:flex;flex-direction:column;gap:20px;">
    <div class="admin-card">
      <div class="admin-card-header"><div class="card-icon" style="background:rgba(99,102,241,0.1);">🔗</div> API Base URL</div>
      <div class="admin-card-body">
        <div style="font-size:13px;color:var(--text-muted);margin-bottom:12px;">Ví dụ: <code class="font-mono" style="background:var(--surface-hover);padding:3px 8px;border-radius:6px;font-size:12px;color:var(--accent);">${escapeHtml(window.location.origin)}</code></div>
        <div style="display:flex;gap:10px;">
          <input id="apiBaseInput" class="admin-input" value="${escapeHtml(apiBase)}" style="flex:1;" />
          <button id="btnSaveApiBase" class="btn-primary">Lưu</button>
        </div>
      </div>
    </div>
    <div class="admin-card">
      <div class="admin-card-header"><div class="card-icon" style="background:rgba(16,185,129,0.1);">🔑</div> Xác thực</div>
      <div class="admin-card-body">
        <div style="display:flex;align-items:center;gap:8px;margin-bottom:14px;">
          <span style="font-size:13px;color:var(--text-secondary);font-weight:600;">Token:</span>
          ${token ? badge("Đã thiết lập", "green") : badge("Chưa có", "red")}
        </div>
        ${token ? `<div class="font-mono" style="background:var(--surface-hover);border:1px solid var(--border);border-radius:10px;padding:12px 14px;font-size:11.5px;color:var(--text-muted);word-break:break-all;margin-bottom:14px;">${escapeHtml(token.substring(0, 48))}…</div>` : ""}
        <div style="display:flex;gap:10px;">
          <button id="btnForceLogin" class="btn-ghost">Đăng nhập lại</button>
          <button id="btnClearAuth" class="btn-ghost" style="color:var(--danger);border-color:#fecaca;">Xoá token</button>
        </div>
      </div>
    </div>
    <div class="admin-card">
      <div class="admin-card-header"><div class="card-icon" style="background:rgba(245,158,11,0.1);">🩺</div> Health Check</div>
      <div class="admin-card-body">
        <div style="display:flex;gap:10px;margin-bottom:14px;">
          <button id="btnPing" class="btn-primary">Ping /</button>
          <button id="btnAdminPing" class="btn-ghost">Ping Admin Overview</button>
        </div>
        <pre id="pingOut" class="font-mono" style="background:#0f1117;color:#a3e635;border-radius:12px;padding:16px;font-size:12px;max-height:220px;overflow:auto;margin:0;line-height:1.6;"></pre>
      </div>
    </div>
    <div class="admin-card">
      <div class="admin-card-header"><div class="card-icon" style="background:rgba(99,102,241,0.1);">ℹ️</div> System Info</div>
      <div class="admin-card-body">
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;font-size:13px;">
          <div><span style="color:var(--text-muted);font-weight:700;">Version</span><div style="margin-top:4px;">2.0.0</div></div>
          <div><span style="color:var(--text-muted);font-weight:700;">Build</span><div style="margin-top:4px;" class="font-mono" style="font-size:12px;">${new Date().toISOString().split("T")[0]}</div></div>
          <div><span style="color:var(--text-muted);font-weight:700;">API Endpoint</span><div style="margin-top:4px;" class="font-mono" style="font-size:12px;">${escapeHtml(apiBase)}</div></div>
          <div><span style="color:var(--text-muted);font-weight:700;">Browser</span><div style="margin-top:4px;font-size:12px;">${escapeHtml(navigator.userAgent.split(' ').pop())}</div></div>
        </div>
      </div>
    </div>
  </div>`;
}

// ─── Mount + Render route ─────────────────────────────────────────────────────
function mountContent(nodeOrHtml) {
  const contentEl = qs("#content");
  contentEl.innerHTML = "";
  if (typeof nodeOrHtml === "string") contentEl.innerHTML = nodeOrHtml;
  else contentEl.appendChild(nodeOrHtml);
}

async function renderRoute() {
  const id = currentRouteId();
  document.querySelectorAll(".nav-item").forEach((el) => {
    const itemId = (el.getAttribute("href") || "").replace("#/", "");
    el.classList.toggle("active", itemId === id);
  });
  const titleEl = document.querySelector("#topbar .route-title");
  if (titleEl) titleEl.textContent = routes.find((r) => r.id === id)?.label || "Dashboard";

  // Update breadcrumb
  const bc = qs(".breadcrumb");
  if (bc) {
    const currentRoute = routes.find((r) => r.id === id);
    bc.innerHTML = `<a href="#/dashboard">Dashboard</a>${id !== "dashboard" ? `<span class="breadcrumb-sep">${icons.chevRight}</span><span style="font-weight:600;color:var(--text-primary);">${escapeHtml(currentRoute?.label || "")}</span>` : ""}`;
  }

  const authed = await ensureAuthed();
  mountContent(`<div style="display:flex;flex-direction:column;gap:20px;">
    <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:20px;">${[0,1,2,3].map(() => `<div class="skeleton" style="height:120px;"></div>`).join("")}</div>
    <div class="skeleton" style="height:320px;"></div>
  </div>`);

  if (!authed) {
    mountContent(`<div class="admin-card"><div class="empty-state"><div class="empty-state-icon">🔐</div><div class="empty-state-text">Vui lòng đăng nhập để tiếp tục</div></div></div>`);
    return;
  }

  try {
    const domPages = ["users", "courts", "bookings", "payments", "discounts", "wallets"];
    if (domPages.includes(id)) {
      let node;
      if (id === "users") node = await renderUsers();
      else if (id === "courts") node = await renderCourts();
      else if (id === "bookings") node = await renderBookings();
      else if (id === "payments") node = await renderPayments();
      else if (id === "discounts") node = await renderDiscounts();
      else if (id === "wallets") node = await renderWallets();
      mountContent(node);
    } else {
      let html = "";
      if (id === "dashboard") html = await renderDashboard();
      else if (id === "settings") html = await renderSettings();
      else html = await renderDashboard();
      mountContent(html);
      bindPageHandlers();
    }
  } catch (err) {
    if (err.status === 401 || err.status === 403) {
      clearAuth();
      toast("error", "Phiên hết hạn", "Vui lòng đăng nhập lại.");
      await ensureAuthed();
    } else {
      toast("error", "Lỗi", err.message);
    }
    mountContent(`<div class="admin-card" style="padding:32px;display:flex;align-items:flex-start;gap:16px;">
      <div style="width:44px;height:44px;background:var(--danger-light);border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:20px;flex-shrink:0;">❌</div>
      <div><div style="font-weight:800;color:var(--danger);margin-bottom:4px;">Có lỗi xảy ra</div><div style="font-size:13.5px;color:var(--text-muted);">${escapeHtml(err.message)}</div></div>
    </div>`);
  }
}

function bindPageHandlers() {
  const btnSave = qs("#btnSaveApiBase");
  if (btnSave) btnSave.onclick = () => { setApiBaseUrl(qs("#apiBaseInput").value.trim()); toast("success", "Đã lưu", "API Base URL đã được cập nhật"); setTimeout(() => window.location.reload(), 500); };
  const btnClear = qs("#btnClearAuth");
  if (btnClear) btnClear.onclick = () => { clearAuth(); toast("success", "Đã xoá", "Token đã được xoá"); setTimeout(() => window.location.reload(), 500); };
  const btnLogin = qs("#btnForceLogin");
  if (btnLogin) btnLogin.onclick = () => ensureAuthed();
  const btnPing = qs("#btnPing");
  if (btnPing) btnPing.onclick = async () => { const out = qs("#pingOut"); out.textContent = "Loading…"; try { const res = await fetch(`${getApiBaseUrl()}/`); out.textContent = `HTTP ${res.status}\n\n${await res.text()}`; } catch (e) { out.textContent = e.message; } };
  const btnAdminPing = qs("#btnAdminPing");
  if (btnAdminPing) btnAdminPing.onclick = async () => { const out = qs("#pingOut"); out.textContent = "Loading…"; try { const data = await apiFetch("/api/admin/dashboard/overview"); out.textContent = JSON.stringify(data, null, 2); } catch (e) { out.textContent = `${e.message}\n\n${JSON.stringify(e.data || {}, null, 2)}`; } };
}

// ─── Boot ─────────────────────────────────────────────────────────────────────
function boot() {
  qs("#app").innerHTML = layout();
  qs("#btnRefresh").addEventListener("click", () => renderRoute());
  const btnLogout = qs("#btnLogout");
  if (btnLogout) btnLogout.addEventListener("click", () => (clearAuth(), window.location.reload()));
  window.addEventListener("hashchange", () => renderRoute());

  qs("#loginForm").addEventListener("submit", async (e) => {
    e.preventDefault();
    const fd = new FormData(e.target);
    const email = String(fd.get("email") || "").trim();
    const password = String(fd.get("password") || "").trim();
    const btn = e.target.querySelector("button[type=submit]");
    btn.textContent = "Đang đăng nhập…"; btn.disabled = true;
    try {
      await loginAsAdmin({ email, password });
      toast("success", "Đăng nhập thành công", "Xin chào, Admin!");
      closeLogin();
      if (!window.location.hash || window.location.hash === "#/") setRoute("dashboard");
      await renderRoute();
    } catch (err) {
      toast("error", "Đăng nhập thất bại", err.message);
      btn.textContent = "Đăng nhập"; btn.disabled = false;
    }
  });

  if (!window.location.hash) setRoute("dashboard");
  renderRoute();
}

boot();

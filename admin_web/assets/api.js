// ─── API helpers (inlined) ────────────────────────────────────────────────────
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

async function apiFetch(path, { method = "GET", query, body, headers } = {}) {
  const base = getApiBaseUrl();
  const url = new URL(`${base}${path.startsWith("/") ? "" : "/"}${path}`);
  if (query) for (const [k, v] of Object.entries(query)) {
    if (v === undefined || v === null || v === "") continue;
    url.searchParams.set(k, String(v));
  }
  const token = getToken();
  const res = await fetch(url.toString(), {
    method,
    headers: {
      ...(body ? { "Content-Type": "application/json" } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(headers || {}),
    },
    body: body ? JSON.stringify(body) : undefined,
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
  dashboard: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/></svg>`,
  users:     `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>`,
  courts:    `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>`,
  bookings:  `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>`,
  payments:  `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>`,
  discounts: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"/><line x1="7" y1="7" x2="7.01" y2="7"/></svg>`,
  settings:  `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.07 4.93A10 10 0 0 0 6.99 3.34L5.5 5.5M4.93 19.07A10 10 0 0 0 17.01 20.66l1.49-2.16M20.66 6.99A10 10 0 0 1 22 12c0 1.93-.55 3.73-1.5 5.25"/><path d="M3.34 17.01A10 10 0 0 1 2 12c0-1.93.55-3.73 1.5-5.25"/></svg>`,
  refresh:   `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg>`,
  logout:    `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>`,
  plus:      `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>`,
  edit:      `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>`,
  trash:     `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg>`,
  x:         `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>`,
};

const routes = [
  { id: "dashboard", label: "Dashboard",  icon: icons.dashboard },
  { id: "users",     label: "Users",       icon: icons.users },
  { id: "courts",    label: "Courts",      icon: icons.courts },
  { id: "bookings",  label: "Bookings",    icon: icons.bookings },
  { id: "payments",  label: "Payments",    icon: icons.payments },
  { id: "discounts", label: "Discounts",   icon: icons.discounts },
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

// ─── Badge ────────────────────────────────────────────────────────────────────
function badge(text, tone = "slate") {
  const tones = {
    slate:  { bg: "#f1f3f9", color: "#5a6384", dot: "#8b93a8" },
    green:  { bg: "#edfbf3", color: "#1d8a4e", dot: "#34c96a" },
    red:    { bg: "#fff0f0", color: "#c0392b", dot: "#e74c3c" },
    amber:  { bg: "#fffbeb", color: "#b45309", dot: "#f59e0b" },
    blue:   { bg: "#eff6ff", color: "#1d5fad", dot: "#3b82f6" },
    purple: { bg: "#f5f0ff", color: "#6d28d9", dot: "#8b5cf6" },
  };
  const t = tones[tone] || tones.slate;
  return `<span class="badge" style="background:${t.bg};color:${t.color};">
    <span style="display:inline-block;width:5px;height:5px;border-radius:50%;background:${t.dot};flex-shrink:0;"></span>
    ${escapeHtml(text)}
  </span>`;
}

function statusBadge(kind, value) {
  const v = String(value || "").toLowerCase();
  const map = {
    booking:  { pending: ["pending","amber"], confirmed: ["confirmed","green"], cancelled: ["cancelled","red"], completed: ["completed","blue"] },
    user:     { active: ["active","green"], locked: ["locked","red"] },
    payment:  { pending: ["pending","amber"], completed: ["completed","green"], failed: ["failed","red"], refunded: ["refunded","purple"] },
    discount: { active: ["active","green"], expired: ["expired","amber"], disabled: ["disabled","red"] },
    court:    { active: ["active","green"], maintenance: ["maintenance","amber"] },
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
    <div id="globalModal" style="position:fixed;inset:0;z-index:300;display:flex;align-items:center;justify-content:center;padding:16px;background:rgba(15,17,23,0.55);backdrop-filter:blur(4px);-webkit-backdrop-filter:blur(4px);">
      <div style="background:#fff;border-radius:20px;width:100%;max-width:${size};box-shadow:0 30px 80px rgba(0,0,0,0.18);animation:pageFade 0.18s ease;">
        <div style="padding:20px 24px 0;display:flex;align-items:center;justify-content:space-between;">
          <div style="font-size:15px;font-weight:700;color:#1e2235;">${title}</div>
          <button id="modalClose" style="background:none;border:none;cursor:pointer;color:#8b93a8;padding:4px;border-radius:6px;display:flex;align-items:center;justify-content:center;transition:background 0.15s;" onmouseover="this.style.background='#f4f5fb'" onmouseout="this.style.background='none'">${icons.x}</button>
        </div>
        <div style="padding:20px 24px;" id="modalBody">${body}</div>
        ${onConfirm ? `<div style="padding:0 24px 20px;display:flex;gap:10px;justify-content:flex-end;">
          <button id="modalCancel" class="btn-ghost">Huỷ</button>
          <button id="modalConfirm" class="${confirmClass}">${confirmLabel}</button>
        </div>` : `<div style="padding:0 24px 20px;display:flex;justify-content:flex-end;"><button id="modalCancel" class="btn-ghost">Đóng</button></div>`}
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
    body: `<p style="color:#5a6384;font-size:14px;margin:0;">${escapeHtml(message)}</p>`,
    onConfirm,
    confirmLabel: "Xác nhận",
    confirmClass: "btn-danger",
  });
}

// ─── Layout ───────────────────────────────────────────────────────────────────
function layout() {
  const routeId = currentRouteId();
  const token = getToken();
  const mainRoutes = routes.filter((r) => r.id !== "settings");

  return `
  <div style="display:flex;min-height:100vh;">
    <aside id="sidebar" style="width:260px;flex-shrink:0;display:flex;flex-direction:column;position:sticky;top:0;height:100vh;overflow-y:auto;">
      <div style="padding:24px 20px 20px;display:flex;align-items:center;gap:12px;">
        <div style="width:36px;height:36px;border-radius:10px;background:linear-gradient(135deg,#6366f1,#4f46e5);display:flex;align-items:center;justify-content:center;box-shadow:0 4px 12px rgba(99,102,241,0.4);flex-shrink:0;">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/><line x1="2" y1="12" x2="22" y2="12"/></svg>
        </div>
        <div>
          <div style="font-size:15px;font-weight:700;color:#fff;letter-spacing:-0.01em;">Booking Admin</div>
          <div style="font-size:10.5px;color:rgba(255,255,255,0.35);font-family:'JetBrains Mono',monospace;margin-top:1px;">${escapeHtml(getApiBaseUrl().replace(/https?:\/\//, ""))}</div>
        </div>
      </div>
      <nav style="padding:4px 12px;flex:1;">
        <div style="font-size:10px;font-weight:700;letter-spacing:0.1em;color:rgba(255,255,255,0.25);padding:0 6px;margin-bottom:6px;text-transform:uppercase;">Menu</div>
        ${mainRoutes.map((r) => `<a href="#/${r.id}" class="nav-item${r.id === routeId ? " active" : ""}">
          <span class="nav-icon">${r.icon}</span>
          <span style="flex:1;">${escapeHtml(r.label)}</span>
          <span class="nav-dot"></span>
        </a>`).join("")}
        <div style="height:1px;background:rgba(255,255,255,0.07);margin:12px 6px;"></div>
        <a href="#/settings" class="nav-item${routeId === "settings" ? " active" : ""}">
          <span class="nav-icon">${icons.settings}</span>
          <span>Settings</span>
        </a>
      </nav>
      <div style="padding:14px 16px;border-top:1px solid rgba(255,255,255,0.07);margin:8px;border-radius:12px;background:rgba(255,255,255,0.04);">
        <div style="display:flex;align-items:center;gap:10px;">
          <div style="width:32px;height:32px;border-radius:10px;background:linear-gradient(135deg,#6366f1,#8b5cf6);display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:700;color:#fff;flex-shrink:0;">A</div>
          <div style="flex:1;min-width:0;">
            <div style="font-size:13px;font-weight:600;color:#fff;">Administrator</div>
            <div style="font-size:11px;color:rgba(255,255,255,0.3);">Super Admin</div>
          </div>
        </div>
      </div>
    </aside>

    <main style="flex:1;min-width:0;display:flex;flex-direction:column;">
      <header id="topbar" style="position:sticky;top:0;z-index:10;padding:0 28px;">
        <div style="display:flex;align-items:center;justify-content:space-between;height:62px;">
          <div>
            <div class="route-title" style="font-size:18px;font-weight:700;letter-spacing:-0.02em;color:#1e2235;">${escapeHtml(routes.find((r) => r.id === routeId)?.label || "Dashboard")}</div>
            <div id="subTitle" style="font-size:12px;color:#8b93a8;margin-top:1px;"></div>
          </div>
          <div style="display:flex;align-items:center;gap:10px;">
            <span class="status-pill">Live</span>
            <button id="btnRefresh" class="btn-ghost" style="display:flex;align-items:center;gap:7px;padding:8px 14px;">${icons.refresh}<span style="font-size:13px;">Refresh</span></button>
            ${token ? `<button id="btnLogout" class="btn-ghost" style="display:flex;align-items:center;gap:7px;padding:8px 14px;color:#dc3545;border-color:#fcd0d0;">${icons.logout}<span style="font-size:13px;">Logout</span></button>` : ""}
          </div>
        </div>
      </header>
      <div style="padding:24px 28px;flex:1;">
        <div id="toastHost" style="position:fixed;right:24px;top:24px;z-index:200;display:flex;flex-direction:column;gap:8px;"></div>
        <div id="content"></div>
      </div>
    </main>
  </div>

  <div id="loginModal" style="position:fixed;inset:0;z-index:100;display:none;align-items:center;justify-content:center;padding:16px;background:rgba(15,17,23,0.7);">
    <div class="login-box">
      <div style="display:flex;align-items:center;gap:12px;margin-bottom:28px;">
        <div style="width:42px;height:42px;border-radius:12px;background:linear-gradient(135deg,#6366f1,#4f46e5);display:flex;align-items:center;justify-content:center;box-shadow:0 4px 14px rgba(99,102,241,0.4);">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/><line x1="2" y1="12" x2="22" y2="12"/></svg>
        </div>
        <div>
          <div style="font-size:19px;font-weight:700;color:#1e2235;letter-spacing:-0.02em;">Đăng nhập Admin</div>
          <div style="font-size:12.5px;color:#8b93a8;margin-top:2px;">Tài khoản có role <strong style="color:#6366f1;">admin</strong></div>
        </div>
      </div>
      <form id="loginForm" style="display:flex;flex-direction:column;gap:16px;">
        <div>
          <label style="font-size:12px;font-weight:600;color:#5a6384;display:block;margin-bottom:6px;">Email</label>
          <input name="email" type="email" class="admin-input" placeholder="admin@example.com" required />
        </div>
        <div>
          <label style="font-size:12px;font-weight:600;color:#5a6384;display:block;margin-bottom:6px;">Mật khẩu</label>
          <input name="password" type="password" class="admin-input" placeholder="••••••••" required />
        </div>
        <button type="submit" class="btn-primary" style="margin-top:4px;width:100%;padding:11px;font-size:14px;">Đăng nhập</button>
      </form>
    </div>
  </div>
  `;
}

// ─── Toast ────────────────────────────────────────────────────────────────────
function toast(type, title, detail) {
  const host = qs("#toastHost");
  if (!host) return;
  const styles = {
    error:   { bg: "#fff0f0", border: "#fcd0d0", color: "#c0392b", icon: "✗" },
    success: { bg: "#edfbf3", border: "#b8f0d0", color: "#1d8a4e", icon: "✓" },
    info:    { bg: "#eff6ff", border: "#bdd9f8", color: "#1d5fad", icon: "i" },
  };
  const s = styles[type] || styles.info;
  const el = h(`<div class="toast-item" style="background:${s.bg};border:1px solid ${s.border};color:${s.color};">
    <div style="display:flex;align-items:flex-start;gap:10px;">
      <span style="width:20px;height:20px;border-radius:50%;background:${s.color};color:#fff;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:700;flex-shrink:0;margin-top:1px;">${s.icon}</span>
      <div><div style="font-weight:700;font-size:13.5px;">${escapeHtml(title)}</div>${detail ? `<div style="font-size:12px;opacity:0.85;margin-top:2px;">${escapeHtml(detail)}</div>` : ""}</div>
    </div>
  </div>`);
  host.appendChild(el);
  setTimeout(() => { el.style.transition = "opacity 0.3s"; el.style.opacity = "0"; setTimeout(() => el.remove(), 300); }, 3200);
}

// ─── Metric cards ─────────────────────────────────────────────────────────────
const metricThemes = [
  { bg: "#6366f1", light: "rgba(99,102,241,0.08)", glyph: "📋" },
  { bg: "#10b981", light: "rgba(16,185,129,0.08)", glyph: "💰" },
  { bg: "#f59e0b", light: "rgba(245,158,11,0.08)", glyph: "👤" },
  { bg: "#3b82f6", light: "rgba(59,130,246,0.08)", glyph: "🏟️" },
];

function renderCardGrid(cards) {
  return `<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:16px;">
    ${cards.map((c, i) => {
      const t = metricThemes[i % metricThemes.length];
      return `<div class="metric-card" style="--card-accent:${t.light};">
        <div class="metric-icon" style="background:${t.light};"><span style="font-size:18px;">${t.glyph}</span></div>
        <div style="font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:0.07em;color:#8b93a8;">${escapeHtml(c.label)}</div>
        <div style="font-size:26px;font-weight:700;color:#1e2235;margin-top:4px;letter-spacing:-0.02em;">${escapeHtml(c.value)}</div>
        ${c.hint ? `<div style="font-size:12px;color:#8b93a8;margin-top:4px;">${escapeHtml(c.hint)}</div>` : ""}
      </div>`;
    }).join("")}
  </div>`;
}

// ─── Table ────────────────────────────────────────────────────────────────────
function renderTable({ columns, rows, rowKey }) {
  if (!rows || rows.length === 0) {
    return `<div class="admin-card" style="padding:48px;text-align:center;color:#8b93a8;">
      <div style="font-size:32px;margin-bottom:10px;">📭</div>
      <div style="font-size:14px;font-weight:600;">Không có dữ liệu</div>
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

// ─── Input builder ────────────────────────────────────────────────────────────
function field(label, inputHtml) {
  return `<div style="display:flex;flex-direction:column;gap:5px;">
    <label style="font-size:11.5px;font-weight:700;color:#8b93a8;text-transform:uppercase;letter-spacing:0.06em;">${escapeHtml(label)}</label>
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

// ─── Dashboard ────────────────────────────────────────────────────────────────
async function renderDashboard() {
  qs("#subTitle").textContent = "Tổng quan hệ thống — 30 ngày gần nhất";
  const data = await apiFetch("/api/admin/dashboard/overview");
  const m = data?.metrics || {};
  const top = data?.topCourts || [];
  const cards = [
    { label: "Total Bookings", value: String(m.bookingsTotal ?? 0) },
    { label: "Revenue",        value: formatMoney(m.revenue ?? 0), hint: `${m.revenuePaymentsCount ?? 0} payments` },
    { label: "New Users",      value: String(m.newUsersTotal ?? 0) },
    { label: "Courts",         value: String(m.courtsTotal ?? 0) },
  ];
  const bookingBreakdown = data?.breakdown?.bookingsByStatus || [];
  const paymentBreakdown = data?.breakdown?.paymentsByStatus || [];
  return `
    ${renderCardGrid(cards)}
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-top:20px;">
      <div class="admin-card">
        <div class="admin-card-header"><span style="font-size:16px;">📊</span> Bookings by Status</div>
        <div class="admin-card-body" style="padding:16px 20px;">
          ${bookingBreakdown.length === 0 ? `<div style="color:#8b93a8;font-size:13px;">Không có dữ liệu</div>` :
            bookingBreakdown.map((x) => {
              const s = x?._id || "-";
              const pct = m.bookingsTotal ? Math.round((x.count / m.bookingsTotal) * 100) : 0;
              return `<div style="margin-bottom:12px;">
                <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:5px;">
                  <div style="display:flex;align-items:center;gap:8px;">${statusBadge("booking", s)}</div>
                  <span style="font-size:13px;font-weight:700;color:#1e2235;">${escapeHtml(x.count || 0)}</span>
                </div>
                <div style="height:4px;background:#f0f2f8;border-radius:4px;overflow:hidden;"><div style="height:100%;width:${pct}%;background:#6366f1;border-radius:4px;transition:width 0.6s ease;"></div></div>
              </div>`;
            }).join("")}
        </div>
      </div>
      <div class="admin-card">
        <div class="admin-card-header"><span style="font-size:16px;">💳</span> Payments by Status</div>
        <div class="admin-card-body" style="padding:16px 20px;">
          ${paymentBreakdown.length === 0 ? `<div style="color:#8b93a8;font-size:13px;">Không có dữ liệu</div>` :
            paymentBreakdown.map((x) => {
              const s = x?._id || "-";
              return `<div style="display:flex;align-items:center;justify-content:space-between;padding:9px 0;border-bottom:1px solid #f4f5f9;">
                <div style="display:flex;align-items:center;gap:8px;">${statusBadge("payment", s)}</div>
                <span style="font-size:13px;font-weight:700;color:#1e2235;">${escapeHtml(x.count || 0)}</span>
              </div>`;
            }).join("")}
        </div>
      </div>
    </div>
    <div style="margin-top:20px;">
      <div class="admin-card">
        <div class="admin-card-header"><span style="font-size:16px;">🏆</span> Top Courts</div>
        ${renderTable({
          columns: [
            { label: "Court",    render: (r) => `<div style="font-weight:600;">${escapeHtml(r.courtName || "-")}</div><div style="font-size:12px;color:#8b93a8;">${escapeHtml(r.category || "")}</div>` },
            { label: "Bookings", render: (r) => `<span style="font-weight:600;">${escapeHtml(r.bookings)}</span>` },
            { label: "Revenue",  render: (r) => `<span style="font-weight:600;color:#10b981;">${escapeHtml(formatMoney(r.revenue))}</span>` },
          ],
          rows: top,
        })}
      </div>
    </div>`;
}

// ─── Users (full CRUD) ────────────────────────────────────────────────────────
async function renderUsers() {
  qs("#subTitle").textContent = "Quản lý người dùng — tìm kiếm, khoá/mở, đổi quyền, tạo, xoá";

  const wrapper = h(`<div style="display:flex;flex-direction:column;gap:16px;">
    <div class="admin-card">
      <div class="admin-card-body" style="padding:16px 20px;">
        <div style="display:flex;flex-wrap:wrap;gap:12px;align-items:flex-end;">
          <div style="flex:1;min-width:200px;">
            <label style="font-size:11.5px;font-weight:700;color:#8b93a8;text-transform:uppercase;letter-spacing:0.06em;display:block;margin-bottom:6px;">Tìm kiếm</label>
            <input id="q" class="admin-input" placeholder="Tên / email / số điện thoại…" />
          </div>
          <div>
            <label style="font-size:11.5px;font-weight:700;color:#8b93a8;text-transform:uppercase;letter-spacing:0.06em;display:block;margin-bottom:6px;">Trạng thái</label>
            <select id="status" class="admin-select"><option value="">Tất cả</option><option value="active">Active</option><option value="locked">Locked</option></select>
          </div>
          <div>
            <label style="font-size:11.5px;font-weight:700;color:#8b93a8;text-transform:uppercase;letter-spacing:0.06em;display:block;margin-bottom:6px;">Quyền</label>
            <select id="role" class="admin-select"><option value="">Tất cả</option><option value="customer">Customer</option><option value="admin">Admin</option></select>
          </div>
          <button id="btnSearch" class="btn-primary" style="display:flex;align-items:center;gap:6px;">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
            Tìm kiếm
          </button>
          <button id="btnCreateUser" class="btn-primary" style="display:flex;align-items:center;gap:6px;">${icons.plus} Tạo user</button>
        </div>
      </div>
    </div>
    <div id="usersTable"></div>
  </div>`);

  async function load() {
    const q = qs("#q", wrapper).value.trim();
    const status = qs("#status", wrapper).value;
    const role = qs("#role", wrapper).value;
    const data = await apiFetch("/api/admin/users", { query: { q, status, role, page: 1, limit: 50 } });
    const users = data?.users || [];
    qs("#usersTable", wrapper).innerHTML = renderTable({
      columns: [
        { label: "User", render: (u) => `<div style="display:flex;align-items:center;gap:10px;">
          <div style="width:34px;height:34px;border-radius:10px;background:linear-gradient(135deg,#6366f1,#8b5cf6);display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:700;color:#fff;flex-shrink:0;">${escapeHtml((u.fullName || "?")[0].toUpperCase())}</div>
          <div><div style="font-weight:600;">${escapeHtml(u.fullName || "-")}</div><div style="font-size:12px;color:#8b93a8;">${escapeHtml(u.email || "")}</div>${u.phone ? `<div style="font-size:12px;color:#8b93a8;">${escapeHtml(u.phone)}</div>` : ""}</div>
        </div>` },
        { label: "Role",   render: (u) => badge(u.role || "-", u.role === "admin" ? "purple" : "slate") },
        { label: "Status", render: (u) => statusBadge("user", u.status) },
        { label: "Actions", render: (u) => `<div style="display:flex;gap:6px;flex-wrap:wrap;">
          <button data-act="toggleLock" data-id="${escapeHtml(u._id)}" data-status="${escapeHtml(u.status)}" class="${u.status === "locked" ? "btn-sm" : "btn-danger"}" style="font-size:12px;display:flex;align-items:center;gap:4px;">${u.status === "locked" ? "🔓 Unlock" : "🔒 Lock"}</button>
          <button data-act="toggleRole" data-id="${escapeHtml(u._id)}" data-role="${escapeHtml(u.role)}" class="btn-sm" style="font-size:12px;display:flex;align-items:center;gap:4px;">${u.role === "admin" ? "👤 → Customer" : "⭐ → Admin"}</button>
          <button data-act="editUser" data-id="${escapeHtml(u._id)}" data-name="${escapeHtml(u.fullName || "")}" data-email="${escapeHtml(u.email || "")}" data-phone="${escapeHtml(u.phone || "")}" class="btn-sm" style="font-size:12px;display:flex;align-items:center;gap:4px;">${icons.edit} Sửa</button>
          <button data-act="deleteUser" data-id="${escapeHtml(u._id)}" data-name="${escapeHtml(u.fullName || u.email || "-")}" class="btn-danger" style="font-size:12px;display:flex;align-items:center;gap:4px;">${icons.trash} Xoá</button>
        </div>` },
      ],
      rows: users,
    });
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
          body: `<div style="display:flex;flex-direction:column;gap:14px;">
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

  qs("#btnSearch", wrapper).onclick = () => load().catch((e) => toast("error", "Lỗi", e.message));
  qs("#q", wrapper).addEventListener("keydown", (e) => { if (e.key === "Enter") load().catch((err) => toast("error", "Lỗi", err.message)); });

  qs("#btnCreateUser", wrapper).onclick = () => {
    openModal({
      title: "➕ Tạo user mới",
      body: `<div style="display:flex;flex-direction:column;gap:14px;">
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
  return wrapper.outerHTML;
}

// ─── Courts (full CRUD) ───────────────────────────────────────────────────────
async function renderCourts() {
  qs("#subTitle").textContent = "Quản lý sân — tạo, chỉnh sửa, xoá, đổi trạng thái";

  const wrapper = h(`<div style="display:flex;flex-direction:column;gap:16px;">
    <div style="display:flex;justify-content:flex-end;">
      <button id="btnCreateCourt" class="btn-primary" style="display:flex;align-items:center;gap:6px;">${icons.plus} Thêm sân mới</button>
    </div>
    <div id="courtsTable"></div>
  </div>`);

  async function load() {
    const data = await apiFetch("/api/admin/courts", { query: { page: 1, limit: 50 } });
    const courts = data?.courts || data?.items || [];
    qs("#courtsTable", wrapper).innerHTML = renderTable({
      columns: [
        { label: "Sân",       render: (c) => `<div style="font-weight:600;">${escapeHtml(c.name || "-")}</div><div style="font-size:12px;color:#8b93a8;">${escapeHtml(c.address || "")}</div>` },
        { label: "Loại",      render: (c) => `<span style="font-weight:500;">${escapeHtml(c.category || "-")}</span>` },
        { label: "Trạng thái",render: (c) => statusBadge("court", c.status) },
        { label: "Giá/slot",  render: (c) => `<span style="font-weight:600;color:#10b981;">${escapeHtml(formatMoney(c.pricePerSlot))}</span>` },
        { label: "Giờ mở",   render: (c) => `<span style="font-family:'JetBrains Mono',monospace;font-size:12px;background:#f4f5fb;padding:3px 8px;border-radius:6px;">${escapeHtml(c.openTime || "")} – ${escapeHtml(c.closeTime || "")}</span>` },
        { label: "Actions",   render: (c) => `<div style="display:flex;gap:6px;flex-wrap:wrap;">
          <button data-act="editCourt" data-id="${escapeHtml(c._id)}" data-json="${escapeHtml(JSON.stringify(c))}" class="btn-sm" style="font-size:12px;display:flex;align-items:center;gap:4px;">${icons.edit} Sửa</button>
          <button data-act="toggleCourtStatus" data-id="${escapeHtml(c._id)}" data-status="${escapeHtml(c.status)}" class="btn-sm" style="font-size:12px;">${c.status === "maintenance" ? "✅ Kích hoạt" : "🔧 Bảo trì"}</button>
          <button data-act="deleteCourt" data-id="${escapeHtml(c._id)}" data-name="${escapeHtml(c.name || "-")}" class="btn-danger" style="font-size:12px;display:flex;align-items:center;gap:4px;">${icons.trash} Xoá</button>
        </div>` },
      ],
      rows: courts,
    });
  }

  function courtForm(c = {}) {
    return `<div style="display:grid;grid-template-columns:1fr 1fr;gap:14px;">
      ${field("Tên sân", inp("fName", "text", c.name || "", "Sân A1"))}
      ${field("Loại", inp("fCategory", "text", c.category || "", "Cầu lông / Padel…"))}
      ${field("Địa chỉ", `<input id="fAddress" type="text" class="admin-input" value="${escapeHtml(c.address || "")}" placeholder="123 Đường…" style="grid-column:span 2;" />`)}
      ${field("Giá/slot (VND)", inp("fPrice", "number", c.pricePerSlot || "", "150000"))}
      ${field("Trạng thái", sel("fStatus", [["active","Active"],["maintenance","Bảo trì"]], c.status || "active"))}
      ${field("Giờ mở", inp("fOpenTime", "time", c.openTime || "06:00"))}
      ${field("Giờ đóng", inp("fCloseTime", "time", c.closeTime || "22:00"))}
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
        openModal({
          title: "✏️ Chỉnh sửa sân",
          body: courtForm(c),
          size: "560px",
          onConfirm: async (modal) => {
            const body = {
              name: qs("#fName", modal).value.trim(),
              category: qs("#fCategory", modal).value.trim(),
              address: qs("#fAddress", modal).value.trim(),
              pricePerSlot: Number(qs("#fPrice", modal).value),
              status: qs("#fStatus", modal).value,
              openTime: qs("#fOpenTime", modal).value,
              closeTime: qs("#fCloseTime", modal).value,
            };
            await apiFetch(`/api/admin/courts/${id}`, { method: "PATCH", body });
            toast("success", "Đã cập nhật", "Thông tin sân đã được lưu");
            await load();
          },
          confirmLabel: "Lưu thay đổi",
        });
      }
      if (act === "toggleCourtStatus") {
        const next = btn.dataset.status === "maintenance" ? "active" : "maintenance";
        await apiFetch(`/api/admin/courts/${id}/status`, { method: "PATCH", body: { status: next } });
        toast("success", "Cập nhật thành công", "Trạng thái sân đã thay đổi");
        await load();
      }
      if (act === "deleteCourt") {
        confirmDialog("🗑️ Xoá sân", `Bạn có chắc muốn xoá sân "${btn.dataset.name}"?`, async () => {
          await apiFetch(`/api/admin/courts/${id}`, { method: "DELETE" });
          toast("success", "Đã xoá", "Sân đã được xoá thành công");
          await load();
        });
      }
    } catch (err) { toast("error", "Lỗi", err.message); }
  });

  qs("#btnCreateCourt", wrapper).onclick = () => {
    openModal({
      title: "➕ Thêm sân mới",
      body: courtForm(),
      size: "560px",
      onConfirm: async (modal) => {
        const body = {
          name: qs("#fName", modal).value.trim(),
          category: qs("#fCategory", modal).value.trim(),
          address: qs("#fAddress", modal).value.trim(),
          pricePerSlot: Number(qs("#fPrice", modal).value),
          status: qs("#fStatus", modal).value,
          openTime: qs("#fOpenTime", modal).value,
          closeTime: qs("#fCloseTime", modal).value,
        };
        await apiFetch("/api/admin/courts", { method: "POST", body });
        toast("success", "Đã tạo", "Sân mới đã được thêm thành công");
        await load();
      },
      confirmLabel: "Thêm sân",
    });
  };

  await load();
  return wrapper.outerHTML;
}

// ─── Bookings (full CRUD) ─────────────────────────────────────────────────────
async function renderBookings() {
  qs("#subTitle").textContent = "Quản lý booking — tạo thủ công, đổi trạng thái, xoá";

  const wrapper = h(`<div style="display:flex;flex-direction:column;gap:16px;">
    <div class="admin-card">
      <div class="admin-card-body" style="padding:16px 20px;">
        <div style="display:flex;flex-wrap:wrap;gap:12px;align-items:flex-end;">
          <div style="flex:1;min-width:180px;">
            <label style="font-size:11.5px;font-weight:700;color:#8b93a8;text-transform:uppercase;letter-spacing:0.06em;display:block;margin-bottom:6px;">Trạng thái</label>
            <select id="bStatus" class="admin-select"><option value="">Tất cả</option><option value="pending">Pending</option><option value="confirmed">Confirmed</option><option value="cancelled">Cancelled</option><option value="completed">Completed</option></select>
          </div>
          <div style="flex:1;min-width:180px;">
            <label style="font-size:11.5px;font-weight:700;color:#8b93a8;text-transform:uppercase;letter-spacing:0.06em;display:block;margin-bottom:6px;">Tìm kiếm</label>
            <input id="bQ" class="admin-input" placeholder="Mã booking / email khách…" />
          </div>
          <button id="btnBSearch" class="btn-primary" style="display:flex;align-items:center;gap:6px;">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
            Tìm kiếm
          </button>
          <button id="btnCreateBooking" class="btn-primary" style="display:flex;align-items:center;gap:6px;">${icons.plus} Tạo booking</button>
        </div>
      </div>
    </div>
    <div id="bookingsTable"></div>
  </div>`);

  async function load() {
    const status = qs("#bStatus", wrapper).value;
    const q = qs("#bQ", wrapper).value.trim();
    const data = await apiFetch("/api/admin/bookings", { query: { status, q, page: 1, limit: 50 } });
    const bookings = data?.bookings || data?.items || [];
    qs("#bookingsTable", wrapper).innerHTML = renderTable({
      columns: [
        { label: "Mã đặt", render: (b) => `<div style="font-weight:600;font-family:'JetBrains Mono',monospace;font-size:12px;color:#6366f1;">${escapeHtml(b.bookingCode || "-")}</div><div style="font-size:12px;color:#8b93a8;">${escapeHtml(b.date || "")} ${escapeHtml(b.startTime || "")}–${escapeHtml(b.endTime || "")}</div>` },
        { label: "Sân",    render: (b) => `<span style="font-weight:500;">${escapeHtml(b.court?.name || "-")}</span>` },
        { label: "Khách",  render: (b) => `<div style="font-weight:500;">${escapeHtml(b.user?.fullName || "-")}</div><div style="font-size:12px;color:#8b93a8;">${escapeHtml(b.user?.email || "")}</div>` },
        { label: "Tổng",   render: (b) => `<span style="font-weight:600;color:#10b981;">${escapeHtml(formatMoney(b.finalPrice))}</span>` },
        { label: "Trạng thái", render: (b) => statusBadge("booking", b.status) },
        { label: "Actions", render: (b) => `<div style="display:flex;gap:6px;flex-wrap:wrap;">
          <button data-act="changeBookingStatus" data-id="${escapeHtml(b._id)}" data-status="${escapeHtml(b.status)}" class="btn-sm" style="font-size:12px;display:flex;align-items:center;gap:4px;">${icons.edit} Trạng thái</button>
          <button data-act="viewBooking" data-json="${escapeHtml(JSON.stringify(b))}" class="btn-sm" style="font-size:12px;">👁 Chi tiết</button>
          <button data-act="deleteBooking" data-id="${escapeHtml(b._id)}" data-code="${escapeHtml(b.bookingCode || "-")}" class="btn-danger" style="font-size:12px;display:flex;align-items:center;gap:4px;">${icons.trash} Xoá</button>
        </div>` },
      ],
      rows: bookings,
    });
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
          body: `<div style="display:flex;flex-direction:column;gap:14px;">
            <div style="font-size:13px;color:#5a6384;">Chọn trạng thái mới cho booking này:</div>
            ${field("Trạng thái", sel("newBStatus", [
              ["pending","⏳ Pending"],["confirmed","✅ Confirmed"],
              ["cancelled","❌ Cancelled"],["completed","🏁 Completed"]
            ], btn.dataset.status))}
            ${field("Ghi chú (tuỳ chọn)", `<input id="statusNote" type="text" class="admin-input" placeholder="Lý do thay đổi…" />`)}
          </div>`,
          onConfirm: async (modal) => {
            const body = { status: qs("#newBStatus", modal).value };
            const note = qs("#statusNote", modal).value.trim();
            if (note) body.note = note;
            await apiFetch(`/api/admin/bookings/${id}/status`, { method: "PATCH", body });
            toast("success", "Đã cập nhật", "Trạng thái booking đã thay đổi");
            await load();
          },
          confirmLabel: "Cập nhật",
        });
      }
      if (act === "viewBooking") {
        const b = JSON.parse(btn.dataset.json || "{}");
        openModal({
          title: `📋 Chi tiết booking ${escapeHtml(b.bookingCode || "")}`,
          body: `<div style="display:flex;flex-direction:column;gap:10px;font-size:13.5px;">
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;">
              <div><span style="color:#8b93a8;font-size:12px;">MÃ BOOKING</span><div style="font-weight:700;color:#6366f1;font-family:'JetBrains Mono',monospace;">${escapeHtml(b.bookingCode || "-")}</div></div>
              <div><span style="color:#8b93a8;font-size:12px;">TRẠNG THÁI</span><div>${statusBadge("booking", b.status)}</div></div>
              <div><span style="color:#8b93a8;font-size:12px;">SÂN</span><div style="font-weight:600;">${escapeHtml(b.court?.name || "-")}</div></div>
              <div><span style="color:#8b93a8;font-size:12px;">KHÁCH</span><div style="font-weight:600;">${escapeHtml(b.user?.fullName || "-")}</div><div style="font-size:12px;color:#8b93a8;">${escapeHtml(b.user?.email || "")}</div></div>
              <div><span style="color:#8b93a8;font-size:12px;">NGÀY ĐẶT</span><div>${escapeHtml(b.date || "-")}</div></div>
              <div><span style="color:#8b93a8;font-size:12px;">KHUNG GIỜ</span><div>${escapeHtml(b.startTime || "")} – ${escapeHtml(b.endTime || "")}</div></div>
              <div><span style="color:#8b93a8;font-size:12px;">TỔNG TIỀN</span><div style="font-weight:700;color:#10b981;">${escapeHtml(formatMoney(b.finalPrice))}</div></div>
              <div><span style="color:#8b93a8;font-size:12px;">MÃ GIẢM GIÁ</span><div>${escapeHtml(b.discountCode || "Không có")}</div></div>
            </div>
          </div>`,
        });
      }
      if (act === "deleteBooking") {
        confirmDialog("🗑️ Xoá booking", `Bạn có chắc muốn xoá booking "${btn.dataset.code}"?`, async () => {
          await apiFetch(`/api/admin/bookings/${id}`, { method: "DELETE" });
          toast("success", "Đã xoá", "Booking đã được xoá thành công");
          await load();
        });
      }
    } catch (err) { toast("error", "Lỗi", err.message); }
  });

  qs("#btnBSearch", wrapper).onclick = () => load().catch((e) => toast("error", "Lỗi", e.message));
  qs("#bQ", wrapper).addEventListener("keydown", (e) => { if (e.key === "Enter") load().catch((err) => toast("error", "Lỗi", err.message)); });

  qs("#btnCreateBooking", wrapper).onclick = async () => {
    // Load courts for dropdown
    let courtOptions = [["", "-- Chọn sân --"]];
    try {
      const cd = await apiFetch("/api/admin/courts", { query: { page: 1, limit: 100 } });
      const courts = cd?.courts || cd?.items || [];
      courtOptions = [["", "-- Chọn sân --"], ...courts.map((c) => [c._id, c.name])];
    } catch {}

    openModal({
      title: "➕ Tạo booking thủ công",
      size: "560px",
      body: `<div style="display:grid;grid-template-columns:1fr 1fr;gap:14px;">
        ${field("Chọn sân", sel("cbCourt", courtOptions, ""))}
        ${field("User ID / Email", inp("cbUser", "text", "", "user@example.com"))}
        ${field("Ngày", inp("cbDate", "date", new Date().toISOString().split("T")[0]))}
        ${field("Giờ bắt đầu", inp("cbStart", "time", "08:00"))}
        ${field("Giờ kết thúc", inp("cbEnd", "time", "09:00"))}
        ${field("Trạng thái", sel("cbStatus", [["pending","Pending"],["confirmed","Confirmed"]], "pending"))}
        ${field("Ghi chú", inp("cbNote", "text", "", "Ghi chú tuỳ chọn…"))}
      </div>`,
      onConfirm: async (modal) => {
        const body = {
          courtId: qs("#cbCourt", modal).value,
          userId: qs("#cbUser", modal).value.trim(),
          date: qs("#cbDate", modal).value,
          startTime: qs("#cbStart", modal).value,
          endTime: qs("#cbEnd", modal).value,
          status: qs("#cbStatus", modal).value,
          note: qs("#cbNote", modal).value.trim(),
        };
        await apiFetch("/api/admin/bookings", { method: "POST", body });
        toast("success", "Đã tạo", "Booking mới đã được tạo thành công");
        await load();
      },
      confirmLabel: "Tạo booking",
    });
  };

  await load();
  return wrapper.outerHTML;
}

// ─── Payments (view + status change) ─────────────────────────────────────────
async function renderPayments() {
  qs("#subTitle").textContent = "Lịch sử thanh toán — chỉnh trạng thái, xem chi tiết";

  const wrapper = h(`<div style="display:flex;flex-direction:column;gap:16px;">
    <div class="admin-card">
      <div class="admin-card-body" style="padding:16px 20px;">
        <div style="display:flex;flex-wrap:wrap;gap:12px;align-items:flex-end;">
          <div style="flex:1;min-width:180px;">
            <label style="font-size:11.5px;font-weight:700;color:#8b93a8;text-transform:uppercase;letter-spacing:0.06em;display:block;margin-bottom:6px;">Trạng thái</label>
            <select id="pStatus" class="admin-select"><option value="">Tất cả</option><option value="pending">Pending</option><option value="completed">Completed</option><option value="failed">Failed</option><option value="refunded">Refunded</option></select>
          </div>
          <div style="flex:1;min-width:180px;">
            <label style="font-size:11.5px;font-weight:700;color:#8b93a8;text-transform:uppercase;letter-spacing:0.06em;display:block;margin-bottom:6px;">Tìm kiếm</label>
            <input id="pQ" class="admin-input" placeholder="Email / booking code…" />
          </div>
          <button id="btnPSearch" class="btn-primary" style="display:flex;align-items:center;gap:6px;">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
            Tìm kiếm
          </button>
        </div>
      </div>
    </div>
    <div id="paymentsTable"></div>
  </div>`);

  async function load() {
    const status = qs("#pStatus", wrapper).value;
    const q = qs("#pQ", wrapper).value.trim();
    const data = await apiFetch("/api/admin/payments", { query: { status, q, page: 1, limit: 50 } });
    const payments = data?.payments || data?.items || [];
    qs("#paymentsTable", wrapper).innerHTML = renderTable({
      columns: [
        { label: "Số tiền",    render: (p) => `<div style="font-weight:700;color:#10b981;">${escapeHtml(formatMoney(p.amount))}</div><div style="font-size:12px;color:#8b93a8;">${escapeHtml(p.method || "")}</div>` },
        { label: "Trạng thái", render: (p) => statusBadge("payment", p.status) },
        { label: "Khách",      render: (p) => `<div style="font-weight:500;">${escapeHtml(p.user?.fullName || "-")}</div><div style="font-size:12px;color:#8b93a8;">${escapeHtml(p.user?.email || "")}</div>` },
        { label: "Booking",    render: (p) => `<span style="font-family:'JetBrains Mono',monospace;font-size:12px;color:#6366f1;">${escapeHtml(p.booking?.bookingCode || "-")}</span>` },
        { label: "Ngày TT",    render: (p) => `<span style="font-family:'JetBrains Mono',monospace;font-size:12px;">${escapeHtml(p.paidAt || "")}</span>` },
        { label: "Actions",    render: (p) => `<div style="display:flex;gap:6px;">
          <button data-act="changePayStatus" data-id="${escapeHtml(p._id)}" data-status="${escapeHtml(p.status)}" class="btn-sm" style="font-size:12px;display:flex;align-items:center;gap:4px;">${icons.edit} Trạng thái</button>
          <button data-act="viewPayment" data-json="${escapeHtml(JSON.stringify(p))}" class="btn-sm" style="font-size:12px;">👁 Chi tiết</button>
        </div>` },
      ],
      rows: payments,
    });
  }

  wrapper.addEventListener("click", async (e) => {
    const btn = e.target.closest("button[data-act]");
    if (!btn) return;
    const act = btn.dataset.act;
    const id = btn.dataset.id;
    try {
      if (act === "changePayStatus") {
        openModal({
          title: "🔄 Đổi trạng thái thanh toán",
          body: `<div style="display:flex;flex-direction:column;gap:14px;">
            ${field("Trạng thái mới", sel("newPStatus", [
              ["pending","⏳ Pending"],["completed","✅ Completed"],
              ["failed","❌ Failed"],["refunded","↩️ Refunded"]
            ], btn.dataset.status))}
          </div>`,
          onConfirm: async (modal) => {
            await apiFetch(`/api/admin/payments/${id}/status`, { method: "PATCH", body: { status: qs("#newPStatus", modal).value } });
            toast("success", "Đã cập nhật", "Trạng thái thanh toán đã thay đổi");
            await load();
          },
          confirmLabel: "Cập nhật",
        });
      }
      if (act === "viewPayment") {
        const p = JSON.parse(btn.dataset.json || "{}");
        openModal({
          title: "💳 Chi tiết thanh toán",
          body: `<div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;font-size:13.5px;">
            <div><span style="color:#8b93a8;font-size:12px;">SỐ TIỀN</span><div style="font-weight:700;color:#10b981;">${escapeHtml(formatMoney(p.amount))}</div></div>
            <div><span style="color:#8b93a8;font-size:12px;">TRẠNG THÁI</span><div>${statusBadge("payment", p.status)}</div></div>
            <div><span style="color:#8b93a8;font-size:12px;">PHƯƠNG THỨC</span><div>${escapeHtml(p.method || "-")}</div></div>
            <div><span style="color:#8b93a8;font-size:12px;">NGÀY TT</span><div>${escapeHtml(p.paidAt || "-")}</div></div>
            <div><span style="color:#8b93a8;font-size:12px;">KHÁCH HÀNG</span><div style="font-weight:600;">${escapeHtml(p.user?.fullName || "-")}</div><div style="font-size:12px;color:#8b93a8;">${escapeHtml(p.user?.email || "")}</div></div>
            <div><span style="color:#8b93a8;font-size:12px;">BOOKING</span><div style="font-family:'JetBrains Mono',monospace;color:#6366f1;">${escapeHtml(p.booking?.bookingCode || "-")}</div></div>
          </div>`,
        });
      }
    } catch (err) { toast("error", "Lỗi", err.message); }
  });

  qs("#btnPSearch", wrapper).onclick = () => load().catch((e) => toast("error", "Lỗi", e.message));

  await load();
  return wrapper.outerHTML;
}

// ─── Discounts (full CRUD) ────────────────────────────────────────────────────
async function renderDiscounts() {
  qs("#subTitle").textContent = "Quản lý mã giảm giá — tạo, chỉnh sửa, xoá, đổi trạng thái";

  const wrapper = h(`<div style="display:flex;flex-direction:column;gap:16px;">
    <div style="display:flex;justify-content:flex-end;">
      <button id="btnCreateDiscount" class="btn-primary" style="display:flex;align-items:center;gap:6px;">${icons.plus} Tạo mã giảm giá</button>
    </div>
    <div id="discountsTable"></div>
  </div>`);

  async function load() {
    const data = await apiFetch("/api/admin/discounts", { query: { page: 1, limit: 50 } });
    const discounts = data?.discounts || data?.items || [];
    qs("#discountsTable", wrapper).innerHTML = renderTable({
      columns: [
        { label: "Mã",        render: (d) => `<div style="font-weight:700;font-family:'JetBrains Mono',monospace;color:#6366f1;">${escapeHtml(d.code || "-")}</div><div style="font-size:12px;color:#8b93a8;">${escapeHtml(d.description || "")}</div>` },
        { label: "Loại",      render: (d) => `<span style="font-weight:500;">${escapeHtml(d.discountType || "-")}</span>` },
        { label: "Giá trị",  render: (d) => `<span style="font-weight:700;color:#f59e0b;">${escapeHtml(d.discountType === "percent" ? `${d.discountValue || 0}%` : formatMoney(d.discountValue))}</span>` },
        { label: "Lượt dùng", render: (d) => `<span style="font-size:13px;">${escapeHtml(d.usedCount || 0)} / ${escapeHtml(d.maxUsage || "∞")}</span>` },
        { label: "Trạng thái",render: (d) => statusBadge("discount", d.status) },
        { label: "Hết hạn",  render: (d) => `<span style="font-family:'JetBrains Mono',monospace;font-size:12px;">${escapeHtml(d.validTo ? d.validTo.substring(0, 10) : "")}</span>` },
        { label: "Actions",  render: (d) => `<div style="display:flex;gap:6px;flex-wrap:wrap;">
          <button data-act="editDiscount" data-id="${escapeHtml(d._id)}" data-json="${escapeHtml(JSON.stringify(d))}" class="btn-sm" style="font-size:12px;display:flex;align-items:center;gap:4px;">${icons.edit} Sửa</button>
          <button data-act="toggleDiscount" data-id="${escapeHtml(d._id)}" data-status="${escapeHtml(d.status)}" class="btn-sm" style="font-size:12px;">${d.status === "disabled" ? "✅ Kích hoạt" : "🚫 Vô hiệu"}</button>
          <button data-act="deleteDiscount" data-id="${escapeHtml(d._id)}" data-code="${escapeHtml(d.code || "-")}" class="btn-danger" style="font-size:12px;display:flex;align-items:center;gap:4px;">${icons.trash} Xoá</button>
        </div>` },
      ],
      rows: discounts,
    });
  }

  function discountForm(d = {}) {
    return `<div style="display:grid;grid-template-columns:1fr 1fr;gap:14px;">
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
    const act = btn.dataset.act;
    const id = btn.dataset.id;
    try {
      if (act === "editDiscount") {
        const d = JSON.parse(btn.dataset.json || "{}");
        openModal({
          title: "✏️ Chỉnh sửa mã giảm giá",
          body: discountForm(d),
          size: "560px",
          onConfirm: async (modal) => {
            const body = {
              code: qs("#dCode", modal).value.trim(),
              description: qs("#dDesc", modal).value.trim(),
              discountType: qs("#dType", modal).value,
              discountValue: Number(qs("#dValue", modal).value),
              maxUsage: Number(qs("#dMax", modal).value) || null,
              minOrderValue: Number(qs("#dMinOrder", modal).value) || 0,
              validFrom: qs("#dFrom", modal).value || null,
              validTo: qs("#dTo", modal).value || null,
              status: qs("#dStatus", modal).value,
            };
            await apiFetch(`/api/admin/discounts/${id}`, { method: "PATCH", body });
            toast("success", "Đã cập nhật", "Mã giảm giá đã được lưu");
            await load();
          },
          confirmLabel: "Lưu thay đổi",
        });
      }
      if (act === "toggleDiscount") {
        const next = btn.dataset.status === "disabled" ? "active" : "disabled";
        await apiFetch(`/api/admin/discounts/${id}/status`, { method: "PATCH", body: { status: next } });
        toast("success", "Cập nhật thành công", "Trạng thái mã giảm giá đã thay đổi");
        await load();
      }
      if (act === "deleteDiscount") {
        confirmDialog("🗑️ Xoá mã giảm giá", `Bạn có chắc muốn xoá mã "${btn.dataset.code}"?`, async () => {
          await apiFetch(`/api/admin/discounts/${id}`, { method: "DELETE" });
          toast("success", "Đã xoá", "Mã giảm giá đã được xoá thành công");
          await load();
        });
      }
    } catch (err) { toast("error", "Lỗi", err.message); }
  });

  qs("#btnCreateDiscount", wrapper).onclick = () => {
    openModal({
      title: "➕ Tạo mã giảm giá",
      body: discountForm(),
      size: "560px",
      onConfirm: async (modal) => {
        const body = {
          code: qs("#dCode", modal).value.trim(),
          description: qs("#dDesc", modal).value.trim(),
          discountType: qs("#dType", modal).value,
          discountValue: Number(qs("#dValue", modal).value),
          maxUsage: Number(qs("#dMax", modal).value) || null,
          minOrderValue: Number(qs("#dMinOrder", modal).value) || 0,
          validFrom: qs("#dFrom", modal).value || null,
          validTo: qs("#dTo", modal).value || null,
          status: qs("#dStatus", modal).value,
        };
        await apiFetch("/api/admin/discounts", { method: "POST", body });
        toast("success", "Đã tạo", "Mã giảm giá mới đã được tạo");
        await load();
      },
      confirmLabel: "Tạo mã",
    });
  };

  await load();
  return wrapper.outerHTML;
}

// ─── Settings ─────────────────────────────────────────────────────────────────
async function renderSettings() {
  qs("#subTitle").textContent = "Cấu hình API và xác thực";
  const apiBase = getApiBaseUrl();
  const token = getToken();
  return `<div style="max-width:640px;display:flex;flex-direction:column;gap:16px;">
    <div class="admin-card">
      <div class="admin-card-header">🔗 API Base URL</div>
      <div class="admin-card-body">
        <div style="font-size:13px;color:#8b93a8;margin-bottom:12px;">Ví dụ: <code style="background:#f4f5fb;padding:2px 7px;border-radius:6px;font-size:12px;color:#6366f1;">${escapeHtml(window.location.origin)}</code></div>
        <div style="display:flex;gap:10px;">
          <input id="apiBaseInput" class="admin-input" value="${escapeHtml(apiBase)}" style="flex:1;" />
          <button id="btnSaveApiBase" class="btn-primary">Lưu</button>
        </div>
      </div>
    </div>
    <div class="admin-card">
      <div class="admin-card-header">🔑 Xác thực</div>
      <div class="admin-card-body">
        <div style="display:flex;align-items:center;gap:8px;margin-bottom:14px;">
          <span style="font-size:13px;color:#5a6384;font-weight:500;">Token:</span>
          ${token ? badge("Đã thiết lập", "green") : badge("Chưa có", "red")}
        </div>
        ${token ? `<div style="background:#f8f9fc;border:1px solid #eef0f5;border-radius:10px;padding:10px 14px;font-family:'JetBrains Mono',monospace;font-size:11.5px;color:#8b93a8;word-break:break-all;margin-bottom:14px;">${escapeHtml(token.substring(0, 48))}…</div>` : ""}
        <div style="display:flex;gap:10px;">
          <button id="btnForceLogin" class="btn-ghost">Đăng nhập lại</button>
          <button id="btnClearAuth" class="btn-ghost" style="color:#c0392b;border-color:#fcd0d0;">Xoá token</button>
        </div>
      </div>
    </div>
    <div class="admin-card">
      <div class="admin-card-header">🩺 Health Check</div>
      <div class="admin-card-body">
        <div style="display:flex;gap:10px;margin-bottom:14px;">
          <button id="btnPing" class="btn-primary">Ping /</button>
          <button id="btnAdminPing" class="btn-ghost">Ping Admin Overview</button>
        </div>
        <pre id="pingOut" style="background:#0f1117;color:#a3e635;border-radius:12px;padding:14px 16px;font-size:12px;font-family:'JetBrains Mono',monospace;max-height:220px;overflow:auto;margin:0;line-height:1.6;"></pre>
      </div>
    </div>
  </div>`;
}

// ─── Render route ─────────────────────────────────────────────────────────────
async function renderRoute() {
  const id = currentRouteId();
  document.querySelectorAll(".nav-item").forEach((el) => {
    const itemId = (el.getAttribute("href") || "").replace("#/", "");
    el.classList.toggle("active", itemId === id);
  });
  const titleEl = document.querySelector("#topbar .route-title");
  if (titleEl) titleEl.textContent = routes.find((r) => r.id === id)?.label || "Dashboard";

  const authed = await ensureAuthed();
  const contentEl = qs("#content");
  contentEl.innerHTML = `<div style="display:flex;flex-direction:column;gap:16px;">
    <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:16px;">${[0,1,2,3].map(() => `<div class="skeleton" style="height:110px;border-radius:16px;"></div>`).join("")}</div>
    <div class="skeleton" style="height:300px;border-radius:16px;"></div>
  </div>`;

  if (!authed) {
    contentEl.innerHTML = `<div class="admin-card" style="padding:40px;text-align:center;color:#8b93a8;"><div style="font-size:32px;margin-bottom:10px;">🔐</div><div style="font-size:15px;font-weight:600;">Vui lòng đăng nhập để tiếp tục</div></div>`;
    return;
  }

  try {
    let html = "";
    if (id === "dashboard")       html = await renderDashboard();
    else if (id === "users")      html = await renderUsers();
    else if (id === "courts")     html = await renderCourts();
    else if (id === "bookings")   html = await renderBookings();
    else if (id === "payments")   html = await renderPayments();
    else if (id === "discounts")  html = await renderDiscounts();
    else if (id === "settings")   html = await renderSettings();
    else                          html = await renderDashboard();
    contentEl.innerHTML = html;
    bindPageHandlers();
  } catch (err) {
    if (err.status === 401 || err.status === 403) {
      clearAuth();
      toast("error", "Phiên hết hạn", "Vui lòng đăng nhập lại.");
      await ensureAuthed();
    } else {
      toast("error", "Lỗi", err.message);
    }
    contentEl.innerHTML = `<div class="admin-card" style="padding:32px;display:flex;align-items:flex-start;gap:14px;">
      <div style="width:40px;height:40px;background:#fff0f0;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:20px;flex-shrink:0;">❌</div>
      <div><div style="font-weight:700;color:#c0392b;margin-bottom:4px;">Có lỗi xảy ra</div><div style="font-size:13.5px;color:#8b93a8;">${escapeHtml(err.message)}</div></div>
    </div>`;
  }
}

// ─── Page handlers (settings + any page-level buttons) ───────────────────────
function bindPageHandlers() {
  const btnSave = qs("#btnSaveApiBase");
  if (btnSave) btnSave.onclick = () => {
    setApiBaseUrl(qs("#apiBaseInput").value.trim());
    toast("success", "Đã lưu", "API Base URL đã được cập nhật");
    setTimeout(() => window.location.reload(), 500);
  };

  const btnClear = qs("#btnClearAuth");
  if (btnClear) btnClear.onclick = () => {
    clearAuth();
    toast("success", "Đã xoá", "Token đã được xoá");
    setTimeout(() => window.location.reload(), 500);
  };

  const btnLogin = qs("#btnForceLogin");
  if (btnLogin) btnLogin.onclick = () => ensureAuthed();

  const btnPing = qs("#btnPing");
  if (btnPing) btnPing.onclick = async () => {
    const out = qs("#pingOut");
    out.textContent = "Loading…";
    try {
      const res = await fetch(`${getApiBaseUrl()}/`);
      out.textContent = `HTTP ${res.status}\n\n${await res.text()}`;
    } catch (e) { out.textContent = e.message; }
  };

  const btnAdminPing = qs("#btnAdminPing");
  if (btnAdminPing) btnAdminPing.onclick = async () => {
    const out = qs("#pingOut");
    out.textContent = "Loading…";
    try {
      const data = await apiFetch("/api/admin/dashboard/overview");
      out.textContent = JSON.stringify(data, null, 2);
    } catch (e) { out.textContent = `${e.message}\n\n${JSON.stringify(e.data || {}, null, 2)}`; }
  };
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
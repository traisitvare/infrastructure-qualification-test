import React, { useEffect, useState } from "react";

function Badge({ ok, loading }) {
  const className = loading ? "badge pending" : ok ? "badge good" : "badge bad";
  const text = loading ? "CHECKING" : ok ? "VERIFIED" : "UNAVAILABLE";
  return <span className={className}><i />{text}</span>;
}

function MetricCard({ title, value, detail, ok, loading, measured }) {
  return (
    <article className="metric-card">
      <div className="metric-header">
        <span>{title}</span>
        {measured ? <label>MEASURED</label> : <Badge ok={ok} loading={loading} />}
      </div>
      <strong>{value}</strong>
      <small>{detail}</small>
    </article>
  );
}

function ArchitectureNode({ tone, label, title, detail }) {
  return (
    <div className={`arch-node ${tone}`}>
      <label>{label}</label>
      <b>{title}</b>
      <small>{detail}</small>
    </div>
  );
}

function csrfToken() {
  return document.cookie.split("; ").find((cookie) => cookie.startsWith("csrftoken="))?.split("=")[1] || "";
}

function AuthScreen({ mode, setMode, form, setForm, error, submitting, onSubmit }) {
  const registering = mode === "register";
  return (
    <main className="auth-page">
      <section className="auth-card">
        <div className="brand"><span>IP</span><div><strong>InfraPulse</strong><small>VERIFICATION</small></div></div>
        <p className="eyebrow">SECURE ACCESS</p>
        <h1>{registering ? "Create your account" : "Welcome back"}</h1>
        <p className="auth-copy">{registering ? "Register to access the verified infrastructure dashboard." : "Sign in to view live infrastructure evidence."}</p>
        <form onSubmit={onSubmit} className="auth-form">
          <label>Username<input value={form.username} onChange={(event) => setForm({ ...form, username: event.target.value })} autoComplete="username" minLength="3" required /></label>
          {registering && <label>Email<input type="email" value={form.email} onChange={(event) => setForm({ ...form, email: event.target.value })} autoComplete="email" required /></label>}
          <label>Password<input type="password" value={form.password} onChange={(event) => setForm({ ...form, password: event.target.value })} autoComplete={registering ? "new-password" : "current-password"} minLength="8" required /></label>
          {error && <p className="auth-error">{error}</p>}
          <button type="submit" disabled={submitting}>{submitting ? "Please wait..." : registering ? "Create account" : "Sign in"}</button>
        </form>
        <p className="auth-switch">{registering ? "Already have an account?" : "Need an account?"} <button type="button" onClick={() => { setMode(registering ? "login" : "register"); }}>{registering ? "Sign in" : "Register"}</button></p>
      </section>
    </main>
  );
}

export default function App() {
  const [health, setHealth] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [roundTrip, setRoundTrip] = useState(null);
  const [user, setUser] = useState(null);
  const [authLoading, setAuthLoading] = useState(true);
  const [authMode, setAuthMode] = useState("login");
  const [authForm, setAuthForm] = useState({ username: "", email: "", password: "" });
  const [authError, setAuthError] = useState("");
  const [authSubmitting, setAuthSubmitting] = useState(false);

  async function verify() {
    setLoading(true);
    setError("");
    const started = performance.now();

    try {
      const response = await fetch("/api/health/", { cache: "no-store" });
      const body = await response.json();
      if (!response.ok) {
        throw new Error(body.error || `HTTP ${response.status}`);
      }
      setRoundTrip(Math.round((performance.now() - started) * 100) / 100);
      setHealth(body);
    } catch (requestError) {
      setHealth(null);
      setRoundTrip(null);
      setError(requestError.message || "Health endpoint unavailable");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    async function restoreSession() {
      try {
        await fetch("/api/auth/csrf/", { credentials: "same-origin" });
        const response = await fetch("/api/auth/me/", { credentials: "same-origin" });
        if (response.ok) setUser(await response.json());
      } finally {
        setAuthLoading(false);
      }
    }
    restoreSession();
  }, []);

  useEffect(() => {
    if (user) verify();
  }, [user]);

  async function submitAuth(event) {
    event.preventDefault();
    setAuthSubmitting(true);
    setAuthError("");
    try {
      const endpoint = authMode === "register" ? "/api/auth/register/" : "/api/auth/login/";
      const response = await fetch(endpoint, {
        method: "POST",
        credentials: "same-origin",
        headers: { "Content-Type": "application/json", "X-CSRFToken": csrfToken() },
        body: JSON.stringify(authForm)
      });
      const body = await response.json();
      if (!response.ok) throw new Error(body.error || "Unable to sign in");
      setUser(body);
      setAuthForm({ username: "", email: "", password: "" });
    } catch (requestError) {
      setAuthError(requestError.message || "Unable to sign in");
    } finally {
      setAuthSubmitting(false);
    }
  }

  async function signOut() {
    await fetch("/api/auth/logout/", { method: "POST", credentials: "same-origin", headers: { "X-CSRFToken": csrfToken() } });
    setUser(null);
    setHealth(null);
  }

  const verified = health?.status === "ok" && health?.database === "connected";
  const rawResponse = health || {
    status: "error",
    database: "disconnected",
    message: error || "Waiting for health endpoint"
  };

  if (authLoading) return <main className="auth-page"><p className="auth-loading">Loading secure access...</p></main>;
  if (!user) return <AuthScreen mode={authMode} setMode={setAuthMode} form={authForm} setForm={setAuthForm} error={authError} submitting={authSubmitting} onSubmit={submitAuth} />;

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="brand">
          <span>IP</span>
          <div><strong>InfraPulse</strong><small>VERIFICATION</small></div>
        </div>
        <p className="nav-label">PROJECT</p>
        <nav>
          <a className="active" href="#overview">Overview</a>
          <a href="#status">Live verification</a>
          <a href="#architecture">Architecture</a>
          <a href="#configuration">Configuration</a>
        </nav>
        <div className="sidebar-state">
          <Badge ok={verified} loading={loading} />
          <small>No simulated monitoring data</small>
        </div>
      </aside>

      <div className="workspace">
        <header className="topbar">
          <span>Infrastructure / <b>Verified Overview</b></span>
          <div className="topbar-actions"><span>Signed in as <b>{user.username}</b></span><button className="logout-button" onClick={signOut}>Sign out</button><Badge ok={verified} loading={loading} /></div>
        </header>

        <main id="overview">
          <section className="hero">
            <div>
              <p className="eyebrow">LIVE DJANGO AND POSTGRESQL EVIDENCE</p>
              <h1>Infrastructure status<br /><em>with real data.</em></h1>
              <p className="lead">
                The browser reaches Django through Nginx. Django executes a live
                PostgreSQL query before returning database identity, version,
                query duration, and timestamp.
              </p>
              <div className="actions">
                <button onClick={verify} disabled={loading}>
                  {loading ? "Checking..." : "Run verification"}
                </button>
                <a href="/api/health/" target="_blank" rel="noreferrer">Open raw API</a>
              </div>
            </div>

            <div className="terminal">
              <div className="terminal-header"><i /><i /><i /><span>GET /api/health/</span></div>
              <pre>{JSON.stringify(rawResponse, null, 2)}</pre>
            </div>
          </section>

          <section id="status" className="section">
            <div className="section-heading">
              <div><p className="eyebrow">VERIFIED STATUS</p><h2>Evidence from the running stack</h2></div>
              <p>A failed API or database request is shown as unavailable. There is no healthy fallback.</p>
            </div>

            <div className="metric-grid">
              <MetricCard title="Django API" value={loading ? "checking" : health?.status || "error"} detail="GET /api/health/ through Nginx" ok={verified} loading={loading} />
              <MetricCard title="PostgreSQL" value={loading ? "checking" : health?.database || "disconnected"} detail="Live SQL query executed by Django" ok={health?.database === "connected"} loading={loading} />
              <MetricCard title="HTTP round trip" value={roundTrip == null ? "N/A" : `${roundTrip} ms`} detail="Browser to API and back" measured />
              <MetricCard title="Database query" value={health?.database_query_ms == null ? "N/A" : `${health.database_query_ms} ms`} detail="Measured inside Django" measured />
            </div>

            {error && <div className="error-box"><b>Verification failed</b><span>{error}</span></div>}

            <div className="evidence-panel">
              <div className="evidence-title">
                <div><p className="eyebrow">DATABASE EVIDENCE</p><h3>Returned directly by PostgreSQL</h3></div>
                <span>{health?.checked_at ? new Date(health.checked_at).toLocaleString() : "Not verified"}</span>
              </div>
              <div className="evidence-grid">
                <div><span>Database name</span><b>{health?.database_name || "Unavailable"}</b></div>
                <div><span>Database user</span><b>{health?.database_user || "Unavailable"}</b></div>
                <div><span>Server version</span><b>{health?.database_version ? `PostgreSQL ${health.database_version}` : "Unavailable"}</b></div>
                <div><span>Connection state</span><b className={verified ? "green" : "red"}>{health?.database || "disconnected"}</b></div>
              </div>
            </div>
          </section>

          <section id="architecture" className="section">
            <div className="section-heading">
              <div><p className="eyebrow">SYSTEM ARCHITECTURE</p><h2>Actual request and data flow</h2></div>
              <p>Only Nginx publishes a host port. React, Django, and PostgreSQL stay inside app_network.</p>
            </div>

            <div className="diagram">
              <ArchitectureNode tone="user" label="PUBLIC" title="Internet User" detail="Web browser" />
              <div className="arrow"><small>HTTP :80</small>↓</div>
              <div className="network">
                <span className="network-label">DOCKER BRIDGE NETWORK · app_network</span>
                <ArchitectureNode tone="nginx" label="ENTRY POINT" title="Nginx Reverse Proxy" detail="Published port 80" />
                <div className="routes"><span><i>/</i>↙</span><span><i>/api/*</i>↘</span></div>
                <div className="branches">
                  <ArchitectureNode tone="react" label="UI" title="React Frontend" detail="Internal port 5173" />
                  <div className="database-path">
                    <ArchitectureNode tone="django" label="API" title="Django 4.2" detail="Gunicorn · port 8000" />
                    <div className="arrow compact"><small>SQL · TCP 5432</small>↓</div>
                    <ArchitectureNode tone="postgres" label="DATA" title="PostgreSQL 15.2" detail="Internal port 5432" />
                    <div className="volume-arrow">↓</div>
                    <div className="volume"><b>Named volume</b><small>postgres_data</small></div>
                  </div>
                </div>
              </div>
            </div>
          </section>

          <section id="configuration" className="section">
            <div className="section-heading"><div><p className="eyebrow">DESIGN SUMMARY</p><h2>Configuration, not fake monitoring</h2></div></div>
            <div className="config-grid">
              <article><span>Public exposure</span><b>Nginx :80</b><small>Only published application port</small></article>
              <article><span>Internal DNS</span><b>Docker services</b><small>frontend, backend, and db</small></article>
              <article><span>Persistence</span><b>postgres_data</b><small>PostgreSQL named volume</small></article>
              <article><span>Verification</span><b>/api/health/</b><small>Real API and database query</small></article>
            </div>
          </section>

          <section className="transparency">
            <div><b>Data transparency</b><p>No fake uptime, CPU, memory, event history, or invented service latency is displayed. Use <code>docker compose ps</code> for container state.</p></div>
            <Badge ok={verified} loading={loading} />
          </section>
        </main>

        <footer><b>Infrastructure Qualification Test</b><span>Nginx · React.js · Django 4.2 · PostgreSQL 15.2</span></footer>
      </div>
    </div>
  );
}

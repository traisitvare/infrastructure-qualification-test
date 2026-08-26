import { useCallback, useEffect, useState } from "react";

const architecture = [
  { name: "Internet User", detail: "Web browser", type: "external" },
  { name: "Nginx", detail: "Reverse proxy Â· public port 80", type: "proxy" },
  { name: "React.js", detail: "Frontend Â· internal port 5173", type: "frontend" },
  { name: "Django 4.2", detail: "Gunicorn API Â· internal port 8000", type: "backend" },
  { name: "PostgreSQL 15.2", detail: "Database Â· internal port 5432", type: "database" },
];

function StatusBadge({ healthy, pending = false }) {
  const label = pending ? "Checking" : healthy ? "Verified" : "Unavailable";
  return <span className={`status-badge ${pending ? "pending" : healthy ? "good" : "bad"}`}><i />{label}</span>;
}

function App() {
  const [health, setHealth] = useState(null);
  const [requestError, setRequestError] = useState("");
  const [loading, setLoading] = useState(true);
  const [httpLatency, setHttpLatency] = useState(null);

  const verifyEnvironment = useCallback(async () => {
    setLoading(true);
    setRequestError("");
    const startedAt = performance.now();

    try {
      const response = await fetch("/api/health/", { cache: "no-store" });
      const body = await response.json();
      setHttpLatency(Math.round((performance.now() - startedAt) * 100) / 100);

      if (!response.ok) {
        throw new Error(body.error || `HTTP ${response.status}`);
      }

      setHealth(body);
    } catch (error) {
      setHealth(null);
      setHttpLatency(null);
      setRequestError(error.message || "Unable to reach the health endpoint");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    verifyEnvironment();
  }, [verifyEnvironment]);

  const verified = health?.status === "ok" && health?.database === "connected";
  const checkedAt = health?.checked_at
    ? new Date(health.checked_at).toLocaleString()
    : "Not verified";

  return (
    <div className="page-shell">
      <header className="topbar">
        <div className="brand">
          <span className="brand-mark">IV</span>
          <div><strong>Infrastructure Verification</strong><small>Qualification Project</small></div>
        </div>
        <nav><a href="#verification">Verification</a><a href="#architecture">Architecture</a><a href="#configuration">Configuration</a></nav>
        <StatusBadge healthy={verified} pending={loading} />
      </header>

      <main>
        <section className="hero">
          <div>
            <p className="eyebrow">LIVE END-TO-END VERIFICATION</p>
            <h1>Docker infrastructure,<br/><span>verified with real data.</span></h1>
            <p className="lead">This dashboard reports only values returned by the running Django health endpoint and its live PostgreSQL query. No uptime, resource, event, or service-latency data is simulated.</p>
            <div className="actions"><button onClick={verifyEnvironment} disabled={loading}>{loading ? "Checking..." : "Run verification"}</button><a href="/api/health/" target="_blank" rel="noreferrer">View raw API response</a></div>
          </div>
          <div className="response-card">
            <div className="response-head"><span /><span /><span /><b>GET /api/health/</b></div>
            <pre>{health ? JSON.stringify(health, null, 2) : requestError ? JSON.stringify({ status: "error", database: "disconnected", message: requestError }, null, 2) : "Waiting for API response..."}</pre>
          </div>
        </section>

        <section id="verification" className="section">
          <div className="section-heading"><div><p className="eyebrow">VERIFIED STATUS</p><h2>Evidence from the running environment</h2></div><p>Every status below is derived from the current API request. A failed request is displayed as unavailable, never as healthy.</p></div>

          <div className="status-grid">
            <article><div className="card-title"><span>Django health API</span><StatusBadge healthy={verified} pending={loading} /></div><strong>{loading ? "Checking" : health?.status || "error"}</strong><small>HTTP request through Nginx to <code>/api/health/</code></small></article>
            <article><div className="card-title"><span>PostgreSQL connection</span><StatusBadge healthy={health?.database === "connected"} pending={loading} /></div><strong>{loading ? "Checking" : health?.database || "disconnected"}</strong><small>Django executes a live SQL query before returning success</small></article>
            <article><div className="card-title"><span>HTTP round trip</span><span className="source-label">Measured now</span></div><strong>{httpLatency === null ? "N/A" : `${httpLatency} ms`}</strong><small>Browser to Nginx to Django and response back to browser</small></article>
            <article><div className="card-title"><span>Database query</span><span className="source-label">Measured now</span></div><strong>{health?.database_latency_ms === undefined ? "N/A" : `${health.database_latency_ms} ms`}</strong><small>Measured inside Django around the PostgreSQL verification query</small></article>
          </div>

          {requestError && <div className="error-box"><b>Verification failed</b><span>{requestError}</span></div>}

          <div className="evidence-panel">
            <div className="evidence-title"><div><p className="eyebrow">DATABASE EVIDENCE</p><h3>Values returned directly by PostgreSQL</h3></div><span>Checked: {checkedAt}</span></div>
            <div className="evidence-grid">
              <div><span>Database name</span><strong>{health?.database_name || "Unavailable"}</strong></div>
              <div><span>Database user</span><strong>{health?.database_user || "Unavailable"}</strong></div>
              <div><span>Server version</span><strong>{health?.database_version ? `PostgreSQL ${health.database_version}` : "Unavailable"}</strong></div>
              <div><span>Connection state</span><strong className={verified ? "green-text" : "red-text"}>{health?.database || "disconnected"}</strong></div>
            </div>
          </div>
        </section>

        <section id="architecture" className="section">
          <div className="section-heading"><div><p className="eyebrow">SYSTEM ARCHITECTURE</p><h2>Actual request and data flow</h2></div><p>Only Nginx publishes a host port. React, Django, and PostgreSQL remain inside the Docker bridge network.</p></div>
          <div className="architecture-panel">
            <div className="arch-node external"><span>PUBLIC</span><b>{architecture[0].name}</b><small>{architecture[0].detail}</small></div>
            <div className="down-arrow"><em>HTTP :80</em>â†“</div>
            <div className="docker-network">
              <span className="network-label">DOCKER BRIDGE NETWORK Â· app_network</span>
              <div className="arch-node proxy"><span>ENTRY POINT</span><b>{architecture[1].name}</b><small>{architecture[1].detail}</small></div>
              <div className="route-labels"><div><em>/</em>â†™</div><div><em>/api/*</em>â†˜</div></div>
              <div className="route-grid">
                <div className="arch-node frontend"><span>UI</span><b>{architecture[2].name}</b><small>{architecture[2].detail}</small></div>
                <div className="backend-path"><div className="arch-node backend"><span>API</span><b>{architecture[3].name}</b><small>{architecture[3].detail}</small></div><div className="sql-arrow"><em>SQL Â· TCP 5432</em>â†“</div><div className="arch-node database"><span>DATA</span><b>{architecture[4].name}</b><small>{architecture[4].detail}</small></div><div className="volume-arrow">â†“</div><div className="volume"><b>Named volume</b><small>postgres_data</small></div></div>
              </div>
            </div>
          </div>
        </section>

        <section id="configuration" className="section configuration-section">
          <div className="section-heading"><div><p className="eyebrow">CONFIGURATION SUMMARY</p><h2>Declared environment design</h2></div><p>These values describe the checked project configuration. They are not presented as monitoring metrics.</p></div>
          <div className="config-grid">
            <article><span>Public exposure</span><strong>Nginx Â· port 80</strong><small>Single host entry point</small></article>
            <article><span>Internal network</span><strong>app_network</strong><small>Docker bridge network</small></article>
            <article><span>Persistent storage</span><strong>postgres_data</strong><small>Docker named volume</small></article>
            <article><span>Health endpoint</span><strong>/api/health/</strong><small>Real Django and PostgreSQL check</small></article>
          </div>
        </section>

        <section className="truth-note"><div><b>Data transparency</b><p>The dashboard intentionally excludes fake uptime percentages, CPU charts, memory charts, static event histories, and invented per-service latency. Container state can be verified separately with <code>docker compose ps</code>.</p></div><StatusBadge healthy={verified} pending={loading} /></section>
      </main>

      <footer><b>Infrastructure Qualification Test</b><span>Nginx Â· React.js Â· Django 4.2 Â· PostgreSQL 15.2 Â· Docker Compose</span></footer>
    </div>
  );
}

export default App;
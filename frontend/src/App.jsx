import { useEffect, useState } from "react";

function Status({ ok, loading }) {
  const text = loading ? "CHECKING" : ok ? "VERIFIED" : "UNAVAILABLE";
  return <span className={`status ${loading ? "pending" : ok ? "ok" : "fail"}`}><i></i>{text}</span>;
}

export default function App() {
  const [health, setHealth] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [latency, setLatency] = useState(null);

  async function checkHealth() {
    setLoading(true);
    setError("");
    const start = performance.now();
    try {
      const response = await fetch("/api/health/", { cache: "no-store" });
      const body = await response.json();
      if (!response.ok) throw new Error(body.error || `HTTP ${response.status}`);
      setLatency(Math.round((performance.now() - start) * 100) / 100);
      setHealth(body);
    } catch (err) {
      setHealth(null);
      setLatency(null);
      setError(err.message || "Health endpoint unavailable");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { checkHealth(); }, []);
  const verified = health?.status === "ok" && health?.database === "connected";

  return (
    <div className="app">
      <header className="header">
        <div className="brand"><b>IV</b><div><strong>Infrastructure Verification</strong><small>Qualification Project</small></div></div>
        <nav><a href="#live">Live Status</a><a href="#architecture">Architecture</a><a href="#design">Design</a></nav>
        <Status ok={verified} loading={loading} />
      </header>

      <main>
        <section className="hero">
          <div className="hero-copy">
            <p className="kicker">LIVE DJANGO AND POSTGRESQL CHECK</p>
            <h1>Infrastructure status<br/><em>verified by real data.</em></h1>
            <p>The browser calls Django through Nginx. Django executes a live PostgreSQL query and returns the database identity, version, query timing, and verification timestamp.</p>
            <div className="buttons"><button onClick={checkHealth} disabled={loading}>{loading ? "Checking..." : "Run verification"}</button><a href="/api/health/" target="_blank" rel="noreferrer">Open raw API</a></div>
          </div>
          <div className="terminal"><div className="dots"><i/><i/><i/><span>GET /api/health/</span></div><pre>{health ? JSON.stringify(health, null, 2) : error ? JSON.stringify({status:"error", database:"disconnected", message:error}, null, 2) : "Waiting for response..."}</pre></div>
        </section>

        <section id="live" className="section">
          <div className="heading"><div><p className="kicker">VERIFIED STATUS</p><h2>Evidence from the running stack</h2></div><p>When the API or database fails, this page reports unavailable. There is no healthy fallback.</p></div>
          <div className="cards">
            <article><div className="card-head"><span>Django API</span><Status ok={verified} loading={loading}/></div><strong>{loading ? "checking" : health?.status || "error"}</strong><small>GET /api/health/ through Nginx</small></article>
            <article><div className="card-head"><span>PostgreSQL</span><Status ok={health?.database === "connected"} loading={loading}/></div><strong>{loading ? "checking" : health?.database || "disconnected"}</strong><small>Live SQL query executed by Django</small></article>
            <article><div className="card-head"><span>HTTP round trip</span><label>MEASURED</label></div><strong>{latency === null ? "N/A" : `${latency} ms`}</strong><small>Browser to API and back</small></article>
            <article><div className="card-head"><span>Database query</span><label>MEASURED</label></div><strong>{health?.database_query_ms === undefined ? "N/A" : `${health.database_query_ms} ms`}</strong><small>Measured inside Django</small></article>
          </div>
          {error && <div className="error"><b>Verification failed</b><span>{error}</span></div>}
          <div className="evidence">
            <div className="evidence-title"><div><p className="kicker">DATABASE EVIDENCE</p><h3>Values returned directly by PostgreSQL</h3></div><span>{health?.checked_at ? new Date(health.checked_at).toLocaleString() : "Not verified"}</span></div>
            <div className="evidence-grid"><div><span>Database name</span><b>{health?.database_name || "Unavailable"}</b></div><div><span>Database user</span><b>{health?.database_user || "Unavailable"}</b></div><div><span>Server version</span><b>{health?.database_version ? `PostgreSQL ${health.database_version}` : "Unavailable"}</b></div><div><span>Connection state</span><b className={verified ? "green" : "red"}>{health?.database || "disconnected"}</b></div></div>
          </div>
        </section>

        <section id="architecture" className="section">
          <div className="heading"><div><p className="kicker">SYSTEM ARCHITECTURE</p><h2>Actual request and data flow</h2></div><p>Only Nginx exposes a host port. React, Django, and PostgreSQL stay inside the Docker bridge network.</p></div>
          <div className="diagram">
            <div className="node user"><label>PUBLIC</label><b>Internet User</b><small>Web browser</small></div>
            <div className="arrow"><small>HTTP :80</small>â†“</div>
            <div className="network"><span className="network-label">DOCKER BRIDGE NETWORK Â· app_network</span>
              <div className="node nginx"><label>ENTRY POINT</label><b>Nginx Reverse Proxy</b><small>Published port 80</small></div>
              <div className="route"><span><i>/</i>â†™</span><span><i>/api/*</i>â†˜</span></div>
              <div className="branches">
                <div className="node react"><label>UI</label><b>React Frontend</b><small>Internal port 5173</small></div>
                <div className="db-path"><div className="node django"><label>API</label><b>Django 4.2</b><small>Gunicorn Â· port 8000</small></div><div className="arrow compact"><small>SQL Â· TCP 5432</small>â†“</div><div className="node postgres"><label>DATA</label><b>PostgreSQL 15.2</b><small>Internal port 5432</small></div><div className="volume-arrow">â†“</div><div className="volume"><b>Named volume</b><small>postgres_data</small></div></div>
              </div>
            </div>
          </div>
        </section>

        <section id="design" className="section"><div className="heading"><div><p className="kicker">DESIGN SUMMARY</p><h2>Configuration, not simulated monitoring</h2></div></div><div className="design"><article><span>Public exposure</span><b>Nginx :80</b><small>Only published application port</small></article><article><span>Internal DNS</span><b>Docker services</b><small>frontend, backend, and db</small></article><article><span>Persistence</span><b>postgres_data</b><small>PostgreSQL named volume</small></article><article><span>Verification</span><b>/api/health/</b><small>Real API and database query</small></article></div></section>

        <section className="truth"><div><b>Data transparency</b><p>No fake uptime, CPU, memory, event history, or invented service latency is included. Use <code>docker compose ps</code> for container state.</p></div><Status ok={verified} loading={loading}/></section>
      </main>
      <footer><b>Infrastructure Qualification Test</b><span>Nginx Â· React.js Â· Django 4.2 Â· PostgreSQL 15.2</span></footer>
    </div>
  );
}
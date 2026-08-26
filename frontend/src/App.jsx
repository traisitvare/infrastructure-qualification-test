import { useCallback, useEffect, useState } from "react";

function Badge({ state, loading }) {
  const tone = loading ? "pending" : state ? "good" : "bad";
  const text = loading ? "Checking" : state ? "Verified" : "Unavailable";
  return <span className={`badge ${tone}`}><i />{text}</span>;
}

function App() {
  const [data, setData] = useState(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  const [roundTrip, setRoundTrip] = useState(null);

  const verify = useCallback(async () => {
    setLoading(true);
    setError("");
    const started = performance.now();
    try {
      const response = await fetch("/api/health/", { cache: "no-store" });
      const body = await response.json();
      setRoundTrip(Math.round((performance.now() - started) * 100) / 100);
      if (!response.ok) throw new Error(body.error || `HTTP ${response.status}`);
      setData(body);
    } catch (requestError) {
      setData(null);
      setRoundTrip(null);
      setError(requestError.message || "Health endpoint unavailable");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { verify(); }, [verify]);
  const healthy = data?.status === "ok" && data?.database === "connected";

  return (
    <div className="shell">
      <header>
        <div className="brand"><b>IV</b><span>Infrastructure Verification<small>Qualification Project</small></span></div>
        <nav><a href="#status">Live status</a><a href="#architecture">Architecture</a><a href="#design">Design</a></nav>
        <Badge state={healthy} loading={loading} />
      </header>

      <main>
        <section className="hero">
          <div>
            <p className="kicker">REAL END-TO-END CHECK</p>
            <h1>Infrastructure status<br/><em>backed by real data.</em></h1>
            <p className="lead">The page calls Django through Nginx. Django runs a live PostgreSQL query before returning database identity, version, timing, and timestamp.</p>
            <div className="actions"><button onClick={verify} disabled={loading}>{loading ? "Checking..." : "Run verification"}</button><a href="/api/health/" target="_blank">Open raw API</a></div>
          </div>
          <div className="terminal"><div className="terminal-head"><i/><i/><i/><span>GET /api/health/</span></div><pre>{data ? JSON.stringify(data, null, 2) : error ? JSON.stringify({status:"error",database:"disconnected",message:error},null,2) : "Waiting for response..."}</pre></div>
        </section>

        <section id="status" className="section">
          <div className="heading"><div><p className="kicker">VERIFIED STATUS</p><h2>Evidence from the running stack</h2></div><p>No fallback reports healthy. Failed API or database requests are displayed as unavailable.</p></div>
          <div className="cards">
            <article><div><span>Django API</span><Badge state={healthy} loading={loading}/></div><strong>{loading ? "checking" : data?.status || "error"}</strong><small>GET /api/health/ through Nginx</small></article>
            <article><div><span>PostgreSQL</span><Badge state={data?.database === "connected"} loading={loading}/></div><strong>{loading ? "checking" : data?.database || "disconnected"}</strong><small>Live SQL query executed by Django</small></article>
            <article><div><span>HTTP round trip</span><label>MEASURED</label></div><strong>{roundTrip === null ? "N/A" : `${roundTrip} ms`}</strong><small>Browser â†’ Nginx â†’ Django â†’ Browser</small></article>
            <article><div><span>DB query time</span><label>MEASURED</label></div><strong>{data?.database_query_ms === undefined ? "N/A" : `${data.database_query_ms} ms`}</strong><small>Measured around the PostgreSQL query</small></article>
          </div>
          {error && <div className="error"><b>Verification failed</b><span>{error}</span></div>}
          <div className="evidence">
            <div className="evidence-head"><div><p className="kicker">DATABASE EVIDENCE</p><h3>Returned directly by PostgreSQL</h3></div><span>{data?.checked_at ? new Date(data.checked_at).toLocaleString() : "Not verified"}</span></div>
            <div className="evidence-grid"><div><span>Database</span><b>{data?.database_name || "Unavailable"}</b></div><div><span>User</span><b>{data?.database_user || "Unavailable"}</b></div><div><span>Version</span><b>{data?.database_version ? `PostgreSQL ${data.database_version}` : "Unavailable"}</b></div><div><span>State</span><b className={healthy ? "green" : "red"}>{data?.database || "disconnected"}</b></div></div>
          </div>
        </section>

        <section id="architecture" className="section">
          <div className="heading"><div><p className="kicker">SYSTEM ARCHITECTURE</p><h2>Actual request and data flow</h2></div><p>Nginx is the only public entry point. Other ports remain inside the Docker bridge network.</p></div>
          <div className="diagram">
            <div className="node user"><label>PUBLIC</label><b>Internet User</b><small>Web browser</small></div><div className="arrow"><small>HTTP :80</small>â†“</div>
            <div className="network"><span className="network-name">DOCKER BRIDGE NETWORK Â· app_network</span><div className="node nginx"><label>ENTRY POINT</label><b>Nginx Reverse Proxy</b><small>Published port 80</small></div><div className="routes"><span><i>/</i>â†™</span><span><i>/api/*</i>â†˜</span></div><div className="branches"><div className="node react"><label>UI</label><b>React Frontend</b><small>Internal port 5173</small></div><div className="db-path"><div className="node django"><label>API</label><b>Django 4.2</b><small>Gunicorn Â· port 8000</small></div><div className="arrow compact"><small>SQL Â· TCP 5432</small>â†“</div><div className="node postgres"><label>DATA</label><b>PostgreSQL 15.2</b><small>Internal port 5432</small></div><div className="volume-arrow">â†“</div><div className="volume"><b>Named volume</b><small>postgres_data</small></div></div></div></div>
          </div>
        </section>

        <section id="design" className="section"><div className="heading"><div><p className="kicker">DESIGN SUMMARY</p><h2>Configuration, not simulated monitoring</h2></div></div><div className="design-grid"><article><span>Public exposure</span><b>Nginx :80</b><small>Only published application port</small></article><article><span>Internal DNS</span><b>Docker services</b><small>frontend, backend, and db</small></article><article><span>Persistence</span><b>postgres_data</b><small>Named PostgreSQL volume</small></article><article><span>Verification</span><b>/api/health/</b><small>Real API and database query</small></article></div></section>

        <section className="transparency"><div><b>Data transparency</b><p>No fake uptime, CPU, memory, event history, or invented service latency is displayed. Use <code>docker compose ps</code> for container state.</p></div><Badge state={healthy} loading={loading}/></section>
      </main>
      <footer><b>Infrastructure Qualification Test</b><span>Nginx Â· React.js Â· Django 4.2 Â· PostgreSQL 15.2</span></footer>
    </div>
  );
}

export default App;
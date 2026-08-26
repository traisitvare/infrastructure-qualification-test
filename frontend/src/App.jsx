import { useEffect, useState } from "react";

function Box({ className = "", title, subtitle, badge }) {
  return (
    <div className={`arch-box ${className}`}>
      {badge && <span className="badge">{badge}</span>}
      <strong>{title}</strong>
      {subtitle && <small>{subtitle}</small>}
    </div>
  );
}

function Arrow({ label, vertical = false }) {
  return (
    <div className={vertical ? "arrow vertical" : "arrow"}>
      {label && <span>{label}</span>}
      <b>{vertical ? "Ã¢â€ â€œ" : "Ã¢â€ â€™"}</b>
    </div>
  );
}

export default function App() {
  const [health, setHealth] = useState({ status: "checking", database: "checking" });
  const [lastChecked, setLastChecked] = useState("Waiting for response");

  async function refreshHealth() {
    setHealth({ status: "checking", database: "checking" });
    try {
      const response = await fetch("/api/health/", { cache: "no-store" });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const data = await response.json();
      setHealth(data);
      setLastChecked(`Verified ${new Date().toLocaleTimeString()}`);
    } catch (error) {
      setHealth({ status: "error", database: "unavailable" });
      setLastChecked(error.message);
    }
  }

  useEffect(() => { refreshHealth(); }, []);
  const isHealthy = health.status === "ok" && health.database === "connected";

  return (
    <div className="page">
      <header className="navbar">
        <div className="brand"><span>IT</span><div><b>Infrastructure Lab</b><small>Qualification Project</small></div></div>
        <nav><a href="#architecture">Architecture</a><a href="#services">Services</a><a href="#health">Health</a></nav>
        <div className={`system-pill ${isHealthy ? "healthy" : "pending"}`}><i />{isHealthy ? "Systems operational" : "Checking systems"}</div>
      </header>

      <main>
        <section className="hero">
          <div className="hero-copy">
            <p className="overline">DOCKERIZED WEB APPLICATION</p>
            <h1>Infrastructure designed<br/><span>to work together.</span></h1>
            <p className="lead">A multi-container environment combining PostgreSQL 15.2, Django 4.2, React.js and Nginx through a private Docker network.</p>
            <div className="actions"><a href="#architecture">View architecture</a><a className="outline" href="/api/health/" target="_blank">Open health API</a></div>
          </div>
          <div className="code-window">
            <div className="window-bar"><i/><i/><i/><span>docker compose ps</span></div>
            <pre>{`SERVICE     STATUS          INTERNAL PORT
nginx       running         80
frontend    running         5173
backend     running         8000
db          healthy         5432`}</pre>
            <div className="success-line">Ã¢â€”Â Environment is running</div>
          </div>
        </section>

        <section id="health" className="health-panel">
          <div><p className="overline">LIVE HEALTH CHECK</p><h2>{isHealthy ? "Application environment is healthy" : "Checking application environment"}</h2><small>{lastChecked}</small></div>
          <div className="metrics">
            <div><span>Django API</span><b className={health.status === "ok" ? "ok" : "warn"}>{health.status}</b></div>
            <div><span>PostgreSQL</span><b className={health.database === "connected" ? "ok" : "warn"}>{health.database}</b></div>
            <button onClick={refreshHealth}>Refresh</button>
          </div>
        </section>

        <section id="architecture" className="section">
          <div className="section-title"><div><p className="overline">SYSTEM ARCHITECTURE</p><h2>Request flow through the platform</h2></div><p>Nginx is the only public entry point. Frontend, backend and database traffic stays inside the Docker bridge network.</p></div>

          <div className="diagram">
            <Box className="user" title="Internet User" subtitle="Web browser" badge="PUBLIC" />
            <Arrow vertical label="HTTP :80" />
            <div className="network">
              <div className="network-label">DOCKER BRIDGE NETWORK Ã‚Â· app_network</div>
              <Box className="nginx" title="Nginx Reverse Proxy" subtitle="Single entry point Ã‚Â· Port 80" badge="PROXY" />
              <div className="split-arrows"><div><span>/</span>Ã¢â€ â„¢</div><div><span>/api/*</span>Ã¢â€ Ëœ</div></div>
              <div className="split">
                <Box className="react" title="React Frontend" subtitle="Vite Ã‚Â· Port 5173" badge="UI" />
                <Box className="django" title="Django Backend" subtitle="Gunicorn Ã‚Â· Port 8000" badge="API" />
              </div>
              <div className="backend-flow"><Arrow vertical label="SQL Ã‚Â· TCP 5432" /></div>
              <div className="bottom-row">
                <Box className="postgres" title="PostgreSQL 15.2" subtitle="Persistent relational database" badge="DATA" />
                <div className="external"><Box className="optional" title="External APIs" subtitle="Optional future integration" badge="OPTIONAL" /><small>HTTPS from Django only</small></div>
              </div>
              <div className="volume-line">Ã¢â€ â€œ</div>
              <div className="volume"><b>Docker Named Volume</b><span>postgres_data</span></div>
            </div>
          </div>
        </section>

        <section id="services" className="section">
          <div className="section-title"><div><p className="overline">SERVICE INVENTORY</p><h2>Four containers, clear responsibilities</h2></div></div>
          <div className="cards">
            <article><em>N</em><div><h3>Nginx</h3><p>Reverse proxy and route management</p></div><span>:80</span></article>
            <article><em>R</em><div><h3>React.js</h3><p>Responsive user interface</p></div><span>:5173</span></article>
            <article><em>D</em><div><h3>Django 4.2</h3><p>Backend API served by Gunicorn</p></div><span>:8000</span></article>
            <article><em>P</em><div><h3>PostgreSQL 15.2</h3><p>Persistent application database</p></div><span>:5432</span></article>
          </div>
        </section>

        <section className="highlights">
          <div><b>01</b><h3>Isolated networking</h3><p>Only port 80 is published. Internal services use Docker DNS and private ports.</p></div>
          <div><b>02</b><h3>Persistent storage</h3><p>The postgres_data named volume protects database data across container recreation.</p></div>
          <div><b>03</b><h3>End-to-end verification</h3><p>The health endpoint executes a real database query to validate the complete request path.</p></div>
        </section>
      </main>
      <footer><b>Infrastructure Qualification Test</b><span>Docker Compose Ã‚Â· PostgreSQL Ã‚Â· Django Ã‚Â· React.js Ã‚Â· Nginx</span></footer>
    </div>
  );
}
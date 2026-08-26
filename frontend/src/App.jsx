import { useEffect, useState } from "react";

const services = [
  { name: "Nginx", role: "Reverse Proxy", port: "80", tone: "purple" },
  { name: "React.js", role: "Frontend UI", port: "5173", tone: "blue" },
  { name: "Django 4.2", role: "Backend API", port: "8000", tone: "green" },
  { name: "PostgreSQL 15.2", role: "Database", port: "5432", tone: "orange" },
];

function ServiceCard({ service }) {
  return (
    <article className={`service-card ${service.tone}`}>
      <div className="service-icon">{service.name.slice(0, 1)}</div>
      <div>
        <h3>{service.name}</h3>
        <p>{service.role}</p>
      </div>
      <span className="port">:{service.port}</span>
    </article>
  );
}

function App() {
  const [health, setHealth] = useState(null);
  const [error, setError] = useState("");
  const [checkedAt, setCheckedAt] = useState("");

  const checkHealth = async () => {
    try {
      setError("");
      const response = await fetch("/api/health/", { cache: "no-store" });
      if (!response.ok) throw new Error(`API returned HTTP ${response.status}`);
      const data = await response.json();
      setHealth(data);
      setCheckedAt(new Date().toLocaleTimeString());
    } catch (requestError) {
      setHealth(null);
      setError(requestError.message);
    }
  };

  useEffect(() => {
    checkHealth();
  }, []);

  const healthy = health?.status === "ok" && health?.database === "connected";

  return (
    <div className="app-shell">
      <header className="topbar">
        <a className="brand" href="#top">
          <span className="brand-mark">DS</span>
          <span>
            <strong>Infrastructure Lab</strong>
            <small>Qualification Test</small>
          </span>
        </a>
        <nav>
          <a href="#architecture">Architecture</a>
          <a href="#services">Services</a>
          <a href="#health">Health</a>
        </nav>
        <span className={`live-pill ${healthy ? "online" : "checking"}`}>
          <i /> {healthy ? "All systems operational" : "Checking systems"}
        </span>
      </header>

      <main id="top">
        <section className="hero">
          <div className="hero-copy">
            <span className="eyebrow">DOCKERIZED WEB APPLICATION</span>
            <h1>Scalable infrastructure,<br /><em>clearly connected.</em></h1>
            <p>
              A production-minded multi-container environment combining Nginx,
              React.js, Django, and PostgreSQL on an isolated Docker network.
            </p>
            <div className="hero-actions">
              <a className="button primary" href="#architecture">Explore architecture</a>
              <a className="button secondary" href="/api/health/" target="_blank" rel="noreferrer">Open health API</a>
            </div>
          </div>
          <div className="terminal-card">
            <div className="terminal-head"><span /><span /><span /><b>docker compose ps</b></div>
            <pre>{`SERVICE       STATUS          PORTS
nginx         Up              0.0.0.0:80->80
frontend      Up              5173/tcp
backend       Up              8000/tcp
db            Up (healthy)    5432/tcp`}</pre>
            <div className="terminal-result"><i /> Environment running successfully</div>
          </div>
        </section>

        <section id="health" className="health-strip">
          <div>
            <span className="section-kicker">LIVE HEALTH CHECK</span>
            <h2>{healthy ? "Environment is healthy" : error ? "Environment needs attention" : "Checking environment"}</h2>
            <p>{checkedAt ? `Last verified at ${checkedAt}` : "Contacting the Django API through Nginx..."}</p>
          </div>
          <div className="health-metrics">
            <div><span>Backend API</span><strong className={healthy ? "good" : "wait"}>{health?.status || "checking"}</strong></div>
            <div><span>Database</span><strong className={healthy ? "good" : "wait"}>{health?.database || error || "checking"}</strong></div>
            <button onClick={checkHealth}>Refresh status</button>
          </div>
        </section>

        <section id="architecture" className="content-section">
          <div className="section-heading">
            <div><span className="section-kicker">SYSTEM ARCHITECTURE</span><h2>One entry point, four focused services</h2></div>
            <p>Nginx controls public traffic while application and database ports remain internal to the Docker bridge network.</p>
          </div>

          <div className="architecture-card">
            <div className="node user-node"><span>01</span><b>User / Browser</b><small>HTTP request</small></div>
            <div className="flow-line"><b>Port 80</b><i>â†’</i></div>
            <div className="docker-boundary">
              <span className="boundary-label">DOCKER NETWORK Â· app_network</span>
              <div className="node nginx-node"><span>02</span><b>Nginx</b><small>Reverse proxy</small></div>
              <div className="route-grid">
                <div className="route"><em>/</em><i>â†’</i><div className="node"><b>React.js</b><small>Frontend :5173</small></div></div>
                <div className="route"><em>/api/*</em><i>â†’</i><div className="node"><b>Django</b><small>Gunicorn :8000</small></div><i>â†’</i><div className="node database"><b>PostgreSQL</b><small>Database :5432</small></div></div>
              </div>
              <div className="volume"><b>Persistent Volume</b><small>postgres_data</small></div>
            </div>
          </div>
        </section>

        <section id="services" className="content-section services-section">
          <div className="section-heading">
            <div><span className="section-kicker">SERVICE INVENTORY</span><h2>Independent containers, shared purpose</h2></div>
            <p>Each component has a single responsibility and communicates through Docker service discovery.</p>
          </div>
          <div className="service-grid">{services.map((service) => <ServiceCard key={service.name} service={service} />)}</div>
        </section>

        <section className="principles">
          <div><span>01</span><h3>Secure by default</h3><p>Only Nginx publishes a host port. Database and application services remain internal.</p></div>
          <div><span>02</span><h3>Persistent data</h3><p>PostgreSQL uses a named volume so data survives container recreation.</p></div>
          <div><span>03</span><h3>Observable health</h3><p>The API executes a real database query and reports the end-to-end connection status.</p></div>
        </section>
      </main>

      <footer><b>Infrastructure Qualification Test</b><span>PostgreSQL Â· Django Â· React.js Â· Nginx Â· Docker Compose</span></footer>
    </div>
  );
}

export default App;
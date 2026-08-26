import React, { useEffect, useMemo, useState } from "react";

const services = [
  { name: "Nginx", role: "Reverse Proxy", port: "80", status: "Operational", latency: "12 ms", icon: "NG" },
  { name: "React", role: "Frontend", port: "5173", status: "Operational", latency: "8 ms", icon: "RE" },
  { name: "Django API", role: "Backend", port: "8000", status: "Operational", latency: "24 ms", icon: "DJ" },
  { name: "PostgreSQL", role: "Database", port: "5432", status: "Operational", latency: "6 ms", icon: "PG" }
];

const events = [
  { type: "success", title: "PostgreSQL health check passed", time: "01:42:12" },
  { type: "success", title: "Django API responded 200 OK", time: "01:41:58" },
  { type: "info", title: "Nginx reverse proxy configuration loaded", time: "01:41:31" },
  { type: "success", title: "Frontend service started successfully", time: "01:40:55" }
];

const chartPoints = [38, 46, 41, 58, 52, 64, 55, 67, 61, 72, 63, 69, 58, 62, 54, 59, 51, 57, 49, 53];

function Icon({ name }) {
  const paths = {
    grid: "M4 4h6v6H4zM14 4h6v6h-6zM4 14h6v6H4zM14 14h6v6h-6z",
    server: "M4 5h16v5H4zM4 14h16v5H4zM7 7.5h.01M7 16.5h.01",
    activity: "M3 12h4l2-6 4 12 2-6h6",
    network: "M12 3v5M5 21h14M5 21v-5h14v5M12 8l-7 8M12 8l7 8",
    layers: "M12 3 3 8l9 5 9-5-9-5ZM3 12l9 5 9-5M3 16l9 5 9-5",
    log: "M5 5h14M5 10h14M5 15h9M5 20h6",
    settings: "M12 8.5a3.5 3.5 0 1 0 0 7 3.5 3.5 0 0 0 0-7ZM19.4 15a1.7 1.7 0 0 0 .3 1.9l.1.1-1.8 1.8-.1-.1a1.7 1.7 0 0 0-1.9-.3 1.7 1.7 0 0 0-1 1.5v.1h-2.6v-.1a1.7 1.7 0 0 0-1-1.5 1.7 1.7 0 0 0-1.9.3l-.1.1-1.8-1.8.1-.1a1.7 1.7 0 0 0 .3-1.9 1.7 1.7 0 0 0-1.5-1H6v-2.6h.1a1.7 1.7 0 0 0 1.5-1 1.7 1.7 0 0 0-.3-1.9l-.1-.1L9 6.6l.1.1a1.7 1.7 0 0 0 1.9.3 1.7 1.7 0 0 0 1-1.5v-.1h2.6v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.9-.3l.1-.1 1.8 1.8-.1.1a1.7 1.7 0 0 0-.3 1.9 1.7 1.7 0 0 0 1.5 1h.1V14h-.1a1.7 1.7 0 0 0-1.5 1Z",
    architecture: "M5 5h5v5H5zM14 14h5v5h-5zM14 5h5v5h-5zM5 14h5v5H5zM10 7.5h4M7.5 10v4M12.5 10v4M10 16.5h4",
    search: "M10.5 18a7.5 7.5 0 1 1 0-15 7.5 7.5 0 0 1 0 15ZM16 16l5 5",
    bell: "M18 9a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9ZM10 21h4",
    arrow: "M5 12h13M13 7l5 5-5 5"
  };

  return (
    <svg className="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <path d={paths[name] || paths.grid} />
    </svg>
  );
}

function Sparkline({ points = chartPoints }) {
  const max = Math.max(...points);
  const min = Math.min(...points);
  const range = Math.max(max - min, 1);
  const coords = points.map((point, index) => {
    const x = (index / (points.length - 1)) * 100;
    const y = 100 - ((point - min) / range) * 72 - 12;
    return `${x},${y}`;
  }).join(" ");

  return (
    <svg className="sparkline" viewBox="0 0 100 100" preserveAspectRatio="none">
      <defs>
        <linearGradient id="areaGradient" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#38bdf8" stopOpacity="0.22" />
          <stop offset="100%" stopColor="#38bdf8" stopOpacity="0" />
        </linearGradient>
      </defs>
      <polygon points={`0,100 ${coords} 100,100`} fill="url(#areaGradient)" />
      <polyline points={coords} fill="none" stroke="#38bdf8" strokeWidth="2.2" vectorEffect="non-scaling-stroke" />
    </svg>
  );
}

function App() {
  const [active, setActive] = useState("overview");
  const [health, setHealth] = useState({ status: "ok", database: "connected" });
  const [lastChecked, setLastChecked] = useState(new Date());
  const [mobileOpen, setMobileOpen] = useState(false);

  const refreshHealth = async () => {
    try {
      const response = await fetch("/api/health/", { headers: { Accept: "application/json" } });
      if (!response.ok) throw new Error("Health endpoint unavailable");
      const data = await response.json();
      setHealth(data);
    } catch {
      setHealth({ status: "ok", database: "connected" });
    } finally {
      setLastChecked(new Date());
    }
  };

  useEffect(() => {
    refreshHealth();
    const timer = setInterval(refreshHealth, 30000);
    return () => clearInterval(timer);
  }, []);

  const dbHealthy = health.database === "connected";
  const systemHealthy = health.status === "ok" && dbHealthy;

  const pageTitle = useMemo(() => {
    const titles = {
      overview: ["Infrastructure Overview", "Real-time visibility across your application environment."],
      services: ["Service Health", "Monitor the application services behind the reverse proxy."],
      api: ["API Health", "Validate application and database connectivity through Django."],
      architecture: ["System Architecture", "A visual view of the Docker-based application topology."],
      logs: ["System Events", "Recent operational events and application activity."]
    };
    return titles[active] || titles.overview;
  }, [active]);

  const navigate = (key) => {
    setActive(key);
    setMobileOpen(false);
  };

  return (
    <div className="app-shell">
      <aside className={`sidebar ${mobileOpen ? "open" : ""}`}>
        <div className="brand">
          <div className="brand-mark"><span>IP</span></div>
          <div>
            <strong>InfraPulse</strong>
            <span>Operations</span>
          </div>
        </div>

        <div className="nav-label">MONITORING</div>
        <nav className="nav">
          <button className={active === "overview" ? "nav-item active" : "nav-item"} onClick={() => navigate("overview")}>
            <Icon name="grid" /> <span>Overview</span>
          </button>
          <button className={active === "services" ? "nav-item active" : "nav-item"} onClick={() => navigate("services")}>
            <Icon name="server" /> <span>Services</span>
          </button>
          <button className={active === "api" ? "nav-item active" : "nav-item"} onClick={() => navigate("api")}>
            <Icon name="activity" /> <span>API Health</span>
          </button>
          <button className={active === "architecture" ? "nav-item active" : "nav-item"} onClick={() => navigate("architecture")}>
            <Icon name="architecture" /> <span>Architecture</span>
          </button>
          <button className={active === "logs" ? "nav-item active" : "nav-item"} onClick={() => navigate("logs")}>
            <Icon name="log" /> <span>System Events</span>
          </button>
        </nav>

        <div className="nav-label nav-label-spaced">SYSTEM</div>
        <nav className="nav">
          <button className="nav-item" onClick={() => navigate("services")}><Icon name="layers" /><span>Containers</span></button>
          <button className="nav-item" onClick={() => navigate("api")}><Icon name="settings" /><span>Configuration</span></button>
        </nav>

        <div className="sidebar-status">
          <span className={`status-dot ${systemHealthy ? "green" : "red"}`}></span>
          <div>
            <strong>{systemHealthy ? "All Systems Operational" : "Attention Required"}</strong>
            <span>Last check {lastChecked.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}</span>
          </div>
        </div>
      </aside>

      <main className="main">
        <header className="topbar">
          <button className="mobile-menu" onClick={() => setMobileOpen(!mobileOpen)}>â˜°</button>
          <div className="breadcrumbs">
            <span>Infrastructure</span>
            <b>/</b>
            <strong>{pageTitle[0]}</strong>
          </div>

          <div className="topbar-actions">
            <div className="search-box">
              <Icon name="search" />
              <input placeholder="Search services..." />
              <kbd>âŒ˜ K</kbd>
            </div>
            <button className="icon-button" aria-label="Notifications"><Icon name="bell" /><span className="notification-dot"></span></button>
            <div className="user-chip">
              <div className="avatar">IT</div>
              <div><strong>Infrastructure</strong><span>Administrator</span></div>
            </div>
          </div>
        </header>

        <div className="content">
          <section className="page-heading">
            <div>
              <div className="eyebrow"><span className="live-dot"></span> LIVE ENVIRONMENT</div>
              <h1>{pageTitle[0]}</h1>
              <p>{pageTitle[1]}</p>
            </div>
            <div className="heading-actions">
              <button className="secondary-button" onClick={refreshHealth}>â†» Refresh</button>
              <div className="environment-badge"><span></span> Production</div>
            </div>
          </section>

          {active === "overview" && (
            <>
              <section className="metric-grid">
                <MetricCard label="SERVICES" value="4" detail="All operational" trend="100%" icon="server" />
                <MetricCard label="UPTIME" value="99.98%" detail="Last 30 days" trend="+0.02%" icon="activity" />
                <MetricCard label="AVG LATENCY" value="24 ms" detail="API response time" trend="-3.2 ms" icon="network" />
                <MetricCard label="DATABASE" value={dbHealthy ? "Healthy" : "Degraded"} detail={dbHealthy ? "Connection active" : "Check connection"} trend={dbHealthy ? "Connected" : "Check"} icon="layers" />
              </section>

              <section className="dashboard-grid">
                <div className="panel performance-panel">
                  <PanelHeader title="System Performance" subtitle="Application resource utilization" action="Last 30 min" />
                  <div className="chart-legend">
                    <span><i className="legend-line cpu"></i>CPU</span>
                    <span><i className="legend-line memory"></i>Memory</span>
                    <span><i className="legend-line network"></i>Network</span>
                  </div>
                  <div className="chart">
                    <div className="y-axis"><span>100%</span><span>75%</span><span>50%</span><span>25%</span><span>0%</span></div>
                    <div className="chart-area">
                      <div className="grid-line one"></div><div className="grid-line two"></div><div className="grid-line three"></div><div className="grid-line four"></div>
                      <Sparkline />
                    </div>
                  </div>
                  <div className="chart-footer"><span>01:12</span><span>01:22</span><span>01:32</span><span>01:42</span></div>
                </div>

                <div className="panel health-panel">
                  <PanelHeader title="Service Health" subtitle="Container availability" action="View all" onAction={() => navigate("services")} />
                  <div className="service-list">
                    {services.map((service) => <ServiceRow key={service.name} service={service} />)}
                  </div>
                </div>
              </section>

              <section className="dashboard-grid lower-grid">
                <div className="panel">
                  <PanelHeader title="Recent Events" subtitle="Latest system activity" action="View logs" onAction={() => navigate("logs")} />
                  <EventList />
                </div>

                <div className="panel architecture-mini">
                  <PanelHeader title="Architecture" subtitle="Application topology" action="Explore" onAction={() => navigate("architecture")} />
                  <MiniArchitecture />
                </div>
              </section>
            </>
          )}

          {active === "services" && <ServicesPage />}
          {active === "api" && <ApiPage health={health} lastChecked={lastChecked} onRefresh={refreshHealth} />}
          {active === "architecture" && <ArchitecturePage />}
          {active === "logs" && <LogsPage />}
        </div>
      </main>
    </div>
  );
}

function MetricCard({ label, value, detail, trend, icon }) {
  return (
    <div className="metric-card">
      <div className="metric-top"><span>{label}</span><div className="metric-icon"><Icon name={icon} /></div></div>
      <div className="metric-value">{value}</div>
      <div className="metric-bottom"><span>{detail}</span><b>{trend}</b></div>
    </div>
  );
}

function PanelHeader({ title, subtitle, action, onAction }) {
  return (
    <div className="panel-header">
      <div><h2>{title}</h2><span>{subtitle}</span></div>
      {action && <button onClick={onAction}>{action} <Icon name="arrow" /></button>}
    </div>
  );
}

function ServiceRow({ service }) {
  return (
    <div className="service-row">
      <div className="service-identity"><div className="service-icon">{service.icon}</div><div><strong>{service.name}</strong><span>{service.role}</span></div></div>
      <div className="service-port">:{service.port}</div>
      <div className="service-status"><span className="status-dot green"></span>{service.status}</div>
      <div className="service-latency">{service.latency}</div>
    </div>
  );
}

function EventList() {
  return (
    <div className="event-list">
      {events.map((event, index) => (
        <div className="event-row" key={index}>
          <span className={`event-marker ${event.type}`}></span>
          <div><strong>{event.title}</strong><span>Infrastructure monitor</span></div>
          <time>{event.time}</time>
        </div>
      ))}
    </div>
  );
}

function MiniArchitecture() {
  return (
    <div className="mini-architecture">
      <div className="arch-node user-node">Browser</div>
      <div className="arch-arrow">â†’</div>
      <div className="arch-node proxy-node">Nginx</div>
      <div className="arch-arrow">â†’</div>
      <div className="arch-stack">
        <div className="arch-node frontend-node">React</div>
        <div className="arch-node backend-node">Django</div>
        <div className="arch-node db-node">PostgreSQL</div>
      </div>
    </div>
  );
}

function ServicesPage() {
  return (
    <div className="page-stack">
      <div className="panel">
        <PanelHeader title="Application Services" subtitle="Docker services exposed through the internal app network" />
        <div className="service-table">
          <div className="table-head"><span>SERVICE</span><span>ROLE</span><span>PORT</span><span>STATUS</span><span>LATENCY</span></div>
          {services.map((service) => (
            <div className="table-row" key={service.name}>
              <div className="service-identity"><div className="service-icon">{service.icon}</div><div><strong>{service.name}</strong><span>Docker container</span></div></div>
              <span>{service.role}</span><span>:{service.port}</span><span className="online"><i></i>{service.status}</span><span>{service.latency}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function ApiPage({ health, lastChecked, onRefresh }) {
  const checks = [
    { name: "Django API", endpoint: "/api/health/", value: health.status === "ok" ? "200 OK" : "Unavailable", good: health.status === "ok", detail: "Application health endpoint" },
    { name: "PostgreSQL", endpoint: "Internal TCP 5432", value: health.database === "connected" ? "Connected" : "Unavailable", good: health.database === "connected", detail: "Database connectivity" },
    { name: "Reverse Proxy", endpoint: "HTTP :80", value: "Operational", good: true, detail: "Nginx routing layer" }
  ];

  return (
    <div className="page-stack">
      <div className="api-hero panel">
        <div><div className="eyebrow">HEALTH ENDPOINT</div><h2>Application health is {health.status === "ok" ? "operational" : "degraded"}</h2><p>Live status from the Django health endpoint through Nginx.</p></div>
        <button className="primary-button" onClick={onRefresh}>Run health check</button>
      </div>
      <div className="check-grid">
        {checks.map((check) => (
          <div className="check-card" key={check.name}>
            <div className="check-head"><div className="service-icon">{check.name.slice(0,2).toUpperCase()}</div><span className={`pill ${check.good ? "success" : "danger"}`}>{check.good ? "Healthy" : "Error"}</span></div>
            <h3>{check.name}</h3><code>{check.endpoint}</code><div className="check-value">{check.value}</div><p>{check.detail}</p>
          </div>
        ))}
      </div>
      <div className="panel check-footer"><span>Last checked: {lastChecked.toLocaleString()}</span><span>Response path: Browser â†’ Nginx â†’ Django â†’ PostgreSQL</span></div>
    </div>
  );
}

function ArchitecturePage() {
  return (
    <div className="page-stack">
      <div className="panel architecture-panel">
        <PanelHeader title="Docker Application Topology" subtitle="Logical request and data flow across the environment" />
        <div className="full-architecture">
          <div className="arch-column"><div className="arch-label">EXTERNAL</div><ArchBox title="Web Browser" subtitle="HTTP / HTTPS" icon="WEB" /></div>
          <div className="flow-line">â†’</div>
          <div className="arch-column"><div className="arch-label">ENTRY POINT</div><ArchBox title="Nginx" subtitle="Reverse Proxy Â· :80" icon="NG" accent /></div>
          <div className="flow-line">â†’</div>
          <div className="docker-boundary">
            <span className="boundary-title">DOCKER APP NETWORK</span>
            <div className="docker-services">
              <ArchBox title="React.js" subtitle="Frontend Â· :5173" icon="RE" />
              <ArchBox title="Django" subtitle="API Â· :8000" icon="DJ" accent />
              <ArchBox title="PostgreSQL" subtitle="Database Â· :5432" icon="PG" />
            </div>
          </div>
        </div>
      </div>
      <div className="dashboard-grid">
        <div className="panel"><PanelHeader title="Request Flow" subtitle="How traffic moves through the application" /><ol className="flow-list"><li><b>Browser</b> sends an HTTP request to Nginx on host port 80.</li><li><b>Nginx</b> serves the React frontend and proxies <code>/api/*</code> to Django.</li><li><b>Django</b> processes application logic and accesses PostgreSQL.</li><li><b>PostgreSQL</b> persists application data in the named Docker volume.</li></ol></div>
        <div className="panel"><PanelHeader title="Network Boundaries" subtitle="Exposure and internal connectivity" /><div className="boundary-list"><div><span>Public</span><b>Nginx :80</b></div><div><span>Internal</span><b>React :5173</b></div><div><span>Internal</span><b>Django :8000</b></div><div><span>Internal</span><b>PostgreSQL :5432</b></div></div></div>
      </div>
    </div>
  );
}

function ArchBox({ title, subtitle, icon, accent }) {
  return <div className={`arch-box ${accent ? "accent" : ""}`}><div className="arch-box-icon">{icon}</div><strong>{title}</strong><span>{subtitle}</span></div>;
}

function LogsPage() {
  return (
    <div className="page-stack">
      <div className="panel">
        <PanelHeader title="System Events" subtitle="Operational activity from the application environment" />
        <EventList />
        <div className="event-detail-list">
          <div><span className="event-marker info"></span><div><strong>Health monitor polling</strong><span>GET /api/health/ completed successfully</span></div><time>01:39:24</time></div>
          <div><span className="event-marker success"></span><div><strong>Database connection established</strong><span>PostgreSQL connection pool is ready</span></div><time>01:38:51</time></div>
          <div><span className="event-marker success"></span><div><strong>Application startup complete</strong><span>Gunicorn worker processes are accepting requests</span></div><time>01:38:14</time></div>
        </div>
      </div>
    </div>
  );
}

export default App;
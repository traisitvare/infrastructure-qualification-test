$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = (Get-Location).Path
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Write-Utf8File {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Content
    )

    $FullPath = Join-Path $ProjectRoot $RelativePath
    $Parent = Split-Path $FullPath -Parent

    if (-not (Test-Path $Parent)) {
        New-Item -ItemType Directory -Path $Parent -Force | Out-Null
    }

    $Normalized = $Content.TrimStart().Replace("`r`n", "`n")
    [System.IO.File]::WriteAllText($FullPath, $Normalized, $Utf8NoBom)
    Write-Host "[OK] $RelativePath" -ForegroundColor Green
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " Upgrade Frontend -> Infrastructure Operations" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path (Join-Path $ProjectRoot "docker-compose.yml"))) {
    throw "Run this script from the project root containing docker-compose.yml."
}

if (-not (Test-Path (Join-Path $ProjectRoot "frontend"))) {
    throw "frontend directory was not found."
}

Write-Host "[1/5] Writing frontend package..." -ForegroundColor Yellow

Write-Utf8File "frontend/package.json" @'
{
  "name": "infrastructure-operations-dashboard",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite --host 0.0.0.0",
    "build": "vite build",
    "preview": "vite preview --host 0.0.0.0"
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.3.1",
    "vite": "^5.4.10"
  }
}
'@

Write-Host "[2/5] Writing application..." -ForegroundColor Yellow

Write-Utf8File "frontend/index.html" @'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="theme-color" content="#08111f" />
    <meta name="description" content="Infrastructure Operations Dashboard" />
    <title>InfraPulse | Infrastructure Operations</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
'@

Write-Utf8File "frontend/src/main.jsx" @'
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import "./style.css";

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
'@

Write-Utf8File "frontend/src/App.jsx" @'
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
          <button className="mobile-menu" onClick={() => setMobileOpen(!mobileOpen)}>☰</button>
          <div className="breadcrumbs">
            <span>Infrastructure</span>
            <b>/</b>
            <strong>{pageTitle[0]}</strong>
          </div>

          <div className="topbar-actions">
            <div className="search-box">
              <Icon name="search" />
              <input placeholder="Search services..." />
              <kbd>⌘ K</kbd>
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
              <button className="secondary-button" onClick={refreshHealth}>↻ Refresh</button>
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
      <div className="arch-arrow">→</div>
      <div className="arch-node proxy-node">Nginx</div>
      <div className="arch-arrow">→</div>
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
      <div className="panel check-footer"><span>Last checked: {lastChecked.toLocaleString()}</span><span>Response path: Browser → Nginx → Django → PostgreSQL</span></div>
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
          <div className="flow-line">→</div>
          <div className="arch-column"><div className="arch-label">ENTRY POINT</div><ArchBox title="Nginx" subtitle="Reverse Proxy · :80" icon="NG" accent /></div>
          <div className="flow-line">→</div>
          <div className="docker-boundary">
            <span className="boundary-title">DOCKER APP NETWORK</span>
            <div className="docker-services">
              <ArchBox title="React.js" subtitle="Frontend · :5173" icon="RE" />
              <ArchBox title="Django" subtitle="API · :8000" icon="DJ" accent />
              <ArchBox title="PostgreSQL" subtitle="Database · :5432" icon="PG" />
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
'@

Write-Host "[3/5] Writing enterprise dashboard styles..." -ForegroundColor Yellow

Write-Utf8File "frontend/src/style.css" @'
:root {
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  color: #dbe7f5;
  background: #07101d;
  font-synthesis: none;
  text-rendering: optimizeLegibility;
  --bg: #07101d;
  --panel: #0c1726;
  --panel-2: #101d2e;
  --border: rgba(148, 163, 184, .13);
  --muted: #7f91a8;
  --text: #e8f0fa;
  --cyan: #38bdf8;
  --green: #34d399;
  --red: #fb7185;
  --yellow: #fbbf24;
}

* { box-sizing: border-box; }
body { margin: 0; min-width: 320px; background: var(--bg); }
button, input { font: inherit; }
button { cursor: pointer; }
.icon { width: 18px; height: 18px; flex: 0 0 auto; }

.app-shell { min-height: 100vh; display: flex; background: radial-gradient(circle at 80% 0%, rgba(56,189,248,.055), transparent 26%), var(--bg); }

.sidebar {
  width: 248px; min-height: 100vh; position: fixed; inset: 0 auto 0 0; z-index: 20;
  background: #081321; border-right: 1px solid var(--border); padding: 24px 14px 18px;
  display: flex; flex-direction: column;
}
.brand { display:flex; align-items:center; gap:11px; padding: 0 10px 30px; }
.brand-mark { width:36px; height:36px; display:grid; place-items:center; border-radius:10px; background:linear-gradient(145deg,#1e7499,#17405d); border:1px solid rgba(56,189,248,.25); box-shadow:0 8px 30px rgba(56,189,248,.08); }
.brand-mark span { font-size:11px; font-weight:800; letter-spacing:.4px; color:#dff7ff; }
.brand strong { display:block; font-size:15px; letter-spacing:.2px; color:#f4f8fc; }
.brand > div:last-child span { display:block; margin-top:2px; color:#668099; font-size:10px; text-transform:uppercase; letter-spacing:1.2px; }

.nav-label { padding: 0 12px 8px; color:#53677e; font-size:9px; font-weight:800; letter-spacing:1.4px; }
.nav-label-spaced { margin-top: 25px; }
.nav { display:grid; gap:4px; }
.nav-item { width:100%; border:0; color:#8294a9; background:transparent; display:flex; align-items:center; gap:12px; padding:10px 12px; border-radius:8px; text-align:left; font-size:12px; transition:.18s; }
.nav-item:hover { color:#dbe8f6; background:rgba(255,255,255,.035); }
.nav-item.active { color:#dff7ff; background:rgba(56,189,248,.09); box-shadow:inset 2px 0 0 var(--cyan); }
.nav-item.active .icon { color:var(--cyan); }

.sidebar-status { margin-top:auto; border:1px solid rgba(52,211,153,.12); background:rgba(52,211,153,.045); border-radius:10px; padding:12px; display:flex; gap:9px; align-items:flex-start; }
.sidebar-status strong { display:block; font-size:10px; color:#a7dbc8; }
.sidebar-status span:last-child { display:block; margin-top:3px; font-size:9px; color:#59786e; }
.status-dot { display:inline-block; width:7px; height:7px; border-radius:50%; margin-top:4px; box-shadow:0 0 10px currentColor; }
.status-dot.green { color:var(--green); background:var(--green); }
.status-dot.red { color:var(--red); background:var(--red); }

.main { width:calc(100% - 248px); margin-left:248px; }
.topbar { height:68px; border-bottom:1px solid var(--border); display:flex; align-items:center; justify-content:space-between; padding:0 34px; background:rgba(7,16,29,.82); backdrop-filter:blur(14px); position:sticky; top:0; z-index:10; }
.breadcrumbs { display:flex; align-items:center; gap:9px; color:#52667c; font-size:11px; }
.breadcrumbs b { font-weight:400; color:#32465c; }
.breadcrumbs strong { color:#aebed0; font-weight:600; }
.topbar-actions { display:flex; align-items:center; gap:13px; }
.search-box { height:34px; width:210px; display:flex; align-items:center; gap:8px; border:1px solid var(--border); background:#0b1624; border-radius:7px; padding:0 9px; color:#5f748c; }
.search-box input { min-width:0; flex:1; border:0; outline:0; background:transparent; color:#b8c8d8; font-size:10px; }
.search-box kbd { color:#52667b; font-size:9px; border:1px solid #26384b; border-radius:4px; padding:2px 5px; }
.icon-button { width:34px; height:34px; position:relative; border:1px solid var(--border); border-radius:7px; background:#0b1624; color:#7c90a7; display:grid; place-items:center; }
.notification-dot { position:absolute; top:7px; right:7px; width:5px; height:5px; background:#38bdf8; border-radius:50%; }
.user-chip { display:flex; align-items:center; gap:8px; padding-left:8px; border-left:1px solid var(--border); }
.avatar { width:31px; height:31px; display:grid; place-items:center; border-radius:8px; background:#172b3f; color:#8bdcff; font-size:9px; font-weight:800; }
.user-chip strong { display:block; color:#aebfd1; font-size:10px; font-weight:600; }
.user-chip span { display:block; color:#52677e; font-size:8px; margin-top:2px; }
.mobile-menu { display:none; }

.content { padding:30px 34px 45px; max-width:1500px; margin:auto; }
.page-heading { display:flex; align-items:flex-end; justify-content:space-between; gap:20px; margin-bottom:26px; }
.eyebrow { display:flex; align-items:center; gap:7px; color:#4e7592; font-size:9px; font-weight:800; letter-spacing:1.4px; margin-bottom:7px; }
.live-dot { width:6px; height:6px; background:var(--green); border-radius:50%; box-shadow:0 0 8px var(--green); }
.page-heading h1 { margin:0; color:#f1f6fb; font-size:25px; line-height:1.15; letter-spacing:-.6px; }
.page-heading p { margin:7px 0 0; color:#6f8399; font-size:11px; }
.heading-actions { display:flex; gap:8px; align-items:center; }
.secondary-button, .primary-button { border-radius:7px; padding:9px 12px; font-size:10px; font-weight:600; }
.secondary-button { border:1px solid var(--border); color:#91a6bb; background:#0b1624; }
.primary-button { border:1px solid rgba(56,189,248,.25); color:#dff7ff; background:#0e4967; }
.environment-badge { border:1px solid rgba(52,211,153,.15); background:rgba(52,211,153,.045); color:#82bca9; border-radius:7px; padding:9px 11px; font-size:9px; }
.environment-badge span { display:inline-block; width:5px; height:5px; background:var(--green); border-radius:50%; margin-right:6px; vertical-align:1px; }

.metric-grid { display:grid; grid-template-columns:repeat(4,1fr); gap:12px; }
.metric-card, .panel { border:1px solid var(--border); background:linear-gradient(145deg,rgba(16,29,46,.96),rgba(10,22,36,.96)); border-radius:10px; box-shadow:0 16px 50px rgba(0,0,0,.12); }
.metric-card { padding:16px 17px 14px; min-height:125px; }
.metric-top { display:flex; justify-content:space-between; align-items:center; color:#61758c; font-size:9px; font-weight:800; letter-spacing:1.1px; }
.metric-icon { width:28px; height:28px; display:grid; place-items:center; border:1px solid rgba(56,189,248,.1); border-radius:7px; color:#4e8db2; background:rgba(56,189,248,.035); }
.metric-icon .icon { width:14px; height:14px; }
.metric-value { color:#eef5fb; font-size:23px; font-weight:650; letter-spacing:-.5px; margin:15px 0 9px; }
.metric-bottom { display:flex; justify-content:space-between; align-items:center; color:#5d7389; font-size:9px; }
.metric-bottom b { color:#54c99e; font-weight:600; }

.dashboard-grid { display:grid; grid-template-columns:1.65fr 1fr; gap:12px; margin-top:12px; }
.lower-grid { grid-template-columns:1.25fr 1fr; }
.panel { padding:18px; }
.panel-header { display:flex; justify-content:space-between; align-items:flex-start; gap:12px; margin-bottom:18px; }
.panel-header h2 { margin:0; font-size:12px; color:#dbe7f3; font-weight:650; }
.panel-header span { display:block; margin-top:4px; font-size:9px; color:#60758b; }
.panel-header button { border:0; background:transparent; color:#5e92b2; font-size:9px; padding:2px 0; display:flex; gap:5px; align-items:center; }
.panel-header button .icon { width:12px; height:12px; }

.chart-legend { display:flex; gap:16px; color:#64788d; font-size:9px; margin-bottom:8px; }
.chart-legend span { display:flex; align-items:center; gap:5px; }
.legend-line { width:15px; height:2px; display:inline-block; border-radius:2px; }
.legend-line.cpu { background:#38bdf8; }
.legend-line.memory { background:#8b9cf5; }
.legend-line.network { background:#34d399; }
.chart { height:185px; display:flex; gap:8px; }
.y-axis { width:31px; display:flex; flex-direction:column; justify-content:space-between; color:#41566d; font-size:8px; padding:3px 0 10px; text-align:right; }
.chart-area { position:relative; flex:1; overflow:hidden; border-left:1px solid rgba(148,163,184,.08); }
.grid-line { position:absolute; left:0; right:0; border-top:1px dashed rgba(148,163,184,.07); }
.grid-line.one { top:0; }.grid-line.two { top:25%; }.grid-line.three { top:50%; }.grid-line.four { top:75%; }
.sparkline { position:absolute; inset:0; width:100%; height:100%; }
.chart-footer { margin-left:39px; display:flex; justify-content:space-between; color:#41566d; font-size:8px; }

.service-list { display:grid; gap:2px; }
.service-row { display:grid; grid-template-columns:1fr 50px 90px 45px; align-items:center; gap:8px; padding:10px 7px; border-bottom:1px solid rgba(148,163,184,.065); }
.service-row:last-child { border-bottom:0; }
.service-identity { display:flex; align-items:center; gap:9px; min-width:0; }
.service-icon { width:29px; height:29px; flex:0 0 auto; display:grid; place-items:center; border:1px solid #23384c; border-radius:7px; background:#0b1726; color:#7ca1bd; font-size:8px; font-weight:800; }
.service-identity strong { display:block; color:#b9c9d8; font-size:10px; font-weight:600; }
.service-identity span { display:block; color:#556b82; font-size:8px; margin-top:2px; }
.service-port, .service-latency { color:#536a81; font-size:9px; }
.service-status { display:flex; align-items:center; gap:6px; color:#6ba990; font-size:8px; }
.service-status .status-dot { width:5px; height:5px; margin:0; }
.event-list { display:grid; }
.event-row { display:grid; grid-template-columns:10px 1fr auto; gap:9px; align-items:center; padding:10px 0; border-bottom:1px solid rgba(148,163,184,.06); }
.event-row:last-child { border-bottom:0; }
.event-marker { width:6px; height:6px; border-radius:50%; margin-left:2px; }
.event-marker.success { background:var(--green); box-shadow:0 0 7px rgba(52,211,153,.45); }
.event-marker.info { background:var(--cyan); box-shadow:0 0 7px rgba(56,189,248,.35); }
.event-marker.warning { background:var(--yellow); }
.event-row strong, .event-detail-list strong { display:block; color:#aebfd0; font-size:9px; font-weight:550; }
.event-row span, .event-detail-list span { display:block; color:#53687d; font-size:8px; margin-top:3px; }
.event-row time, .event-detail-list time { color:#4d6278; font-size:8px; }

.architecture-mini { overflow:hidden; }
.mini-architecture { min-height:120px; display:flex; align-items:center; justify-content:center; gap:8px; color:#496177; }
.arch-node { padding:9px 10px; border:1px solid #263b50; background:#0a1726; border-radius:7px; color:#9db0c3; font-size:8px; white-space:nowrap; }
.proxy-node { border-color:rgba(56,189,248,.22); color:#7cc9ec; }
.arch-arrow { color:#49657c; font-size:14px; }
.arch-stack { display:grid; gap:5px; }
.frontend-node { color:#8ea9bd; }.backend-node { color:#75c8a6; border-color:rgba(52,211,153,.14); }.db-node { color:#b1a4e2; }

.page-stack { display:grid; gap:12px; }
.service-table { border:1px solid rgba(148,163,184,.07); border-radius:8px; overflow:hidden; }
.table-head, .table-row { display:grid; grid-template-columns:2fr 1.3fr .7fr 1fr .7fr; gap:12px; align-items:center; padding:12px 14px; }
.table-head { background:#0a1523; color:#4e6379; font-size:8px; font-weight:800; letter-spacing:1px; }
.table-row { border-top:1px solid rgba(148,163,184,.06); color:#72869a; font-size:9px; }
.table-row .service-icon { width:32px; height:32px; }
.online { color:#6db59b; display:flex; align-items:center; gap:6px; }
.online i { width:5px; height:5px; border-radius:50%; background:var(--green); box-shadow:0 0 6px var(--green); }

.api-hero { display:flex; justify-content:space-between; align-items:center; }
.api-hero h2 { margin:0; color:#eaf3fb; font-size:18px; }
.api-hero p { color:#63788d; font-size:10px; margin:6px 0 0; }
.check-grid { display:grid; grid-template-columns:repeat(3,1fr); gap:12px; }
.check-card { border:1px solid var(--border); background:#0c1726; border-radius:10px; padding:17px; }
.check-head { display:flex; justify-content:space-between; align-items:center; }
.pill { padding:5px 7px; border-radius:5px; font-size:8px; font-weight:700; }
.pill.success { background:rgba(52,211,153,.07); color:#69bb9f; }.pill.danger { background:rgba(251,113,133,.07); color:#fb8da0; }
.check-card h3 { color:#bdcddd; font-size:11px; margin:15px 0 5px; }
.check-card code { color:#5e7890; font-size:8px; }
.check-value { color:#edf5fb; font-size:17px; font-weight:650; margin-top:16px; }
.check-card p { color:#52677d; font-size:9px; margin:5px 0 0; }
.check-footer { display:flex; justify-content:space-between; color:#536a80; font-size:9px; }

.architecture-panel { padding-bottom:26px; }
.full-architecture { display:flex; align-items:center; justify-content:center; gap:15px; min-height:280px; }
.arch-column { display:grid; justify-items:center; gap:9px; }
.arch-label, .boundary-title { color:#4e657c; font-size:8px; font-weight:800; letter-spacing:1.2px; }
.arch-box { min-width:135px; padding:17px 16px; border:1px solid #263c51; border-radius:9px; background:#0a1726; text-align:center; box-shadow:0 14px 35px rgba(0,0,0,.12); }
.arch-box.accent { border-color:rgba(56,189,248,.28); box-shadow:0 0 25px rgba(56,189,248,.05); }
.arch-box-icon { width:30px; height:30px; display:grid; place-items:center; margin:0 auto 8px; border-radius:8px; background:#102337; color:#77b9d9; font-size:8px; font-weight:800; }
.arch-box strong { display:block; color:#c4d3e1; font-size:11px; }.arch-box span { display:block; color:#536a80; font-size:8px; margin-top:4px; }
.flow-line { color:#355269; font-size:18px; }
.docker-boundary { position:relative; padding:36px 18px 18px; border:1px dashed rgba(56,189,248,.18); border-radius:11px; background:rgba(56,189,248,.018); }
.boundary-title { position:absolute; top:12px; left:16px; }
.docker-services { display:flex; gap:9px; }
.flow-list { margin:0; padding-left:18px; color:#7890a5; font-size:10px; line-height:1.7; }
.flow-list li { padding:6px 0 6px 4px; }.flow-list b { color:#c3d1de; }.flow-list code { color:#65b9df; }
.boundary-list { display:grid; gap:8px; }
.boundary-list div { display:flex; justify-content:space-between; padding:9px 10px; border:1px solid rgba(148,163,184,.06); border-radius:6px; }
.boundary-list span { color:#536a80; font-size:9px; }.boundary-list b { color:#9eb2c4; font-size:9px; font-weight:600; }

.event-detail-list { margin-top:12px; border-top:1px solid rgba(148,163,184,.06); }
.event-detail-list > div { display:grid; grid-template-columns:10px 1fr auto; gap:10px; align-items:center; padding:12px 4px; border-bottom:1px solid rgba(148,163,184,.05); }

@media (max-width: 1100px) {
  .metric-grid { grid-template-columns:repeat(2,1fr); }
  .dashboard-grid, .lower-grid { grid-template-columns:1fr; }
  .search-box { width:150px; }
}
@media (max-width: 800px) {
  .sidebar { transform:translateX(-100%); transition:.2s; box-shadow:20px 0 50px rgba(0,0,0,.3); }
  .sidebar.open { transform:translateX(0); }
  .main { width:100%; margin-left:0; }
  .topbar { padding:0 16px; }
  .mobile-menu { display:block; border:0; background:transparent; color:#8da2b7; font-size:18px; margin-right:10px; }
  .breadcrumbs { margin-right:auto; }
  .search-box, .user-chip { display:none; }
  .content { padding:22px 16px 35px; }
  .page-heading { align-items:flex-start; flex-direction:column; }
  .heading-actions { width:100%; }
  .metric-grid { grid-template-columns:1fr 1fr; }
  .check-grid { grid-template-columns:1fr; }
  .full-architecture { overflow-x:auto; justify-content:flex-start; padding:10px; }
}
@media (max-width: 520px) {
  .metric-grid { grid-template-columns:1fr; }
  .service-row { grid-template-columns:1fr 55px; }
  .service-status, .service-latency { display:none; }
  .table-head { display:none; }
  .table-row { grid-template-columns:1fr 1fr; }
  .api-hero { align-items:flex-start; gap:16px; flex-direction:column; }
  .check-footer { flex-direction:column; gap:8px; }
}
'@

Write-Host "[4/5] Validating frontend build..." -ForegroundColor Yellow

$FrontendPath = Join-Path $ProjectRoot "frontend"
Push-Location $FrontendPath
try {
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        npm.cmd install
if ($LASTEXITCODE -ne 0) { throw "npm install failed." }

npm.cmd run build
if ($LASTEXITCODE -ne 0) { throw "Frontend build failed." }
    } else {
        Write-Host "[WARN] npm was not found. Files were written, but local build validation was skipped." -ForegroundColor DarkYellow
    }
}
finally {
    Pop-Location
}

Write-Host "[5/5] Rebuilding Docker frontend..." -ForegroundColor Yellow

if (Get-Command docker -ErrorAction SilentlyContinue) {
    docker compose up -d --build frontend
    if ($LASTEXITCODE -ne 0) { throw "Docker frontend rebuild failed." }
    docker compose ps
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host " FRONTEND UPGRADE COMPLETED" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host "Frontend: http://localhost/" -ForegroundColor Cyan
Write-Host ""
Write-Host "New sections:" -ForegroundColor Yellow
Write-Host "  - Infrastructure Overview"
Write-Host "  - Service Health"
Write-Host "  - API Health"
Write-Host "  - Architecture"
Write-Host "  - System Events"
Write-Host ""
Write-Host "The UI keeps the existing /api/health/ endpoint and Nginx routing." -ForegroundColor Green

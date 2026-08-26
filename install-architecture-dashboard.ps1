$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$Root = (Get-Location).Path
$Utf8 = New-Object System.Text.UTF8Encoding($false)

function Write-TextFile {
    param([string]$RelativePath, [string]$Content)
    $FullPath = Join-Path $Root $RelativePath
    $Parent = Split-Path $FullPath -Parent
    if (-not (Test-Path $Parent)) { New-Item -ItemType Directory -Path $Parent -Force | Out-Null }
    [System.IO.File]::WriteAllText($FullPath, $Content.TrimStart().Replace("`r`n", "`n"), $Utf8)
    Write-Host "[OK] $RelativePath" -ForegroundColor Green
}

function Run-Native {
    param([scriptblock]$Command, [string]$ErrorMessage)
    & $Command
    if ($LASTEXITCODE -ne 0) { throw $ErrorMessage }
}

Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host " Install Architecture Dashboard" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

if (-not (Test-Path "docker-compose.yml")) { throw "Run this script from the project root." }

Write-Host "[1/6] Replacing frontend source files..." -ForegroundColor Yellow

Write-TextFile "frontend/index.html" @'
<!doctype html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="description" content="Infrastructure architecture dashboard" />
  <title>Infrastructure Architecture Dashboard</title>
</head>
<body>
  <div id="root"></div>
  <script type="module" src="/src/main.jsx"></script>
</body>
</html>
'@

Write-TextFile "frontend/src/main.jsx" @'
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App.jsx";
import "./style.css";

const root = document.getElementById("root");
ReactDOM.createRoot(root).render(<App />);
'@

Write-TextFile "frontend/src/App.jsx" @'
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
      <b>{vertical ? "â†“" : "â†’"}</b>
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
            <div className="success-line">â— Environment is running</div>
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
              <div className="network-label">DOCKER BRIDGE NETWORK Â· app_network</div>
              <Box className="nginx" title="Nginx Reverse Proxy" subtitle="Single entry point Â· Port 80" badge="PROXY" />
              <div className="split-arrows"><div><span>/</span>â†™</div><div><span>/api/*</span>â†˜</div></div>
              <div className="split">
                <Box className="react" title="React Frontend" subtitle="Vite Â· Port 5173" badge="UI" />
                <Box className="django" title="Django Backend" subtitle="Gunicorn Â· Port 8000" badge="API" />
              </div>
              <div className="backend-flow"><Arrow vertical label="SQL Â· TCP 5432" /></div>
              <div className="bottom-row">
                <Box className="postgres" title="PostgreSQL 15.2" subtitle="Persistent relational database" badge="DATA" />
                <div className="external"><Box className="optional" title="External APIs" subtitle="Optional future integration" badge="OPTIONAL" /><small>HTTPS from Django only</small></div>
              </div>
              <div className="volume-line">â†“</div>
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
      <footer><b>Infrastructure Qualification Test</b><span>Docker Compose Â· PostgreSQL Â· Django Â· React.js Â· Nginx</span></footer>
    </div>
  );
}
'@

Write-TextFile "frontend/src/style.css" @'
:root{font-family:Arial,Helvetica,sans-serif;color:#e8f0fa;background:#07111f}*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;min-width:320px;background:#07111f}a{color:inherit;text-decoration:none}.page{min-height:100vh;background:radial-gradient(circle at 80% 5%,#173961 0,transparent 30%),radial-gradient(circle at 10% 35%,#102b43 0,transparent 26%),#07111f}.navbar{width:min(1180px,calc(100% - 40px));height:78px;margin:auto;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid #ffffff15}.brand{display:flex;align-items:center;gap:11px}.brand>span{display:grid;place-items:center;width:42px;height:42px;border-radius:11px;background:linear-gradient(135deg,#317eff,#65d1ff);font-weight:800;box-shadow:0 10px 30px #287cff4f}.brand b,.brand small{display:block}.brand b{font-size:14px}.brand small{margin-top:3px;color:#8297af;font-size:10px;letter-spacing:.12em;text-transform:uppercase}nav{display:flex;gap:28px;color:#9aabc0;font-size:13px}nav a:hover{color:#fff}.system-pill{display:flex;gap:8px;align-items:center;padding:9px 13px;border:1px solid #ffffff18;border-radius:999px;background:#ffffff08;color:#a7b7c9;font-size:11px}.system-pill i{width:8px;height:8px;border-radius:50%;background:#f1b94f;box-shadow:0 0 12px #f1b94f}.system-pill.healthy i{background:#44dfa0;box-shadow:0 0 12px #44dfa0}main{width:min(1180px,calc(100% - 40px));margin:auto}.hero{min-height:560px;display:grid;grid-template-columns:1.1fr .9fr;align-items:center;gap:70px;padding:75px 0}.overline{margin:0;color:#5cb4ff;font-size:10px;font-weight:800;letter-spacing:.18em}.hero h1{margin:16px 0 22px;font-size:clamp(45px,6vw,74px);line-height:1.04;letter-spacing:-.045em}.hero h1 span{color:#55b6ff}.lead{max-width:640px;color:#9aadc3;font-size:17px;line-height:1.7}.actions{display:flex;gap:12px;margin-top:30px}.actions a,.metrics button{padding:13px 17px;border:0;border-radius:10px;background:#2879df;color:#fff;font-weight:700;font-size:13px;cursor:pointer}.actions .outline{border:1px solid #ffffff1d;background:#ffffff08}.code-window{overflow:hidden;border:1px solid #76b7ff2b;border-radius:18px;background:#081522dd;box-shadow:0 30px 70px #0008}.window-bar{display:flex;align-items:center;gap:6px;padding:14px 16px;border-bottom:1px solid #ffffff12;background:#0c1b2c}.window-bar i{width:9px;height:9px;border-radius:50%;background:#ff6c6c}.window-bar i:nth-child(2){background:#ffc65c}.window-bar i:nth-child(3){background:#45d392}.window-bar span{margin-left:8px;color:#7c91a9;font-family:monospace;font-size:10px}.code-window pre{margin:0;padding:27px;color:#bed5ec;font-size:12px;line-height:2}.success-line{padding:14px 27px;border-top:1px solid #ffffff10;color:#4fe1a0;font-size:11px}.health-panel{display:flex;align-items:center;justify-content:space-between;gap:30px;padding:27px 30px;border:1px solid #ffffff16;border-radius:18px;background:linear-gradient(110deg,#10283e,#0b1a29);box-shadow:0 18px 50px #0004}.health-panel h2{margin:8px 0 5px;font-size:23px}.health-panel small{color:#7f94ad}.metrics{display:flex;align-items:center;gap:11px}.metrics>div{min-width:125px;padding:12px 15px;border-radius:11px;background:#ffffff08}.metrics span,.metrics b{display:block}.metrics span{color:#7d91a9;font-size:10px}.metrics b{margin-top:5px;font-size:13px}.ok{color:#4fe0a1}.warn{color:#ffc65c}.section{padding-top:105px}.section-title{display:flex;justify-content:space-between;align-items:end;gap:40px;margin-bottom:35px}.section-title h2{margin:9px 0 0;font-size:clamp(30px,4vw,45px);letter-spacing:-.035em}.section-title>p{max-width:430px;margin:0;color:#859ab2;line-height:1.7}.diagram{display:flex;flex-direction:column;align-items:center;padding:36px;border:1px solid #ffffff16;border-radius:22px;background:linear-gradient(150deg,#0d1c2c,#091521);box-shadow:0 30px 70px #0005}.arch-box{position:relative;width:280px;padding:20px;border:1px solid #745ee7;border-radius:14px;background:#191a3a;text-align:center;box-shadow:0 15px 30px #0004}.arch-box strong,.arch-box small{display:block}.arch-box strong{font-size:17px}.arch-box small{margin-top:6px;color:#93a7bf;font-size:11px}.badge{position:absolute;top:8px;right:10px;color:#748aa6;font-size:8px;letter-spacing:.13em}.user{background:#171d39}.arrow{text-align:center;color:#5aaeff}.arrow span{display:block;color:#7e93aa;font-size:9px}.arrow b{font-size:26px}.vertical{height:69px;padding-top:8px}.network{position:relative;width:100%;padding:45px 35px 32px;border:1px dashed #3d759f;border-radius:19px;background:#0a2031;display:flex;flex-direction:column;align-items:center}.network-label{position:absolute;top:13px;left:17px;color:#5687ae;font-size:9px;letter-spacing:.14em}.nginx{width:430px;background:#261c4b}.split-arrows{width:70%;display:flex;justify-content:space-around;height:72px;padding-top:10px;color:#5c9bd2;font-size:28px}.split-arrows div{text-align:center}.split-arrows span{display:block;color:#8397ae;font-family:monospace;font-size:10px}.split{width:90%;display:grid;grid-template-columns:1fr 1fr;gap:18%;}.split .arch-box{width:100%}.react{border-color:#278bd9;background:#112b43}.django{border-color:#27a96c;background:#102d27}.backend-flow{margin-left:54%;}.bottom-row{width:90%;display:grid;grid-template-columns:1fr 1fr;gap:18%;align-items:start}.bottom-row .arch-box{width:100%}.postgres{border-color:#d89038;background:#322516}.external{position:relative}.optional{border-style:dashed;border-color:#65758a;background:#172332}.external>small{display:block;margin-top:7px;color:#6f8299;text-align:center;font-size:9px}.volume-line{margin-left:-54%;color:#5aaeff;font-size:24px}.volume{margin-left:-54%;display:flex;gap:12px;padding:11px 17px;border:1px solid #ffffff18;border-radius:10px;background:#162536;font-size:10px}.volume span{color:#69b8ff}.cards{display:grid;grid-template-columns:repeat(4,1fr);gap:14px}.cards article{display:flex;align-items:center;gap:13px;min-height:110px;padding:18px;border:1px solid #ffffff14;border-radius:16px;background:#0d1b2a}.cards em{display:grid;place-items:center;width:42px;height:42px;flex:0 0 auto;border-radius:12px;background:#247bba31;color:#68c2ff;font-style:normal;font-weight:800}.cards h3{margin:0;font-size:14px}.cards p{margin:5px 0 0;color:#778da5;font-size:10px}.cards article>span{margin-left:auto;color:#637a94;font-family:monospace;font-size:9px}.highlights{display:grid;grid-template-columns:repeat(3,1fr);gap:45px;margin:105px 0 85px;padding-top:38px;border-top:1px solid #ffffff14}.highlights b{color:#4f91cf;font-family:monospace}.highlights h3{margin:12px 0 9px}.highlights p{margin:0;color:#7d92aa;line-height:1.7}footer{width:min(1180px,calc(100% - 40px));margin:auto;display:flex;justify-content:space-between;padding:27px 0 38px;border-top:1px solid #ffffff13;color:#6e839a;font-size:11px}@media(max-width:900px){nav,.system-pill{display:none}.hero{grid-template-columns:1fr}.section-title{display:block}.section-title>p{margin-top:15px}.health-panel{align-items:flex-start;flex-direction:column}.metrics{flex-wrap:wrap}.cards{grid-template-columns:repeat(2,1fr)}.highlights{grid-template-columns:1fr}.nginx{width:80%}.split,.bottom-row{width:100%;gap:20px}.split-arrows{width:90%}}@media(max-width:600px){main,.navbar,footer{width:calc(100% - 24px)}.hero{padding-top:50px}.actions{flex-direction:column}.metrics>div{min-width:105px}.diagram{padding:15px}.network{padding:44px 12px 25px}.split,.bottom-row{grid-template-columns:1fr}.split-arrows{display:none}.backend-flow,.volume-line,.volume{margin-left:0}.cards{grid-template-columns:1fr}.arch-box,.nginx{width:100%}footer{gap:12px;flex-direction:column}}
'@

Write-Host "[2/6] Validating files..." -ForegroundColor Yellow
if ((Get-Content "frontend/index.html" -Raw) -notmatch '/src/main.jsx') { throw "index.html is invalid." }
Run-Native { docker compose config --quiet } "docker-compose.yml is invalid."

Write-Host "[3/6] Rebuilding frontend..." -ForegroundColor Yellow
Run-Native { docker compose build --no-cache frontend } "Frontend image build failed."
Run-Native { docker compose up -d --force-recreate frontend nginx } "Container recreation failed."
Start-Sleep -Seconds 8

Write-Host "[4/6] Checking frontend logs and API..." -ForegroundColor Yellow
$Logs = docker compose logs frontend --tail=80
if ($LASTEXITCODE -ne 0) { throw "Unable to read frontend logs." }
$Logs | Write-Host
if ($Logs -match "error during build|Failed to resolve|SyntaxError") { throw "Frontend log contains a JavaScript error." }
$Health = Invoke-RestMethod -Uri "http://localhost/api/health/" -TimeoutSec 10
if ($Health.status -ne "ok" -or $Health.database -ne "connected") { throw "Health API failed." }
$HomepageResponse = Invoke-WebRequest -Uri "http://localhost/" -UseBasicParsing -TimeoutSec 10
if ($HomepageResponse.StatusCode -ne 200) { throw "Homepage HTTP test failed." }
docker compose ps

Write-Host "[5/6] Committing and pushing..." -ForegroundColor Yellow
Run-Native { git add frontend/index.html frontend/src/main.jsx frontend/src/App.jsx frontend/src/style.css } "git add failed."
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
  Run-Native { git commit -m "Add system architecture dashboard to frontend" } "git commit failed."
  Run-Native { git push origin main } "git push failed."
}

Write-Host "[6/6] Opening dashboard..." -ForegroundColor Yellow
Write-Host ""
Write-Host "====================================================" -ForegroundColor Green
Write-Host " ARCHITECTURE DASHBOARD INSTALLED SUCCESSFULLY" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green
Write-Host "Frontend: http://localhost/" -ForegroundColor Cyan
Write-Host "API:      http://localhost/api/health/" -ForegroundColor Cyan
Start-Process "http://localhost/?v=architecture-dashboard"

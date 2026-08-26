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

function Run-Command {
    param([Parameter(Mandatory = $true)][scriptblock]$Command, [string]$ErrorMessage)
    & $Command
    if ($LASTEXITCODE -ne 0) { throw $ErrorMessage }
}

function Wait-ForHealth {
    param([string]$Url = "http://localhost/api/health/", [int]$Attempts = 24)
    for ($i = 1; $i -le $Attempts; $i++) {
        try {
            $response = Invoke-RestMethod -Uri $Url -Method Get -TimeoutSec 5
            if ($response.status -eq "ok" -and $response.database -eq "connected") {
                return $response
            }
        } catch {
            Write-Host "Waiting for API ($i/$Attempts)..." -ForegroundColor DarkYellow
        }
        Start-Sleep -Seconds 5
    }
    return $null
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " Finalize Infrastructure Qualification Project" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path (Join-Path $ProjectRoot "docker-compose.yml"))) {
    throw "Run this script from the project root containing docker-compose.yml."
}
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { throw "Docker was not found." }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw "Git was not found." }

Write-Host "[1/9] Writing final project files..." -ForegroundColor Yellow

Write-Utf8File ".gitignore" @'
# Local environment and secrets
.env

# Python
__pycache__/
*.py[cod]
*.sqlite3
backend/staticfiles/

# Node.js
node_modules/
frontend/node_modules/
frontend/dist/
frontend/build/

# VS Code
.vscode/

# Operating system
.DS_Store
Thumbs.db

# Logs
*.log
'@

Write-Utf8File "frontend/index.html" @'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="description" content="Infrastructure qualification test application" />
    <title>Infrastructure Qualification Test</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
'@

$Mermaid = @'
flowchart LR
    User["User / Web Browser"]

    subgraph DockerHost["Docker Host"]
        subgraph AppNetwork["Docker Bridge Network: app_network"]
            Nginx["Nginx Reverse Proxy<br/>Port 80"]
            Frontend["React.js Frontend<br/>Vite Port 5173"]
            Backend["Django 4.2 Backend<br/>Gunicorn Port 8000"]
            Database[("PostgreSQL 15.2<br/>Port 5432")]
        end
        Volume[("Docker Named Volume<br/>postgres_data")]
    end

    User -->|"HTTP Port 80"| Nginx
    Nginx -->|"Route /"| Frontend
    Nginx -->|"Route /api/*"| Backend
    Nginx -->|"Route /admin/*"| Backend
    Frontend -.->|"API /api/health/"| Nginx
    Backend -->|"TCP 5432"| Database
    Database -->|"Persistent data"| Volume
'@
Write-Utf8File "docs/system-architecture.mmd" $Mermaid

$DiagramMd = @"
# System Architecture Diagram

``````mermaid
$Mermaid
``````

## Data Flow

1. The browser connects to Nginx on host port 80.
2. Nginx routes `/` to React and `/api/*` or `/admin/*` to Django.
3. Django connects to PostgreSQL through the internal Docker bridge network.
4. PostgreSQL stores persistent data in the `postgres_data` named volume.
5. No external API is required by this demonstration.
"@
Write-Utf8File "docs/system-architecture.md" $DiagramMd

$Readme = @'
# Infrastructure Qualification Test

A multi-container web application environment featuring PostgreSQL 15.2, Django 4.2, React.js, Gunicorn, and Nginx.

## Technology Stack

- PostgreSQL 15.2
- Django 4.2 with Gunicorn
- React.js 18 with Vite
- Nginx reverse proxy
- Docker and Docker Compose

## System Architecture

```mermaid
flowchart LR
    User["User / Web Browser"]
    subgraph DockerHost["Docker Host"]
        subgraph AppNetwork["Docker Bridge Network: app_network"]
            Nginx["Nginx Reverse Proxy<br/>Port 80"]
            Frontend["React.js Frontend<br/>Vite Port 5173"]
            Backend["Django 4.2 Backend<br/>Gunicorn Port 8000"]
            Database[("PostgreSQL 15.2<br/>Port 5432")]
        end
        Volume[("Docker Named Volume<br/>postgres_data")]
    end
    User -->|"HTTP Port 80"| Nginx
    Nginx -->|"Route /"| Frontend
    Nginx -->|"Route /api/*"| Backend
    Nginx -->|"Route /admin/*"| Backend
    Frontend -.->|"API /api/health/"| Nginx
    Backend -->|"TCP 5432"| Database
    Database -->|"Persistent data"| Volume
```

Diagram source files are available in `docs/system-architecture.md` and `docs/system-architecture.mmd`.

## Architecture Explanation

- **Nginx** is the only service exposed to the host. It listens on port 80.
- Requests to `/` are routed to the React frontend.
- Requests to `/api/*` and `/admin/*` are routed to the Django backend.
- **Django** runs with Gunicorn on internal port 8000.
- **PostgreSQL** is reachable only through the Docker network on port 5432.
- PostgreSQL data persists in the `postgres_data` named volume.
- All services communicate through the `app_network` Docker bridge network.
- The demonstration does not require an external API. Future external integrations should be handled by Django.

## Request Flow

```text
Browser -> Nginx -> React
React -> Nginx -> Django -> PostgreSQL
```

## Project Structure

```text
.
â”œâ”€â”€ backend/
â”‚   â”œâ”€â”€ app/
â”‚   â”œâ”€â”€ config/
â”‚   â”œâ”€â”€ Dockerfile
â”‚   â”œâ”€â”€ entrypoint.sh
â”‚   â”œâ”€â”€ manage.py
â”‚   â””â”€â”€ requirements.txt
â”œâ”€â”€ frontend/
â”‚   â”œâ”€â”€ src/
â”‚   â”œâ”€â”€ Dockerfile
â”‚   â”œâ”€â”€ index.html
â”‚   â””â”€â”€ package.json
â”œâ”€â”€ nginx/
â”‚   â””â”€â”€ nginx.conf
â”œâ”€â”€ docs/
â”‚   â”œâ”€â”€ system-architecture.md
â”‚   â””â”€â”€ system-architecture.mmd
â”œâ”€â”€ .env.example
â”œâ”€â”€ .gitignore
â”œâ”€â”€ docker-compose.yml
â””â”€â”€ README.md
```

## Prerequisites

- Git
- Docker Desktop
- Docker Compose

Verify the tools:

```bash
docker --version
docker compose version
git --version
```

Docker Desktop must be running before starting the environment.

## Build and Run

Clone the public repository:

```bash
git clone https://github.com/traisitvare/infrastructure-qualification-test.git
cd infrastructure-qualification-test
```

Create the local environment file.

Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

Linux or macOS:

```bash
cp .env.example .env
```

Build and start all services:

```bash
docker compose up -d --build
```

## Verify the Environment

```bash
docker compose ps
```

Expected services:

```text
db          Up (healthy)
backend     Up
frontend    Up
nginx       Up
```

Application URLs:

- Frontend: `http://localhost/`
- Health API: `http://localhost/api/health/`
- Django Admin: `http://localhost/admin/`

Test the API using PowerShell:

```powershell
Invoke-RestMethod -Uri "http://localhost/api/health/"
```

Or curl:

```bash
curl http://localhost/api/health/
```

Expected response:

```json
{
  "status": "ok",
  "database": "connected"
}
```

## Logs

```bash
docker compose logs --tail=100
docker compose logs backend
docker compose logs frontend
docker compose logs nginx
docker compose logs db
```

Follow logs continuously:

```bash
docker compose logs -f
```

## Stop and Restart

Stop containers while retaining database data:

```bash
docker compose down
```

Restart:

```bash
docker compose up -d
```

Rebuild after code or dependency changes:

```bash
docker compose up -d --build
```

Reset the database and delete persistent data:

```bash
docker compose down -v
```

Warning: `docker compose down -v` permanently removes the PostgreSQL volume.

## Troubleshooting

### Port 80 is already in use

Check port 80 on Windows:

```powershell
Get-NetTCPConnection -LocalPort 80
```

Alternatively, change the Nginx mapping to `8080:80` and access `http://localhost:8080/`.

### Backend is restarting

```bash
docker compose logs backend --tail=100
```

### Nginx returns 502 Bad Gateway

```bash
docker compose ps
docker compose logs nginx --tail=100
docker compose logs backend --tail=100
```

### Database is unhealthy

```bash
docker compose logs db --tail=100
```

## Security and Design Considerations

- Only Nginx port 80 is published to the host.
- PostgreSQL, Django, and React ports remain internal.
- Secrets are supplied through a local `.env` file that is excluded from Git.
- Django runs with Gunicorn and a non-root container user.
- PostgreSQL uses a health check and persistent named volume.
- The backend waits for PostgreSQL to become healthy.
- Images and dependencies use explicit versions.
- Nginx forwards standard reverse-proxy headers.

## Author

Traisit Wareeratpakron  
IT Infrastructure Developer Qualification Test
'@
Write-Utf8File "README.md" $Readme

# Remove temporary recovery scripts that are not part of the submission.
foreach ($TemporaryScript in @("setup-project.ps1", "repair-project.ps1")) {
    $TemporaryPath = Join-Path $ProjectRoot $TemporaryScript
    if (Test-Path $TemporaryPath) {
        Remove-Item $TemporaryPath -Force
        Write-Host "[OK] Removed temporary file: $TemporaryScript" -ForegroundColor Green
    }
}

Write-Host "[2/9] Validating environment and Git safety..." -ForegroundColor Yellow
if (-not (Test-Path ".env")) { Copy-Item ".env.example" ".env" }
$Ignored = git check-ignore .env
if ($LASTEXITCODE -ne 0 -or -not $Ignored) { throw ".env is not ignored. Stop before committing secrets." }
Run-Command { docker compose config --quiet } "Docker Compose configuration is invalid."

Write-Host "[3/9] Rebuilding and testing the current project..." -ForegroundColor Yellow
Run-Command { docker compose down --remove-orphans } "Unable to stop current containers."
Run-Command { docker compose up -d --build } "Current project build failed."
$CurrentHealth = Wait-ForHealth
if ($null -eq $CurrentHealth) {
    docker compose ps
    docker compose logs --tail=150
    throw "Current project health test failed."
}
docker compose ps
Write-Host "[OK] Current environment health check passed." -ForegroundColor Green

Write-Host "[4/9] Staging project files..." -ForegroundColor Yellow
Run-Command { git add . } "git add failed."
$TrackedEnv = git ls-files .env
if ($TrackedEnv) { throw ".env is tracked by Git. Remove it before continuing." }

git diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host "[INFO] No new changes to commit." -ForegroundColor DarkYellow
} else {
    Run-Command { git commit -m "Complete architecture documentation and deployment validation" } "git commit failed."
}

Write-Host "[5/9] Pushing to GitHub..." -ForegroundColor Yellow
Run-Command { git push origin main } "git push failed."

Write-Host "[6/9] Preparing clean clone test..." -ForegroundColor Yellow
Run-Command { docker compose down --remove-orphans } "Unable to stop current environment before clean test."
$Parent = Split-Path $ProjectRoot -Parent
$CleanPath = Join-Path $Parent "infrastructure-clean-test"
if (Test-Path $CleanPath) { Remove-Item $CleanPath -Recurse -Force }
Run-Command { git clone "https://github.com/traisitvare/infrastructure-qualification-test.git" $CleanPath } "Clean clone failed."
Copy-Item (Join-Path $CleanPath ".env.example") (Join-Path $CleanPath ".env")

Write-Host "[7/9] Building the clean clone..." -ForegroundColor Yellow
Push-Location $CleanPath
try {
    Run-Command { docker compose config --quiet } "Clean clone Compose validation failed."
    Run-Command { docker compose up -d --build } "Clean clone build failed."
    $CleanHealth = Wait-ForHealth
    if ($null -eq $CleanHealth) {
        docker compose ps
        docker compose logs --tail=150
        throw "Clean clone health test failed."
    }
    docker compose ps
    Write-Host "[OK] Clean clone test passed." -ForegroundColor Green
    Run-Command { docker compose down -v --remove-orphans } "Unable to clean the test environment."
} finally {
    Pop-Location
}

Write-Host "[8/9] Removing clean test directory..." -ForegroundColor Yellow
if (Test-Path $CleanPath) { Remove-Item $CleanPath -Recurse -Force }

Write-Host "[9/9] Restarting the original project..." -ForegroundColor Yellow
Set-Location $ProjectRoot
Run-Command { docker compose up -d } "Unable to restart original project."
$FinalHealth = Wait-ForHealth
if ($null -eq $FinalHealth) { throw "Original project did not recover after clean testing." }

docker compose ps
Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host " FINALIZATION COMPLETED SUCCESSFULLY" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host "Repository: https://github.com/traisitvare/infrastructure-qualification-test" -ForegroundColor Cyan
Write-Host "Frontend:   http://localhost/" -ForegroundColor Cyan
Write-Host "Health API: http://localhost/api/health/" -ForegroundColor Cyan
Write-Host ""
Write-Host "The README, Mermaid architecture diagram, clean clone test, commit, and push are complete." -ForegroundColor Green
Start-Process "http://localhost/"
Start-Process "https://github.com/traisitvare/infrastructure-qualification-test"

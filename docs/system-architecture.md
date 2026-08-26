# System Architecture Diagram

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
    Frontend -.->|"Auth + API /api/*"| Nginx
    Backend -->|"TCP 5432"| Database
    Database -->|"Persistent data"| Volume
```

## Data Flow

1. The browser connects to Nginx on host port 80.
2. Nginx routes / to React and /api/* or /admin/* to Django.
3. Django connects to PostgreSQL through the internal Docker bridge network.
4. PostgreSQL stores persistent data in the postgres_data named volume.
5. Django's authentication endpoints store registered users in PostgreSQL's `auth_user` table with hashed passwords.
6. No external API is required by this demonstration.

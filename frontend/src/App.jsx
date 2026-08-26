import { useEffect, useState } from "react";

function App() {
  const [health, setHealth] = useState(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch("/api/health/")
      .then((response) => {
        if (!response.ok) {
          throw new Error(
            `API returned status ${response.status}`
          );
        }

        return response.json();
      })
      .then((data) => {
        setHealth(data);
        setError("");
      })
      .catch((requestError) => {
        setError(requestError.message);
      })
      .finally(() => {
        setLoading(false);
      });
  }, []);

  return (
    <main className="page">
      <section className="card">
        <p className="label">
          DIGITAL STOREMESH QUALIFICATION TEST
        </p>

        <h1>Docker Web Application</h1>

        <p className="description">
          PostgreSQL, Django, React.js and Nginx
          are running as separate Docker containers.
        </p>

        {loading && (
          <div className="status loading">
            Checking application status...
          </div>
        )}

        {health && (
          <div className="status success">
            <h2>System Status</h2>
            <p>
              Backend: <strong>{health.status}</strong>
            </p>
            <p>
              Database:{" "}
              <strong>{health.database}</strong>
            </p>
          </div>
        )}

        {error && (
          <div className="status failure">
            <h2>System Unavailable</h2>
            <p>{error}</p>
          </div>
        )}

        <div className="services">
          <span>React.js</span>
          <span>Nginx</span>
          <span>Django 4.2</span>
          <span>PostgreSQL 15.2</span>
        </div>
      </section>
    </main>
  );
}

export default App;
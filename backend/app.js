// import express from "express";
// import cors from "cors";  
// import dotenv from "dotenv";
// dotenv.config();

// const app = express();
// const PORT = process.env.PORT || 3000;
// const ENV = process.env.ENVIRONMENT || "dev";

// app.get("/", (req, res) => {
//   res.json({
//     message: `🚀 Delphi POC running in ${ENV.toUpperCase()} environment.`,
//   });
// });

// app.listen(PORT, () => {
//   console.log(`Server running on port ${PORT} in ${ENV} environment`);
//   console.log("Hello World");
// });

// backend/app.js
import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import path from "path";
import { fileURLToPath } from "url";
dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
const ENV = (process.env.ENVIRONMENT || "dev").toLowerCase();

// existing API/root endpoint - keep as-is
app.get("/api/ping", (req, res) => {
  res.json({
    message: `🚀 Delphi POC running in ${ENV.toUpperCase()} environment.`,
  });
});

/*
  Serve React frontend when in QA/test environment.
  - The frontend build (npm run build) should be copied to backend/public
  - When ENV === 'qa' (or SERVE_FRONTEND=true) we serve static files from backend/public
*/
const serveFrontend = (ENV === "qa" || process.env.SERVE_FRONTEND === "true");

if (serveFrontend) {
  const publicDir = path.join(__dirname, "public");
  app.use(express.static(publicDir));

  // all other routes -> serve index.html (React Router friendly)
  app.get("*", (req, res) => {
    res.sendFile(path.join(publicDir, "index.html"));
  });

  console.log("✅ Static frontend serving enabled from:", publicDir);
}

// Start server in all environments (you wanted server to start in test env)
// If you still plan to run in-memory tests in CI, you can guard start on NODE_ENV !== 'test'
if (process.env.NODE_ENV !== "test") {
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT} in ${ENV} environment`);
  });
}

export default app;

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

// app.js
import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import path from "path";
import { fileURLToPath } from "url";

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3000;
const ENV = (process.env.ENVIRONMENT || "dev").toLowerCase();

// Middleware
app.use(cors());
app.use(express.json());

// Serve static files from project root (or adjust to 'frontend'/'public' if you move index.html)
app.use(express.static(path.join(__dirname)));

// Root route - health + send index.html
app.get("/", (req, res) => {
  // If you want JSON health for programmatic checks:
  if (req.get("Accept") && req.get("Accept").includes("application/json")) {
    return res.json({ message: `🚀 Delphi POC running in ${ENV.toUpperCase()} environment.` });
  }

  // Otherwise serve the frontend
  return res.sendFile(path.join(__dirname, "index.html"));
});

// Lightweight health endpoint optionally
app.get("/health", (req, res) => {
  res.json({ status: "ok", environment: ENV });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT} in ${ENV} environment`);
});

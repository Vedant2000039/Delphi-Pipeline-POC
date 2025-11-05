// backend/app.js
import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import process from "process";
import path from "path";
import fs from "fs";

// load .env from current working dir (backend/.env)
const ENV_PATH = path.resolve(process.cwd(), ".env");

if (!fs.existsSync(ENV_PATH)) {
  console.warn(`⚠️ .env not found at ${ENV_PATH} — continuing with process.env/defaults`);
} else {
  const result = dotenv.config({ path: ENV_PATH });
  if (result.error) {
    console.error(`❌ Failed to parse ${ENV_PATH}:`, result.error);
    process.exit(1);
  }
}

const PORT = process.env.PORT || 3000;
const ENVIRONMENT = process.env.ENVIRONMENT || process.env.NODE_ENV || "dev";

const app = express();
app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
  res.json({
    message: `Delphi POC running in ${ENVIRONMENT.toUpperCase()} environment.`,
    port: PORT,
  });
});

// Use try/catch style handler to log errors (pm2 will show logs)
const server = app.listen(PORT, () => {
  console.log(`✅ Server running on port ${PORT} in ${ENVIRONMENT} environment`);
});

server.on("error", (err) => {
  if (err.code === "EADDRINUSE") {
    console.error(`❌ Port ${PORT} is already in use. Please stop other processes or change PORT.`);
    process.exit(1);
  } else {
    console.error("❌ Server error:", err);
    process.exit(1);
  }
});

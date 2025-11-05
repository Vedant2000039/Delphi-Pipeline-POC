import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import process from "process";
import fs from "fs";
import path from "path";

// -------------------------
// 1️⃣ Load Environment File
// -------------------------
const NODE_ENV = process.env.NODE_ENV || "dev"; // default to dev
const ENV_PATH = path.resolve(process.cwd(), `environments/${NODE_ENV}.env`);

// Check if env file exists
if (!fs.existsSync(ENV_PATH)) {
  console.error(`❌ Environment file not found: ${ENV_PATH}`);
  process.exit(1);
}

// Load the env file
const result = dotenv.config({ path: ENV_PATH });
if (result.error) {
  console.error(`❌ Failed to load environment file: ${ENV_PATH}`);
  process.exit(1);
}

// -------------------------
// 2️⃣ Read Config Values
// -------------------------
const PORT = process.env.PORT || 3000;
const ENVIRONMENT = process.env.ENVIRONMENT || NODE_ENV;

// -------------------------
// 3️⃣ Initialize Express
// -------------------------
const app = express();
app.use(cors());
app.use(express.json()); // for parsing JSON requests

// -------------------------
// 4️⃣ Sample Route
// -------------------------
app.get("/", (req, res) => {
  res.json({
    message: `Delphi POC running in ${ENVIRONMENT.toUpperCase()} environment.`,
    port: PORT,
  });
});

// -------------------------
// 5️⃣ Start Server with Port Conflict Handling
// -------------------------
app.listen(PORT, () => {
  console.log(`✅ Server running on port ${PORT} in ${ENVIRONMENT} environment`);
});

// Handle uncaught errors like EADDRINUSE
app.on("error", (err) => {
  if (err.code === "EADDRINUSE") {
    console.error(`❌ Port ${PORT} is already in use. Please stop other processes or change PORT.`);
    process.exit(1);
  } else {
    console.error("❌ Server error:", err);
  }
});

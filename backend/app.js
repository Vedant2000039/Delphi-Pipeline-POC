// ================================================
// app.js — Delphi POC Backend Entry Point
// Supports multi-environment deployment (dev/qa/uat/prod)
// ================================================

import express from "express";
import dotenv from "dotenv";
import fs from "fs";
import path from "path";
import cors from "cors";

// --------------------------------------------------
// 1️⃣ Load Environment Configuration
// --------------------------------------------------
const __dirname = path.resolve();
const ENVIRONMENT = process.env.ENVIRONMENT || "dev";
const envFilePath = path.join(__dirname, "../environments", `${ENVIRONMENT}.env`);

if (fs.existsSync(envFilePath)) {
  dotenv.config({ path: envFilePath });
  console.log(`✅ Loaded environment file: ${envFilePath}`);
} else if (fs.existsSync(path.join(__dirname, ".env"))) {
  dotenv.config({ path: path.join(__dirname, ".env") });
  console.log("⚠️ Loaded fallback .env from backend root");
} else {
  console.error(`❌ Environment file not found for ${ENVIRONMENT}`);
  process.exit(1);
}

// --------------------------------------------------
// 2️⃣ Initialize Express App
// --------------------------------------------------
const app = express();
app.use(cors());
app.use(express.json());

// --------------------------------------------------
// 3️⃣ Basic Health Check Endpoint
// --------------------------------------------------
app.get("/", (req, res) => {
  res.status(200).send(`✅ ${ENVIRONMENT.toUpperCase()} server is running on port ${process.env.PORT}`);
});

// --------------------------------------------------
// 4️⃣ Add Other Routes (if any)
// --------------------------------------------------
// Example:
// import userRoutes from "./routes/userRoutes.js";
// app.use("/api/users", userRoutes);

// --------------------------------------------------
// 5️⃣ Start Server on Correct Interface
// --------------------------------------------------
const PORT = process.env.PORT || 5000;
const HOST = "0.0.0.0"; // Required for Docker/NGROK/remote access

const server = app.listen(PORT, HOST, () => {
  console.log(`🚀 Server running on http://${HOST}:${PORT} in ${ENVIRONMENT} environment`);
});

// --------------------------------------------------
// 6️⃣ Graceful Shutdown Handling
// --------------------------------------------------
process.on("SIGTERM", () => {
  console.log("🛑 SIGTERM received. Closing server...");
  server.close(() => {
    console.log("✅ Server closed gracefully.");
    process.exit(0);
  });
});

import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import process from "process";

// -------------------------
// 1️⃣ Load Environment File
// -------------------------
const NODE_ENV = process.env.NODE_ENV || "dev"; // default to dev
const ENV_PATH = `environments/${NODE_ENV}.env`;

// Load the env file
const result = dotenv.config({ path: ENV_PATH });

if (result.error) {
  console.error(`Failed to load environment file: ${ENV_PATH}`);
  process.exit(1);
}

// -------------------------
// 2️⃣ Read Config Values
// -------------------------
const PORT = process.env.PORT;
const ENVIRONMENT = process.env.ENVIRONMENT || NODE_ENV;

// Fail fast if PORT is not set
if (!PORT) {
  console.error(
    `PORT is not defined in ${ENV_PATH}. Please set PORT in your env file.`
  );
  process.exit(1);
}

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
// 5️⃣ Start Server
// -------------------------
const server = app.listen(PORT, "0.0.0.0", () => {
  console.log(`✅ Server running on port ${PORT} in ${ENVIRONMENT} environment`);
});

export default server;

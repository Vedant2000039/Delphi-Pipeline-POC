import express from "express";
import dotenv from "dotenv";
import path from "path";
import { fileURLToPath } from "url";

// ✅ Resolve __dirname in ES module
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ✅ Determine environment file dynamically
const envPath = path.resolve(__dirname, ".env");

// ✅ Load the environment file that Jenkins copied (e.g. uat.env → .env)
const result = dotenv.config({ path: envPath });
if (result.error) {
  console.error(`❌ Failed to load environment file: ${envPath}`);
} else {
  console.log(`✅ Environment file loaded successfully: ${envPath}`);
}

const app = express();
app.use(express.json());

// ✅ Simple test route to verify API works
app.get("/", (req, res) => {
  res.status(200).send({
    message: "Delphi POC backend is running",
    environment: process.env.ENVIRONMENT || "unknown",
  });
});

// ✅ Port and environment handling
const PORT = process.env.PORT || 5000;
const ENVIRONMENT = process.env.ENVIRONMENT || "dev";

app.listen(PORT, '0.0.0.0', () => {
  console.log(` Server running on port ${PORT} [${ENVIRONMENT}]`);
});


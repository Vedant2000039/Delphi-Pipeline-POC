// backend/app.js
import express from "express";
import dotenv from "dotenv";
import path from "path";
import { fileURLToPath } from "url";

// Resolve __dirname in ES module
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load env file (Jenkins copies environments/<env>.env → backend/.env)
const envPath = path.resolve(__dirname, ".env");
const result = dotenv.config({ path: envPath });
if (result.error) {
  console.error(`❌ Failed to load environment file: ${envPath}`);
} else {
  console.log(`✅ Environment file loaded successfully: ${envPath}`);
}

const app = express();
app.use(express.json());

// Root endpoint: return a plain-text line that includes the exact phrase
// "Delphi POC running" (so existing grep tests will match), and include JSON too.
app.get("/", (req, res) => {
  const environment = process.env.ENVIRONMENT || "unknown";
  const textBody = `Delphi POC running — environment: ${environment}`;
  // Respond with JSON that also contains the exact phrase in the message field
  res.status(200).json({
    message: "Delphi POC running",
    details: "backend is healthy",
    environment
  });
  // NOTE: curl will receive JSON; grep will still find "Delphi POC running" in body.
});

// Port and environment handling
const PORT = process.env.PORT || 5000;
const ENVIRONMENT = process.env.ENVIRONMENT || "dev";

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on port ${PORT} [${ENVIRONMENT}]`);
  console.log(`Root URL: http://localhost:${PORT}`);
});

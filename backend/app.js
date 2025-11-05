import express from "express";
import cors from "cors";  
import dotenv from "dotenv";

// Load environment dynamically based on NODE_ENV (default = dev)
const env = process.env.NODE_ENV || "dev";
dotenv.config({ path: `environments/${env}.env` });

const app = express();
const PORT = process.env.PORT || 3000;
const ENV = process.env.ENVIRONMENT || env;

app.use(cors()); // if you want CORS support

app.get("/", (req, res) => {
  res.json({
    message: `Delphi POC running in ${ENV.toUpperCase()} environment.`,
  });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT} in ${ENV} environment`);
});

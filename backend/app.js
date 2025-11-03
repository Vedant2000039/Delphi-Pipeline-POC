import express from "express";
import dotenv from "dotenv";
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;
const ENV = process.env.ENVIRONMENT || "dev";

app.get("/", (req, res) => {
  res.json({
    message: `delphi POC running in ${ENV.toUpperCase()} env.`,
  });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT} in ${ENV} environment`);
});


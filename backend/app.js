import express from "express";
import cors from "cors";  
import dotenv from "dotenv";
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;
const ENV = process.env.ENVIRONMENT || "dev";

app.get("/", (req, res) => {
  res.json({
    message: `🚀 Delphi POC running in ${ENV.toUpperCase()} environment.`,
  });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT} in ${ENV} environment`);
  console.log("Hello World");
});


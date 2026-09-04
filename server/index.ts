import express from "express";
import { createServer } from "http";
import path from "path";
import { fileURLToPath } from "url";

// Garante um valor padrão sem depender de sintaxe de shell (ex: `NODE_ENV=production node ...`),
// que não funciona no Windows sem uma ferramenta como cross-env.
process.env.NODE_ENV = process.env.NODE_ENV || "production";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function startServer() {
  const app = express();
  const server = createServer(app);

  // Serve static files from dist/public in production
  const staticPath =
    process.env.NODE_ENV === "production"
      ? path.resolve(__dirname, "public")
      : path.resolve(__dirname, "..", "dist", "public");

  app.use(express.static(staticPath));

  // Handle client-side routing - serve index.html apenas para navegação de páginas,
  // nunca para chamadas de API ou assets ausentes (evita mascarar 404s reais com HTML).
  app.get("*", (req, res, next) => {
    if (req.path.startsWith("/api/") || path.extname(req.path)) {
      next();
      return;
    }
    res.sendFile(path.join(staticPath, "index.html"));
  });

  const port = process.env.PORT || 3000;

  server.listen(port, () => {
    console.log(`Server running on http://localhost:${port}/`);
  });
}

startServer().catch(console.error);

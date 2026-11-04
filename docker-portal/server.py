#!/usr/bin/env python3
"""
Servidor Web & API em Tempo Real do Portal Docker Swarm (Defesa em Foco)
Porta padrão: 8090 (exposto via Cloudflare Tunnel em https://docker.rhprogramer.com.br)
Protegido por senha (padrão: 1207) com sessão via Cookie HttpOnly + suporte a Basic Auth.
"""
import base64
import hashlib
import hmac
import http.cookies
import json
import mimetypes
import os
import subprocess
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

PORT = int(os.environ.get("DOCKER_PORTAL_PORT", "8090"))
PASSWORD = os.environ.get("DOCKER_PORTAL_PASSWORD", "1207")
SECRET = hashlib.sha256(f"defesa-swarm-{PASSWORD}".encode()).hexdigest()
BASE_DIR = Path(__file__).resolve().parent
VISUALIZER_UPSTREAM = "http://127.0.0.1:8081"

ENV = os.environ.copy()
ENV["PATH"] = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:" + ENV.get("PATH", "")

LOGIN_HTML = """<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Acesso Restrito · Defesa em Foco Docker Swarm</title>
  <link rel="stylesheet" href="/app.css">
  <style>
    .login-shell {
      min-height: 100svh;
      display: grid;
      place-items: center;
      padding: 24px;
      background: var(--ground);
    }
    .login-card {
      width: 100%;
      max-width: 400px;
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 6px;
      padding: 28px 24px;
    }
    .login-badge {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      margin-bottom: 14px;
    }
    .login-input {
      width: 100%;
      height: 38px;
      padding: 0 12px;
      border: 1px solid var(--control);
      border-radius: 6px;
      background: var(--ground);
      color: var(--text);
      margin-top: 6px;
    }
    .login-error {
      margin-top: 10px;
      padding: 8px 10px;
      border-radius: 4px;
      background: var(--pill-negative-bg);
      color: var(--pill-negative-ink);
      font-size: 12px;
    }
  </style>
</head>
<body>
  <main class="login-shell">
    <section class="login-card" data-ui>
      <div class="login-badge">
        <div class="brand-mark mono" data-ui style="margin:0;">DF</div>
        <div>
          <div style="font-weight:600;font-size:14px;">Defesa em Foco · Cluster Swarm</div>
          <div class="mono" style="font-size:11px;color:var(--muted);">mac-mini-de-reinaldo · Docker 28.0.4</div>
        </div>
      </div>
      <h1 style="font-size:20px;font-weight:600;margin-bottom:6px;">Console de Orquestração</h1>
      <p style="color:var(--muted);font-size:13px;margin-bottom:18px;">
        Insira a credencial de apresentação para acessar as métricas do cluster, variação de réplicas ao vivo e o Docker Visualizer.
      </p>
      __ERROR_BLOCK__
      <form method="POST" action="/auth/login" style="display:grid;gap:14px;margin-top:12px;">
        <div>
          <label for="password" style="font-size:12px;color:var(--muted);font-weight:500;">Senha de Acesso</label>
          <input id="password" name="password" type="password" class="login-input mono" placeholder="••••" required autofocus>
        </div>
        <button type="submit" class="btn primary" data-ui style="width:100%;height:38px;border-radius:6px;">
          Acessar Cluster Docker Swarm
        </button>
      </form>
      <div style="margin-top:16px;padding-top:12px;border-top:1px solid var(--rule);display:flex;justify-content:space-between;font-size:11px;color:var(--muted);" class="mono">
        <span>Cloudflare Zero Trust</span>
        <span>Swarm TLS Ativo</span>
      </div>
    </section>
  </main>
</body>
</html>
"""


def run_cmd(cmd, timeout=15):
    try:
        res = subprocess.run(
            cmd,
            shell=True,
            capture_output=True,
            text=True,
            timeout=timeout,
            env=ENV,
        )
        return res.stdout.strip()
    except Exception:
        return ""


def get_swarm_status():
    raw = run_cmd(
        "docker ps --format '{{.Names}}|{{.ID}}|{{.Image}}|{{.Ports}}|{{.Status}}'"
    )
    containers = []
    backend_count = 0
    frontend_count = 0

    for line in raw.splitlines():
        parts = line.split("|")
        if len(parts) < 5:
            continue
        full_name, cid, image, ports, status = parts[:5]
        # Swarm container names look like: defesacivil_backend.1.xyz123...
        task_parts = full_name.split(".")
        if len(task_parts) >= 2:
            task = f"{task_parts[0]}.{task_parts[1]}"
        else:
            task = full_name

        svc = "other"
        for candidate in ["backend", "frontend", "nginx-lb", "db", "visualizer"]:
            if f"defesacivil_{candidate}" in full_name:
                svc = candidate
                break

        if svc == "backend":
            backend_count += 1
        elif svc == "frontend":
            frontend_count += 1

        short_ports = ports if ports else "8080/tcp (overlay)"
        if "8000->80" in short_ports:
            short_ports = "0.0.0.0:8000->80, :8080->8080"
        elif "8081->8080" in short_ports:
            short_ports = "0.0.0.0:8081->8080"
        elif svc == "db":
            short_ports = "5432/tcp (PostGIS)"
        elif svc == "frontend":
            short_ports = "80/tcp (overlay)"

        containers.append(
            {
                "task": task,
                "id": cid[:12],
                "image": image,
                "node": "colima",
                "ports": short_ports,
                "status": "Running" if "Up" in status else status,
                "age": status.replace("Up ", "Ativo · ").split(" (")[0],
                "service": svc,
            }
        )

    containers.sort(key=lambda x: x["task"])

    df_out = run_cmd("df -h /System/Volumes/Data | tail -1")
    disk_free = "23,0 GB"
    if df_out:
        cols = df_out.split()
        if len(cols) >= 4:
            disk_free = cols[3].replace("Gi", " GB")

    return {
        "ok": True,
        "backendReplicas": backend_count or 3,
        "frontendReplicas": frontend_count or 2,
        "diskFree": disk_free,
        "containers": containers,
    }


class PortalHandler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        pass

    def is_authenticated(self):
        # 1. Check Cookie
        cookie_hdr = self.headers.get("Cookie", "")
        if cookie_hdr:
            c = http.cookies.SimpleCookie()
            try:
                c.load(cookie_hdr)
                if "defesa_swarm_token" in c and hmac.compare_digest(
                    c["defesa_swarm_token"].value, SECRET
                ):
                    return True
            except Exception:
                pass

        # 2. Check Basic Auth
        auth_hdr = self.headers.get("Authorization", "")
        if auth_hdr.startswith("Basic "):
            try:
                decoded = base64.b64decode(auth_hdr[6:]).decode("utf-8", "ignore")
                if ":" in decoded:
                    _, pwd = decoded.split(":", 1)
                    if hmac.compare_digest(pwd, PASSWORD):
                        return True
            except Exception:
                pass
        return False

    def send_json(self, code, payload):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def send_login_page(self, error_msg=""):
        err_html = (
            f'<div class="login-error">{error_msg}</div>' if error_msg else ""
        )
        body = LOGIN_HTML.replace("__ERROR_BLOCK__", err_html).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def proxy_visualizer(self, path_and_query):
        # Strip /visualizer prefix when forwarding to 127.0.0.1:8081
        subpath = path_and_query[len("/visualizer") :]
        if not subpath.startswith("/"):
            subpath = "/" + subpath
        target_url = VISUALIZER_UPSTREAM + subpath
        try:
            req = urllib.request.Request(target_url, headers={"User-Agent": "SwarmPortal/1.0"})
            with urllib.request.urlopen(req, timeout=8) as resp:
                content = resp.read()
                ctype = resp.headers.get("Content-Type", "text/html")
                if "text/html" in ctype:
                    text = content.decode("utf-8", "ignore")
                    # Ensure relative assets resolve under /visualizer/
                    text = text.replace('href="/', 'href="/visualizer/').replace(
                        'src="/', 'src="/visualizer/'
                    )
                    content = text.encode("utf-8")
                self.send_response(resp.status)
                self.send_header("Content-Type", ctype)
                self.send_header("Content-Length", str(len(content)))
                self.end_headers()
                self.wfile.write(content)
        except Exception as e:
            msg = f"Visualizer indisponivel no momento: {e}".encode("utf-8")
            self.send_response(502)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(msg)))
            self.end_headers()
            self.wfile.write(msg)

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path

        if path == "/healthz":
            return self.send_json(200, {"status": "UP"})

        # Allow app.css on login screen
        if path == "/app.css":
            css_file = BASE_DIR / "app.css"
            data = css_file.read_bytes()
            self.send_response(200)
            self.send_header("Content-Type", "text/css; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
            return

        if path == "/auth/logout":
            self.send_response(302)
            self.send_header(
                "Set-Cookie",
                "defesa_swarm_token=; Path=/; Max-Age=0; HttpOnly; SameSite=Lax",
            )
            self.send_header("Location", "/")
            self.end_headers()
            return

        if not self.is_authenticated():
            return self.send_login_page()

        if path == "/api/swarm/status":
            return self.send_json(200, get_swarm_status())

        if path == "/visualizer":
            self.send_response(301)
            self.send_header("Location", "/visualizer/")
            self.end_headers()
            return

        if path.startswith("/visualizer/") or path.startswith("/apis/"):
            # Forward /apis/ as well since dockersamples/visualizer fetches /apis/... from root
            if path.startswith("/apis/"):
                full_q = "/visualizer" + self.path
                return self.proxy_visualizer(full_q)
            return self.proxy_visualizer(self.path)

        # Serve static files
        rel = "index.html" if path in ("/", "/index.html") else path.lstrip("/")
        target = (BASE_DIR / rel).resolve()
        if not str(target).startswith(str(BASE_DIR)) or not target.is_file():
            self.send_response(404)
            self.end_headers()
            return

        ctype, _ = mimetypes.guess_type(str(target))
        data = target.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", (ctype or "application/octet-stream") + "; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_POST(self):
        parsed = urlparse(self.path)
        path = parsed.path
        length = int(self.headers.get("Content-Length", "0"))
        raw_body = self.rfile.read(length).decode("utf-8", "ignore") if length > 0 else ""

        if path == "/auth/login":
            params = parse_qs(raw_body)
            pwd = params.get("password", [""])[0]
            if hmac.compare_digest(pwd, PASSWORD):
                self.send_response(302)
                self.send_header(
                    "Set-Cookie",
                    f"defesa_swarm_token={SECRET}; Path=/; Max-Age=86400; HttpOnly; SameSite=Lax",
                )
                self.send_header("Location", "/")
                self.end_headers()
                return
            return self.send_login_page("Senha incorreta. Tente novamente.")

        if not self.is_authenticated():
            return self.send_json(401, {"error": "Unauthorized"})

        if path == "/api/swarm/scale":
            try:
                body = json.loads(raw_body or "{}")
                service = body.get("service", "backend")
                replicas = int(body.get("replicas", 3))
                if service not in ("backend", "frontend"):
                    return self.send_json(400, {"error": "Invalid service"})
                replicas = max(1, min(6, replicas))
                run_cmd(f"docker service scale defesacivil_{service}={replicas}", timeout=25)
                return self.send_json(200, get_swarm_status())
            except Exception as e:
                return self.send_json(500, {"error": str(e)})

        if path == "/api/swarm/heal-demo":
            cid = run_cmd("docker ps -q --filter name=defesacivil_backend | head -n 1")
            if cid:
                run_cmd(f"docker rm -f {cid}", timeout=10)
            return self.send_json(200, get_swarm_status())

        self.send_json(404, {"error": "Not found"})


if __name__ == "__main__":
    server = ThreadingHTTPServer(("127.0.0.1", PORT), PortalHandler)
    print(f"Docker Swarm Portal rodando em http://127.0.0.1:{PORT}")
    server.serve_forever()

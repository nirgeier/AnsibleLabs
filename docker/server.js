const express = require("express");
const http = require("http");
const WebSocket = require("ws");
const pty = require("node-pty");
const path = require("path");
const url = require("url");

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ noServer: true });

const PORT = process.env.PORT || 3000;

// ── Static assets ─────────────────────────────────────────────────────────────
app.use(express.static(path.join(__dirname, "public")));

// ── MkDocs documentation (served at /docs/) ───────────────────────────────────
const docsDir = process.env.DOCS_DIR || path.join(__dirname, "docs");
app.use("/docs", express.static(docsDir));

// ── Terminal target definitions ───────────────────────────────────────────────
// Each tab connects to ws://<host>/ws?target=<id>
// The shell spawned depends on whether this is the controller or a managed server.
const TARGETS = {
  controller: {
    label: "ansible-controller",
    // On the controller container the 'ansible' user is the main workspace
    spawn: () =>
      pty.spawn("su", ["-", "ansible"], {
        name: "xterm-256color",
        cols: 120,
        rows: 40,
        cwd: "/",
        env: { TERM: "xterm-256color", LANG: "en_US.UTF-8" },
      }),
  },
  "server-1": {
    label: "server-1",
    spawn: () =>
      pty.spawn(
        "ssh",
        [
          "-o",
          "StrictHostKeyChecking=no",
          "-o",
          "UserKnownHostsFile=/dev/null",
          "-i",
          "/ssh-shared/id_rsa",
          "root@server-1",
        ],
        {
          name: "xterm-256color",
          cols: 120,
          rows: 40,
          cwd: "/",
          env: { TERM: "xterm-256color", LANG: "en_US.UTF-8" },
        },
      ),
  },
  "server-2": {
    label: "server-2",
    spawn: () =>
      pty.spawn(
        "ssh",
        [
          "-o",
          "StrictHostKeyChecking=no",
          "-o",
          "UserKnownHostsFile=/dev/null",
          "-i",
          "/ssh-shared/id_rsa",
          "root@server-2",
        ],
        {
          name: "xterm-256color",
          cols: 120,
          rows: 40,
          cwd: "/",
          env: { TERM: "xterm-256color", LANG: "en_US.UTF-8" },
        },
      ),
  },
  "server-3": {
    label: "server-3",
    spawn: () =>
      pty.spawn(
        "ssh",
        [
          "-o",
          "StrictHostKeyChecking=no",
          "-o",
          "UserKnownHostsFile=/dev/null",
          "-i",
          "/ssh-shared/id_rsa",
          "root@server-3",
        ],
        {
          name: "xterm-256color",
          cols: 120,
          rows: 40,
          cwd: "/",
          env: { TERM: "xterm-256color", LANG: "en_US.UTF-8" },
        },
      ),
  },
};

// ── Upgrade handler: route each WebSocket by ?target= ────────────────────────
server.on("upgrade", (request, socket, head) => {
  const parsed = url.parse(request.url, true);
  const target = parsed.query.target || "controller";

  if (!TARGETS[target]) {
    socket.destroy();
    return;
  }

  wss.handleUpgrade(request, socket, head, (ws) => {
    ws._target = target;
    wss.emit("connection", ws, request);
  });
});

// ── WebSocket session handler ─────────────────────────────────────────────────
wss.on("connection", (ws) => {
  const target = ws._target || "controller";
  const def = TARGETS[target];

  let shell;
  try {
    shell = def.spawn();
  } catch (e) {
    ws.send(
      JSON.stringify({
        type: "output",
        data: `\r\n\x1b[31mFailed to connect to ${target}: ${e.message}\x1b[0m\r\n`,
      }),
    );
    ws.close();
    return;
  }

  shell.onData((data) => {
    try {
      ws.send(JSON.stringify({ type: "output", data }));
    } catch (_) {}
  });

  shell.onExit(({ exitCode }) => {
    try {
      ws.send(JSON.stringify({ type: "exit", exitCode }));
      ws.close();
    } catch (_) {}
  });

  ws.on("message", (msg) => {
    try {
      const message = JSON.parse(msg);
      switch (message.type) {
        case "input":
          shell.write(message.data);
          break;
        case "resize":
          if (message.cols && message.rows)
            shell.resize(message.cols, message.rows);
          break;
      }
    } catch (_) {}
  });

  ws.on("close", () => {
    try {
      shell.kill();
    } catch (_) {}
  });
});

// ── Start ─────────────────────────────────────────────────────────────────────
server.listen(PORT, "0.0.0.0", () => {
  console.log("");
  console.log("╔══════════════════════════════════════════════════════════╗");
  console.log("║   Ansible Labs - Interactive Terminal Ready              ║");
  console.log("║                                                          ║");
  console.log("║   Tabs: controller | server-1 | server-2 | server-3      ║");
  console.log(
    `║   Open: http://localhost:${PORT}                            ║`,
  );
  console.log("╚══════════════════════════════════════════════════════════╝");
  console.log("");
});

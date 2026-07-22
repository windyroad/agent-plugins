#!/usr/bin/env node

import { spawn } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";

const timeoutMs = Number(process.env.WR_CRUISE_CODEX_TIMEOUT_MS) || 8_000;

function configCachePath() {
  if (process.env.WR_QUOTA_CACHE_FILE) return process.env.WR_QUOTA_CACHE_FILE;
  const codexHome = process.env.CODEX_HOME || join(homedir(), ".codex");
  const files = [join(process.cwd(), ".codex", "cruise.config.json"), join(codexHome, "cruise.config.json")];
  for (const file of files) {
    try {
      const value = JSON.parse(readFileSync(file, "utf8")).cache_path;
      if (typeof value === "string" && value) return value;
    } catch {}
  }
  return join(codexHome, "quota-state.json");
}

function expandHome(path) {
  return path === "~" ? homedir() : path.startsWith("~/") ? join(homedir(), path.slice(2)) : path;
}

function query(binary) {
  return new Promise((resolve, reject) => {
    const child = spawn(binary, ["app-server", "--stdio"], { stdio: ["pipe", "pipe", "ignore"] });
    let settled = false;
    let buffer = "";
    const finish = (error, result) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      child.kill();
      error ? reject(error) : resolve(result);
    };
    const timer = setTimeout(() => finish(new Error("Codex quota read timed out")), timeoutMs);

    child.on("error", (error) => finish(error));
    child.on("exit", (code) => {
      if (!settled) finish(new Error(`Codex app-server exited ${code}`));
    });
    child.stdout.on("data", (chunk) => {
      buffer += chunk;
      for (let newline; (newline = buffer.indexOf("\n")) >= 0; ) {
        const line = buffer.slice(0, newline);
        buffer = buffer.slice(newline + 1);
        if (!line) continue;
        let message;
        try { message = JSON.parse(line); } catch { continue; }
        if (message.id === 0) {
          child.stdin.write(`${JSON.stringify({ method: "initialized", params: {} })}\n`);
          child.stdin.write(`${JSON.stringify({ method: "account/rateLimits/read", id: 1, params: {} })}\n`);
        } else if (message.id === 1) {
          message.error ? finish(new Error("Codex quota read failed")) : finish(null, message.result);
        }
      }
    });
    child.stdin.write(`${JSON.stringify({
      method: "initialize",
      id: 0,
      params: { clientInfo: { name: "wr-cruise", title: "Windy Road Cruise", version: "1" } },
    })}\n`);
  });
}

function normalize(result) {
  const snapshot = result?.rateLimitsByLimitId?.codex || result?.rateLimits;
  const windows = [snapshot?.primary, snapshot?.secondary]
    .filter((window) => Number.isInteger(window?.usedPercent)
      && Number.isInteger(window?.resetsAt)
      && Number.isInteger(window?.windowDurationMins)
      && window.windowDurationMins > 0)
    .sort((a, b) => a.windowDurationMins - b.windowDurationMins);
  if (!windows.length) throw new Error("Codex returned no usable quota windows");

  const short = windows.length > 1 ? windows[0] : null;
  const long = windows.at(-1);
  return {
    five_used_pct: short?.usedPercent ?? 0,
    five_resets_at: short?.resetsAt ?? 0,
    five_window_s: short ? short.windowDurationMins * 60 : 0,
    week_used_pct: long.usedPercent,
    week_resets_at: long.resetsAt,
    week_window_s: long.windowDurationMins * 60,
    written_at: Math.floor(Date.now() / 1000),
    source: "codex-app-server",
  };
}

async function main() {
  const cachePath = expandHome(process.argv[2] || configCachePath());
  const candidates = (process.env.WR_CRUISE_CODEX_BINARY_ONLY === "1"
    ? [process.env.CODEX_BINARY]
    : [
      process.env.CODEX_BINARY,
      process.platform === "darwin" ? "/Applications/ChatGPT.app/Contents/Resources/codex" : null,
      "codex",
    ]).filter((value, index, all) => value && all.indexOf(value) === index)
    .filter((value) => value === "codex" || existsSync(value));

  let result;
  for (const binary of candidates) {
    try { result = await query(binary); break; } catch {}
  }
  if (!result) return;

  const state = normalize(result);
  mkdirSync(dirname(cachePath), { recursive: true });
  const temporary = `${cachePath}.${process.pid}.tmp`;
  writeFileSync(temporary, `${JSON.stringify(state)}\n`, { mode: 0o600 });
  renameSync(temporary, cachePath);

  // The frequent hook reads this trusted numeric sidecar without starting jq.
  const pacePath = `${cachePath}.pace`;
  const paceTemporary = `${pacePath}.${process.pid}.tmp`;
  const pace = [state.five_used_pct, state.five_resets_at, state.week_used_pct,
    state.week_resets_at, state.five_window_s, state.week_window_s, state.written_at].join(" ");
  writeFileSync(paceTemporary, `${pace}\n`, { mode: 0o600 });
  renameSync(paceTemporary, pacePath);
}

main().catch(() => {});

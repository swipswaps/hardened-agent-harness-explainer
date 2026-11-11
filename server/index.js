import http from 'node:http';
import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DIST = path.resolve(__dirname, '..', 'dist');
const PORT = Number(process.env.PORT || 8081);

const FALLBACK_RULES = [
  {
    id: 'env-secret-read',
    tools: ['Read', 'Write', 'Edit', 'MultiEdit', 'Bash'],
    path_regex: '(^|/)\\.env(\\.|$)|(^|/)secrets?/',
    decision: 'deny',
    reason: 'Access to sensitive path "{path}" is prohibited.'
  },
  {
    id: 'system-config-write',
    tools: ['Write', 'Edit', 'MultiEdit', 'Bash'],
    path_regex: 'config\\.system$',
    decision: 'deny',
    reason: 'Modification of system core configuration "{path}" requires human escalation.'
  }
];

let HOOK_POLICY = FALLBACK_RULES;
let POLICY_SOURCE = 'server-embedded';
try {
  const raw = readFileSync(path.join(DIST, 'hook_policy.json'), 'utf-8');
  const parsed = JSON.parse(raw);
  if (Array.isArray(parsed.rules) && parsed.rules.length > 0) {
    HOOK_POLICY = parsed.rules;
    POLICY_SOURCE = 'server-fetched';
  }
} catch (e) { /* keep fallback */ }

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.webp': 'image/webp',
  '.ico': 'image/x-icon',
  '.woff2': 'font/woff2',
  '.map': 'application/json; charset=utf-8'
};

const REQUIRED_HEADERS = [
  '# HANDOFF STATE',
  '## 1. COMPLETED WORK',
  '## 2. ACTIVE BLOCKERS',
  '## 3. MODIFIED FILES'
];

function testRegex(source, value) {
  if (!source || !value) return false;
  try { return new RegExp(source).test(value); } catch (e) { return false; }
}

function evaluatePolicy(payload) {
  const tool = payload.tool || payload.tool_name || '';
  const toolInput = payload.tool_input || {};
  const targetPath = toolInput.file_path || toolInput.path || payload.path || '';
  const command = toolInput.command || payload.command || '';

  for (const rule of HOOK_POLICY) {
    if (Array.isArray(rule.tools) && rule.tools.length > 0 && !rule.tools.includes(tool)) continue;
    const pathHit = testRegex(rule.path_regex, targetPath);
    const cmdHit = testRegex(rule.command_regex, command);
    if (!pathHit && !cmdHit) continue;

    const reason = String(rule.reason || 'Policy violation')
      .replace('{path}', targetPath || command)
      .replace('{command}', command || targetPath);

    const decision = rule.decision || 'deny';
    return {
      matchedRule: rule.id,
      decision,
      exitCode: decision === 'deny' ? 2 : 0,
      status: decision === 'deny' ? 'BLOCKED (Exit 2)' : 'ALLOWED (Exit 0)',
      color: decision === 'deny' ? '#ef4444' : '#10b981',
      stderr: reason,
      action: decision === 'deny'
        ? 'Tool execution intercepted. stderr returned to the model as feedback.'
        : 'Tool call allowed.',
      policySource: POLICY_SOURCE
    };
  }

  return {
    matchedRule: null,
    decision: 'allow',
    exitCode: 0,
    status: 'PASSED (Exit 0)',
    color: '#10b981',
    stderr: "No policy rule matched. Path or command '" + (targetPath || command) + "' is clear.",
    action: 'Tool call allowed.',
    policySource: POLICY_SOURCE
  };
}

function validateHandoff(markdown) {
  const missing = REQUIRED_HEADERS.filter((h) => !markdown.includes(h));
  if (missing.length > 0) {
    return { isValid: false, error: 'Invalid Handoff Schema: Missing required sections (' + missing.join(', ') + ')', checksum: null };
  }
  const hex = createHash('sha256').update(markdown, 'utf8').digest('hex');
  return { isValid: true, error: null, checksum: 'sha256-' + hex };
}

function sendJson(res, code, body) {
  res.writeHead(code, {
    'content-type': 'application/json; charset=utf-8',
    'access-control-allow-origin': '*',
    'cache-control': 'no-store'
  });
  res.end(JSON.stringify(body));
}

function readBody(req, limit = 2000000) {
  return new Promise((resolve, reject) => {
    let size = 0;
    const chunks = [];
    req.on('data', (chunk) => {
      size += chunk.length;
      if (size > limit) { reject(new Error('payload too large')); req.destroy(); }
      else { chunks.push(chunk); }
    });
    req.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
    req.on('error', reject);
  });
}

async function serveStatic(res, pathname) {
  let rel = decodeURIComponent(pathname.split('?')[0]);
  if (rel === '/' || rel === '') rel = '/index.html';
  const safe = path.normalize(rel).replace(/^(\.\.[/\\])+/, '');
  try {
    const buf = await readFile(path.join(DIST, safe));
    const ext = path.extname(safe).toLowerCase();
    res.writeHead(200, { 'content-type': MIME[ext] || 'application/octet-stream' });
    res.end(buf);
    return;
  } catch (e) { /* SPA fallback */ }
  try {
    const buf = await readFile(path.join(DIST, 'index.html'));
    res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' });
    res.end(buf);
  } catch (e) {
    res.writeHead(404, { 'content-type': 'text/plain; charset=utf-8' });
    res.end('dist/ not found — run npm run build first');
  }
}

const server = http.createServer(async (req, res) => {
  try {
    const url = new URL(req.url, 'http://' + (req.headers.host || 'localhost'));
    if (req.method === 'OPTIONS') {
      res.writeHead(204, {
        'access-control-allow-origin': '*',
        'access-control-allow-methods': 'GET,POST,OPTIONS',
        'access-control-allow-headers': 'content-type'
      });
      res.end();
      return;
    }
    if (url.pathname === '/api/health') {
      sendJson(res, 200, {
        backend: 'ok',
        mode: 'full',
        service: 'hardened-agent-harness',
        version: '3.0.5',
        policyRules: HOOK_POLICY.length,
        policySource: POLICY_SOURCE
      });
      return;
    }
    if (url.pathname === '/api/hooks/evaluate' && req.method === 'POST') {
      try {
        const body = JSON.parse(await readBody(req));
        sendJson(res, 200, evaluatePolicy(body));
      } catch (e) {
        sendJson(res, 400, { error: String((e && e.message) || e) });
      }
      return;
    }
    if (url.pathname === '/api/handoff/validate' && req.method === 'POST') {
      try {
        const body = JSON.parse(await readBody(req));
        sendJson(res, 200, validateHandoff(String(body.markdown || '')));
      } catch (e) {
        sendJson(res, 400, { error: String((e && e.message) || e) });
      }
      return;
    }
    await serveStatic(res, url.pathname);
  } catch (e) {
    sendJson(res, 500, { error: String((e && e.message) || e) });
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log('[harness] listening on :' + PORT + ' (dist=' + DIST + ', policy=' + POLICY_SOURCE + ')');
});

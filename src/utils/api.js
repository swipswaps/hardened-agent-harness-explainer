import { FALLBACK_RULES } from './policyFallback.js';

let CACHED_RULES = null;
let CACHED_SOURCE = 'none';

export async function loadPolicy(baseUrl = '') {
  if (CACHED_RULES) return { rules: CACHED_RULES, source: CACHED_SOURCE };
  try {
    const res = await fetch(baseUrl + 'hook_policy.json', { cache: 'no-store' });
    if (res.ok) {
      const body = await res.json();
      if (Array.isArray(body.rules) && body.rules.length > 0) {
        CACHED_RULES = body.rules;
        CACHED_SOURCE = 'client-fetched';
        return { rules: CACHED_RULES, source: CACHED_SOURCE };
      }
    }
  } catch (e) { /* fall through */ }
  CACHED_RULES = FALLBACK_RULES;
  CACHED_SOURCE = 'client-embedded';
  return { rules: CACHED_RULES, source: CACHED_SOURCE };
}

async function probeOne(apiBase, timeoutMs) {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const res = await fetch(apiBase + '/api/health', {
      method: 'GET', cache: 'no-store', signal: ctrl.signal
    });
    if (!res.ok) return { online: false, reason: 'HTTP ' + res.status };
    const body = await res.json();
    return { online: true, ...body };
  } catch (e) {
    return {
      online: false,
      reason: e && e.name === 'AbortError' ? 'timeout' : String((e && e.message) || e)
    };
  } finally {
    clearTimeout(timer);
  }
}

const DEFAULT_LOCAL_BACKEND =
  (import.meta && import.meta.env && import.meta.env.VITE_LOCAL_BACKEND) ||
  'http://localhost:8081';

export async function probeBackend(apiBase = '', timeoutMs = 2500) {
  const isHttps = typeof window !== 'undefined' && window.location.protocol === 'https:';

  // On HTTPS (GitHub Pages): try localhost first. Browsers exempt localhost
  // from mixed-content blocking (W3C potentially-trustworthy-origin), so this
  // works whenever the user has `docker compose up -d` running locally.
  if (isHttps) {
    const local = await probeOne(DEFAULT_LOCAL_BACKEND, timeoutMs);
    if (local.online) {
      return { ...local, backendOrigin: DEFAULT_LOCAL_BACKEND };
    }
  }

  // Otherwise probe the page's own origin. Works on http://localhost:8081.
  const origin = await probeOne(apiBase, timeoutMs);
  if (origin.online) {
    return { ...origin, backendOrigin: apiBase || 'same-origin' };
  }

  // Both failed. On HTTPS, say exactly why.
  if (isHttps) {
    if (origin.reason === 'HTTP 404') {
      return {
        online: false,
        reason: 'no localhost backend — run: docker compose up -d',
        backendOrigin: 'none'
      };
    }
    return { online: false, reason: 'unreachable (offline or blocked)', backendOrigin: 'none' };
  }

  return origin;
}


export async function evaluateHookRemote(apiBase, payload) {
  const res = await fetch(apiBase + '/api/hooks/evaluate', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(payload)
  });
  if (!res.ok) throw new Error('hooks/evaluate HTTP ' + res.status);
  const body = await res.json();
  return { ...body, policySource: 'server' };
}

function testRegex(source, value) {
  if (!source || !value) return false;
  try { return new RegExp(source).test(value); } catch (e) { return false; }
}

export function evaluateHookLocal(payload, rules, policySource = 'client-embedded') {
  const tool = payload.tool || '';
  const path = payload.path || '';
  const command = payload.command || '';

  for (const rule of rules) {
    if (Array.isArray(rule.tools) && rule.tools.length > 0 && !rule.tools.includes(tool)) continue;
    if (rule.requires_file) continue;
    const pathHit = testRegex(rule.path_regex, path);
    const cmdHit = testRegex(rule.command_regex, command);
    if (!pathHit && !cmdHit) continue;

    const reason = String(rule.reason || '')
      .replace('{path}', path || command)
      .replace('{command}', command || path);

    return {
      matchedRule: rule.id,
      decision: rule.decision || 'deny',
      exitCode: rule.decision === 'deny' ? 2 : 0,
      status: rule.decision === 'deny' ? 'BLOCKED (Exit 2)' : 'ALLOWED (Exit 0)',
      color: rule.decision === 'deny' ? '#ef4444' : '#10b981',
      stderr: reason,
      action: rule.decision === 'deny'
        ? 'Tool execution intercepted. stderr returned to the model as feedback.'
        : 'Tool call allowed.',
      policySource
    };
  }

  return {
    matchedRule: null,
    decision: 'allow',
    exitCode: 0,
    status: 'PASSED (Exit 0)',
    color: '#10b981',
    stderr: "No policy rule matched. Path or command '" + (path || command) + "' is clear.",
    action: 'Tool call allowed.',
    policySource
  };
}

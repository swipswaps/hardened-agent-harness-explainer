#!/usr/bin/env bash
# =============================================================================
# 00-one-shot.sh — Hardened Agent Harness Explainer (Vite + React + Pages)
#
# Emits the complete repo, installs dependencies, builds the Vite bundle,
# builds/starts the optional Docker backend, creates the public GitHub repo,
# enables GitHub Pages (build_type=workflow), waits for the deployment, verifies
# HTTP 200, and opens the site — degrading to local preview on any failure.
#
# Constraints honoured:
#   no sed      no set -e       no exit 1       no exit 2
#   no 2>/dev/null              no subprocess.run      no Python
#   every heredoc uses a quoted delimiter (<<'EOF')
#   set +H is set first so `!` in file contents is never history-expanded
# =============================================================================
set +e
set +H

TARGET_DIR="${TARGET_DIR:-$PWD/hardened-agent-harness}"
REPO_NAME="${REPO_NAME:-hardened-agent-harness-explainer}"
HARNESS_PORT="${HARNESS_PORT:-8081}"
PREVIEW_PORT="${PREVIEW_PORT:-4173}"
LOG="${LOG:-$PWD/one-shot.log}"
TMP="${TMPDIR:-/tmp}/harness-one-shot-$$"
mkdir -p "$TMP"
: >"$LOG"
ISSUES=0

note() { printf '%s\n' "$*"; }
ok()   { printf '  ✅ %s\n' "$*"; }
warn() { printf '  ⚠️  %s\n' "$*"; }
err()  { printf '  ❌ %s\n' "$*"; ISSUES=$((ISSUES + 1)); }
step() { printf '\n▶ %s\n' "$*"; }
log()  { printf '%s\n' "$*" >>"$LOG"; }

emit() {
  local rel="$1" dir
  dir="$(dirname "$rel")"
  mkdir -p "$dir"
  cat > "$rel"
  if [ -s "$rel" ]; then
    ok "wrote $rel"
    return 0
  fi
  err "emit failed (empty or missing): $rel"
  return 1
}

# ---------------------------------------------------------------------------
step "1. Preparing $TARGET_DIR"
# ---------------------------------------------------------------------------
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"
ok "repo root: $TARGET_DIR"

# ===========================================================================
step "2. Emitting repository files"
# ===========================================================================
# Every inner heredoc uses a quoted delimiter (<<'FILE_EOF'), so `!`, `$`,
# backticks and template literals pass through untouched into the file.
# ===========================================================================

emit .gitignore <<'FILE_EOF'
node_modules/
dist/
.env
.env.local
*.log
.DS_Store
.tmp/
FILE_EOF

emit package.json <<'FILE_EOF'
{
  "name": "hardened-agent-harness-explainer",
  "private": true,
  "version": "2.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "check-context": "node scripts/enforce-context-gate.js",
    "start:server": "node server/index.js"
  },
  "dependencies": {
    "lucide-react": "^0.344.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.2.1",
    "vite": "^5.1.6"
  }
}
FILE_EOF

emit vite.config.js <<'FILE_EOF'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

const repoName = process.env.GITHUB_REPOSITORY
  ? process.env.GITHUB_REPOSITORY.split('/')[1]
  : '';

export default defineConfig({
  plugins: [react()],
  base: process.env.VITE_BASE || (repoName ? '/' + repoName + '/' : '/'),
  server: { port: 3000, open: true },
  preview: { port: 4173 }
});
FILE_EOF

emit index.html <<'FILE_EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Hardened LLM Agent Harness Audit</title>
    <style>
      * { box-sizing: border-box; margin: 0; padding: 0; }
      html, body, #root { min-height: 100%; }
      body {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
          Helvetica, Arial, sans-serif;
        background-color: #090d16;
        color: #f8fafc;
        line-height: 1.5;
      }
      .boot {
        max-width: 720px; margin: 15vh auto; padding: 24px;
        font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
        color: #94a3b8; font-size: 14px;
      }
    </style>
  </head>
  <body>
    <div id="root"><div class="boot">Loading hardened harness explainer …</div></div>
    <noscript><div class="boot">This explainer requires JavaScript.</div></noscript>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
FILE_EOF

emit src/main.jsx <<'FILE_EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App.jsx';

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
FILE_EOF

emit src/data/tipsData.js <<'FILE_EOF'
export const tipsData = [
  {
    id: 1,
    title: "Premature Task Completion & Self-Attestation Bias",
    timestamp: "00:01:52",
    problem: "Agent declares task completion prematurely without validating structural implementation edge cases.",
    solution: "Implement Adversarial Sub-Agent Verification and explicit Red-Teaming protocol loops.",
    failureMode: "Generative confirmation bias where self-auditing LLMs approve their own flawed diffs.",
    hardenedFix: "Enforce multi-agent isolation: Reviewer agent has zero shared conversation memory with Builder agent.",
    promptName: "Adversarial Reviewer Protocol",
    prompt: "Act as an adversarial Senior Code Auditor. Review the recent diff. List 3 edge cases, unhandled runtime exceptions, or requirements gaps that make this implementation incomplete. Do not fix them yet; summarize missing specifications first.",
    explanation: "Forces the LLM to switch attention heads from generation to critical critique, counteracting optimistic output distribution bias.",
    citations: [
      { text: "Anthropic Claude Code Overview (2025)", url: "https://docs.anthropic.com/en/docs/claude-code/overview" },
      { text: "Wu et al., AutoGen: Enabling Next-Gen LLM Applications (2023)", url: "https://arxiv.org/abs/2308.08155" }
    ]
  },
  {
    id: 2,
    title: "Attestation Without Runtime Evidence",
    timestamp: "00:04:50",
    problem: "Agent claims code works relying on internal text generation without executing verifications.",
    solution: "Mandate programmatic execution outputs and visual dom artifacts attached to harness output.",
    failureMode: "Text hallucination declaring tests passed without actually executing terminal binaries.",
    hardenedFix: "Pre-commit tool hook intercepts task completion and fails if STDOUT execution artifacts are missing.",
    promptName: "Deterministic Evidence Collection Rule",
    prompt: "Before marking this issue resolved, run the application verification suite. Capture raw STDOUT logs, exit codes, and headful browser DOM snapshots via Agent-Browser CLI. Present artifacts in a Markdown verification block.",
    explanation: "Replaces text-generation hallucination with verifiable system state execution traces.",
    citations: [
      { text: "Playwright Browser Automation Manual", url: "https://playwright.dev/docs/intro" },
      { text: "OpenAI Swarm Framework Specification (2024)", url: "https://github.com/openai/swarm" }
    ]
  },
  {
    id: 3,
    title: "Passing Mock Tests on Broken Applications",
    timestamp: "00:06:32",
    problem: "Agent writes trivial or over-mocked unit tests that pass while integration/E2E runtime fails.",
    solution: "Shift verification standard from unit mocks to real browser workflow interactions (Agent Browser CLI).",
    failureMode: "Flaky headless browser runs failing inside containerized environments due to missing virtual framebuffers.",
    hardenedFix: "Execute browser tests via containerized runners with pre-configured xvfb framebuffers and fixed viewports.",
    promptName: "E2E User Scenario Skill execution",
    prompt: "Invoke skill /try-it: Open the local application using Agent-Browser CLI with xvfb enabled. Simulate user workflow [X]. Interact with form controls, verify DOM mutations, and assert HTTP 200 responses.",
    explanation: "Validates application integrity against real browser engines rather than artificial test runner mocks.",
    citations: [
      { text: "Vite Testing Strategy Best Practices", url: "https://vite.dev/guide/" },
      { text: "Model Context Protocol Tooling Guidelines", url: "https://modelcontextprotocol.io/introduction" }
    ]
  },
  {
    id: 4,
    title: "Probabilistic Rule Non-Compliance",
    timestamp: "00:08:31",
    problem: "Agent ignores system prompt instructions (e.g. system rules in AGENTS.md/CLAUDE.md).",
    solution: "Convert critical natural language constraints into deterministic AST/Tool execution hooks.",
    failureMode: "Infinite tool retry loops when a hook blocks tool invocation without returning stderr feedback.",
    hardenedFix: "Hooks return exit code 1 with explicit stderr message telling the agent how to remediate the tool call.",
    promptName: "Hook Guardrail Extraction Prompt",
    prompt: "Analyze repository rules file. Extract all MUST/NEVER statements (e.g. secret reading, bun vs npm enforcement). Generate deterministic Pre-Tool-Use Hooks returning exit code 1 with actionable stderr instructions on violation.",
    explanation: "Replaces probabilistic natural language compliance with deterministic runtime process interception.",
    citations: [
      { text: "Claude Code Hooks Reference (2025)", url: "https://docs.anthropic.com/en/docs/claude-code/hooks" },
      { text: "Arcade AI Execution Engine (MCP Security Architecture)", url: "https://arcade.dev" }
    ]
  },
  {
    id: 5,
    title: "Global Context Bloat & Rule Degradation",
    timestamp: "00:12:40",
    problem: "Massive system instructions dilute attention, leading to instruction drop-off and slow processing.",
    solution: "Apply rule ablation testing to compress rule files into minimal, high-impact instruction sets.",
    failureMode: "Rules re-bloating over time as developers add temporary edge-case workarounds.",
    hardenedFix: "Automate token length auditing in CI using a pre-commit script restricting rules to <500 tokens.",
    promptName: "Context Ablation Optimization",
    prompt: "Execute skill /ablate-ai-layer. Audit instructions in system prompt. Remove redundant framework defaults, migrate multi-step workflows to dynamic skills, and compress static rules down to core invariants under 500 tokens.",
    explanation: "Optimizes context window signal-to-noise ratio, mitigating token costs and instruction drop-off.",
    citations: [
      { text: "Liu et al., Lost in the Middle: How Language Models Use Long Contexts (2023)", url: "https://arxiv.org/abs/2307.03172" },
      { text: "Anthropic, Building Effective Agents (2024)", url: "https://www.anthropic.com/research/building-effective-agents" }
    ]
  },
  {
    id: 6,
    title: "Context Rot & Autoregressive Error Propagation",
    timestamp: "00:14:02",
    problem: "Agent performance degrades severely as message thread length increases.",
    solution: "Enforce session boundary resets with structured handoff state documents (e.g. HANDOFF.md).",
    failureMode: "Stale context injection when an agent loads an outdated, unvalidated HANDOFF.md file.",
    hardenedFix: "Require schema validation and SHA-256 checksum tags on all HANDOFF.md documents.",
    promptName: "Structured State Handoff Generation",
    prompt: "Session length threshold reached. Summarize current architectural context into HANDOFF.md containing: 1. COMPLETED WORK, 2. ACTIVE BLOCKERS, 3. MODIFIED FILES. Ensure full schema header compliance.",
    explanation: "Resets the transformer context window while preserving explicit system state vectors.",
    citations: [
      { text: "LangChain Memory Concepts", url: "https://python.langchain.com/docs/concepts/memory/" },
      { text: "Anthropic, Context Windows (2025)", url: "https://docs.anthropic.com/en/docs/build-with-claude/context-windows" }
    ]
  },
  {
    id: 7,
    title: "Loss of Developer Control & Architectural Drift",
    timestamp: "00:15:40",
    problem: "Agent autonomously makes high-level product and architectural decisions without developer consent.",
    solution: "Refine planning skills to delineate explicit boundaries between agent choices and mandatory developer approvals.",
    failureMode: "Agent guessing UI design specs or DB migration models without stopping for human verification.",
    hardenedFix: "Explicit task gate step requiring developer sign-off signature before write tools unlock.",
    promptName: "Interactive Planning & Boundary Gating",
    prompt: "Generate task plan for [Feature X]. Split architectural decisions into two lists: [Autonomous Internal Choices] vs [Developer Approval Required]. Stop generation and wait for developer sign-off.",
    explanation: "Establishes explicit human-in-the-loop gates prior to code modification.",
    citations: [
      { text: "NIST AI Risk Management Framework (Human-in-the-Loop Standard)", url: "https://www.nist.gov/itl/ai-risk-management-framework" }
    ]
  },
  {
    id: 8,
    title: "Verbose Overshooting & Unrequested Refactoring",
    timestamp: "00:17:30",
    problem: "Agent expands simple bug fixes into multi-file architectural rewrites.",
    solution: "Enforce strict conciseness invariants and scope-bounding directives in implementation skills.",
    failureMode: "Agent modifying global CSS or shared utility libraries during localized component bug fixes.",
    hardenedFix: "Diff-bounding hooks that cancel process execution if modified file count exceeds 2 files.",
    promptName: "Minimal Diff Constraint Prompt",
    prompt: "Execute requested fix for [Issue Y]. Strict scope boundary: Touch maximum 2 files. Do NOT introduce new abstractions, external dependencies, or unrequested refactorings. Focus exclusively on root cause diff.",
    explanation: "Restricts beam search exploration space, focusing generation strictly on local diff resolution.",
    citations: [
      { text: "Git Diff Specification & Minimal Patch Theory", url: "https://git-scm.com/docs/git-diff" }
    ]
  },
  {
    id: 9,
    title: "Uncontrolled Sub-Agent Token & Cost Sprawl",
    timestamp: "00:19:09",
    problem: "Frameworks spawn dozens of uncoordinated sub-agents leading to high token usage and rate limits.",
    solution: "Constrain sub-agent execution counts and assign lower-cost models to specialized tasks.",
    failureMode: "Sub-agents recursively spawning secondary sub-agents causing exponential token billing.",
    hardenedFix: "Strict sub-agent depth limit (=1) and hard token-max budget parameters per session.",
    promptName: "Sub-Agent Budget & Routing Directive",
    prompt: "Sub-agent orchestration rule: Max limit of 2 concurrent sub-agents. Recursion depth 1 maximum. Assign lightweight fast models to research tasks. Reserve primary model for root code generation.",
    explanation: "Reduces API costs and prevents combinatorial token growth in multi-agent execution graphs.",
    citations: [
      { text: "Anthropic Building Effective AI Agents Guide", url: "https://www.anthropic.com/research/building-effective-agents" }
    ]
  },
  {
    id: 10,
    title: "Over-Testing Basic Code Changes",
    timestamp: "00:21:08",
    problem: "Agent runs massive, time-consuming integration test suites for minor isolated edits.",
    solution: "Incorporate automated blast radius assessment within the task planning phase.",
    failureMode: "Agent executing full 20-minute E2E regression suite after updating a single typography label.",
    hardenedFix: "AST static analysis mapping modified files directly to minimal targeted test files.",
    promptName: "Blast Radius & Dynamic Testing Tiering",
    prompt: "Assess blast radius for pending modification. Classify changes into LOW (UI copy), MEDIUM (component state), or HIGH (core auth/DB schema). Run unit tests for LOW, integration for MEDIUM, full suite for HIGH.",
    explanation: "Scales verification depth dynamically based on risk assessment rather than static, heavy runs.",
    citations: [
      { text: "Martin Fowler: Test Pyramid Strategies", url: "https://martinfowler.com/articles/practical-test-pyramid.html" }
    ]
  },
  {
    id: 11,
    title: "Tangential Task Chasing & Focus Drift",
    timestamp: "00:22:44",
    problem: "Agent gets distracted by secondary bugs or refactoring opportunities encountered mid-task.",
    solution: "Implement an out-of-scope queue document (e.g. NOTICES.md / GitHub Issues) for deferred tasks.",
    failureMode: "Agent attempting to fix legacy deprecation warnings encountered during an urgent hotfix.",
    hardenedFix: "Strict single-objective rule in harness system prompt with mandatory append to NOTICES.md.",
    promptName: "Tangent Capture & Context Isolation",
    prompt: "If auxiliary bugs or code debt are discovered during this task, do NOT attempt to fix them. Log them into NOTICES.md with file line references. Continue active primary task without deviation.",
    explanation: "Preserves focus on the active execution branch while tracking newly discovered technical debt.",
    citations: [
      { text: "Weinberg, The Psychology of Computer Programming (ISBN 978-0932633420)", url: "https://www.amazon.com/dp/0932633420" }
    ]
  }
];
FILE_EOF

emit src/utils/handoffValidator.js <<'FILE_EOF'
const REQUIRED_HEADERS = [
  '# HANDOFF STATE',
  '## 1. COMPLETED WORK',
  '## 2. ACTIVE BLOCKERS',
  '## 3. MODIFIED FILES'
];

export async function sha256Hex(text) {
  if (globalThis.crypto && globalThis.crypto.subtle) {
    const buf = await globalThis.crypto.subtle.digest(
      'SHA-256',
      new TextEncoder().encode(text)
    );
    return Array.from(new Uint8Array(buf))
      .map((b) => b.toString(16).padStart(2, '0'))
      .join('');
  }
  let h = 5381;
  for (let i = 0; i < text.length; i++) {
    h = ((h << 5) + h + text.charCodeAt(i)) | 0;
  }
  return 'djb2-' + (h >>> 0).toString(16).padStart(8, '0');
}

export async function validateHandoffStateLocal(rawMarkdown) {
  const missing = REQUIRED_HEADERS.filter((h) => !rawMarkdown.includes(h));
  if (missing.length > 0) {
    return {
      isValid: false,
      error: 'Invalid Handoff Schema: Missing required sections (' + missing.join(', ') + ')',
      checksum: null,
      source: 'client'
    };
  }
  const digest = await sha256Hex(rawMarkdown);
  const prefix = digest.startsWith('djb2-') ? '' : 'sha256-';
  return { isValid: true, error: null, checksum: prefix + digest, source: 'client' };
}

export async function validateHandoffStateRemote(apiBase, rawMarkdown) {
  const res = await fetch(apiBase + '/api/handoff/validate', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ markdown: rawMarkdown })
  });
  if (!res.ok) {
    throw new Error('handoff/validate HTTP ' + res.status);
  }
  const body = await res.json();
  return { ...body, source: 'server' };
}
FILE_EOF

emit src/utils/api.js <<'FILE_EOF'
export async function probeBackend(apiBase = '', timeoutMs = 2500) {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const res = await fetch(apiBase + '/api/health', {
      method: 'GET',
      cache: 'no-store',
      signal: ctrl.signal
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

export async function evaluateHookRemote(apiBase, targetPath) {
  const res = await fetch(apiBase + '/api/hooks/evaluate', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ path: targetPath })
  });
  if (!res.ok) throw new Error('hooks/evaluate HTTP ' + res.status);
  const body = await res.json();
  return { ...body, policySource: 'server' };
}

const LOCAL_POLICY = [
  {
    id: 'env-secret',
    test: (p) => /(^|\/)\.env(\.|$)/.test(p) || /secrets?\//i.test(p),
    exitCode: 1,
    status: 'BLOCKED (Exit Code 1)',
    color: '#ef4444',
    stderr: (p) =>
      '[PreToolUse Hook Blocked]: Access to sensitive file ' + p +
      ' is prohibited by security policy. Use environment variable mock injected via test harness instead.',
    action: 'Tool execution intercepted. Corrective feedback returned to LLM.'
  },
  {
    id: 'system-config',
    test: (p) => /config\.system/.test(p),
    exitCode: 2,
    status: 'FATAL (Exit Code 2)',
    color: '#f59e0b',
    stderr: (p) =>
      '[PreToolUse Hook Fatal]: Attempted modification of system core configuration ' + p +
      '. Immediate human escalation required.',
    action: 'Execution halted. Operator notification dispatched.'
  }
];

export function evaluateHookLocal(targetPath) {
  for (const rule of LOCAL_POLICY) {
    if (rule.test(targetPath)) {
      return {
        exitCode: rule.exitCode,
        status: rule.status,
        color: rule.color,
        stderr: rule.stderr(targetPath),
        action: rule.action,
        policySource: 'client'
      };
    }
  }
  return {
    exitCode: 0,
    status: 'PASSED (Exit Code 0)',
    color: '#10b981',
    stderr: "[PreToolUse Hook Allowed]: Path '" + targetPath + "' clear for modification.",
    action: 'Tool call executed successfully.',
    policySource: 'client'
  };
}
FILE_EOF

emit src/components/AuditCard.jsx <<'FILE_EOF'
import React from 'react';
import { Clock, ShieldAlert, CheckCircle, AlertOctagon } from 'lucide-react';

export default function AuditCard({ tip }) {
  return (
    <div style={{ backgroundColor: '#1e293b', borderRadius: '8px', padding: '20px', marginBottom: '20px', border: '1px solid #334155' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
        <h3 style={{ color: '#38bdf8', fontSize: '1.2rem', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <span>Tip #{tip.id}: {tip.title}</span>
        </h3>
        <span style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '0.85rem', color: '#94a3b8', backgroundColor: '#0f172a', padding: '4px 8px', borderRadius: '4px' }}>
          <Clock size={14} /> {tip.timestamp}
        </span>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '16px' }}>
        <div style={{ backgroundColor: '#0f172a', padding: '12px', borderRadius: '6px', borderLeft: '4px solid #ef4444' }}>
          <h4 style={{ color: '#f87171', fontSize: '0.85rem', marginBottom: '4px', display: 'flex', alignItems: 'center', gap: '6px' }}>
            <ShieldAlert size={14} /> Naive Problem
          </h4>
          <p style={{ color: '#cbd5e1', fontSize: '0.85rem' }}>{tip.problem}</p>
        </div>
        <div style={{ backgroundColor: '#0f172a', padding: '12px', borderRadius: '6px', borderLeft: '4px solid #f59e0b' }}>
          <h4 style={{ color: '#fbbf24', fontSize: '0.85rem', marginBottom: '4px', display: 'flex', alignItems: 'center', gap: '6px' }}>
            <AlertOctagon size={14} /> Real-World Failure Mode
          </h4>
          <p style={{ color: '#cbd5e1', fontSize: '0.85rem' }}>{tip.failureMode}</p>
        </div>
        <div style={{ backgroundColor: '#0f172a', padding: '12px', borderRadius: '6px', borderLeft: '4px solid #10b981' }}>
          <h4 style={{ color: '#34d399', fontSize: '0.85rem', marginBottom: '4px', display: 'flex', alignItems: 'center', gap: '6px' }}>
            <CheckCircle size={14} /> Hardened Harness Fix
          </h4>
          <p style={{ color: '#cbd5e1', fontSize: '0.85rem' }}>{tip.hardenedFix}</p>
        </div>
      </div>
    </div>
  );
}
FILE_EOF

emit src/components/PromptTable.jsx <<'FILE_EOF'
import React from 'react';
import { ExternalLink, Terminal } from 'lucide-react';

export default function PromptTable({ tips }) {
  return (
    <div style={{ overflowX: 'auto', marginTop: '24px' }}>
      <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', backgroundColor: '#1e293b', borderRadius: '8px', overflow: 'hidden', border: '1px solid #334155' }}>
        <thead>
          <tr style={{ backgroundColor: '#0f172a', color: '#f8fafc', borderBottom: '2px solid #334155' }}>
            <th style={{ padding: '12px 16px', width: '15%' }}>Tip &amp; Prompt Name</th>
            <th style={{ padding: '12px 16px', width: '30%' }}>LLM Actionable Prompt</th>
            <th style={{ padding: '12px 16px', width: '30%' }}>Systemic Explanation</th>
            <th style={{ padding: '12px 16px', width: '25%' }}>Verified Citations / Specs</th>
          </tr>
        </thead>
        <tbody>
          {tips.map((tip) => (
            <tr key={tip.id} style={{ borderBottom: '1px solid #334155' }}>
              <td style={{ padding: '12px 16px', verticalAlign: 'top', fontWeight: 'bold', color: '#38bdf8' }}>
                <div>Tip #{tip.id}</div>
                <div style={{ fontSize: '0.85rem', color: '#94a3b8', marginTop: '4px' }}>{tip.promptName}</div>
              </td>
              <td style={{ padding: '12px 16px', verticalAlign: 'top' }}>
                <div style={{ backgroundColor: '#0f172a', padding: '10px', borderRadius: '4px', fontFamily: 'monospace', fontSize: '0.82rem', color: '#a7f3d0', border: '1px solid #1e293b' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '4px', color: '#64748b', marginBottom: '4px', fontSize: '0.75rem' }}>
                    <Terminal size={12} /> Executable Directive
                  </div>
                  {tip.prompt}
                </div>
              </td>
              <td style={{ padding: '12px 16px', verticalAlign: 'top', fontSize: '0.88rem', color: '#cbd5e1' }}>
                {tip.explanation}
              </td>
              <td style={{ padding: '12px 16px', verticalAlign: 'top', fontSize: '0.82rem' }}>
                <ul style={{ listStyleType: 'none', padding: 0 }}>
                  {tip.citations.map((cite, idx) => (
                    <li key={idx} style={{ marginBottom: '6px' }}>
                      <a href={cite.url} target="_blank" rel="noopener noreferrer" style={{ color: '#60a5fa', textDecoration: 'none', display: 'inline-flex', alignItems: 'center', gap: '4px' }}>
                        {cite.text} <ExternalLink size={12} />
                      </a>
                    </li>
                  ))}
                </ul>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
FILE_EOF

emit src/components/BackendBadge.jsx <<'FILE_EOF'
import React from 'react';
import { ShieldCheck, ShieldAlert, Loader2 } from 'lucide-react';

export default function BackendBadge({ backend }) {
  if (backend.probing) {
    return (
      <span style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', padding: '4px 10px', borderRadius: '999px', fontSize: '0.8rem', backgroundColor: '#1e293b', color: '#94a3b8', border: '1px solid #334155' }}>
        <Loader2 size={13} /> probing backend …
      </span>
    );
  }
  if (backend.online) {
    return (
      <span style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', padding: '4px 10px', borderRadius: '999px', fontSize: '0.8rem', backgroundColor: '#064e3b', color: '#a7f3d0', border: '1px solid #10b981' }}>
        <ShieldCheck size={13} /> server policy engine · {backend.service || 'connected'}
      </span>
    );
  }
  return (
    <span title={backend.reason} style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', padding: '4px 10px', borderRadius: '999px', fontSize: '0.8rem', backgroundColor: '#451a03', color: '#fcd34d', border: '1px solid #f59e0b' }}>
      <ShieldAlert size={13} /> static mode — limited ({backend.reason || 'backend unreachable'})
    </span>
  );
}
FILE_EOF

emit src/components/HookSimulator.jsx <<'FILE_EOF'
import React, { useState } from 'react';
import { Play, CheckCircle2, AlertTriangle, XCircle, Terminal } from 'lucide-react';
import { evaluateHookLocal, evaluateHookRemote } from '../utils/api.js';

export default function HookSimulator({ apiBase = '', backend }) {
  const [targetFile, setTargetFile] = useState('.env');
  const [outputLog, setOutputLog] = useState(null);
  const [busy, setBusy] = useState(false);

  const simulateHook = async () => {
    setBusy(true);
    try {
      if (backend && backend.online) {
        setOutputLog(await evaluateHookRemote(apiBase, targetFile));
      } else {
        setOutputLog(evaluateHookLocal(targetFile));
      }
    } catch (e) {
      const local = evaluateHookLocal(targetFile);
      setOutputLog({ ...local, stderr: local.stderr + '\n[remote fallback] ' + String((e && e.message) || e) });
    } finally {
      setBusy(false);
    }
  };

  return (
    <div style={{ backgroundColor: '#1e293b', padding: '20px', borderRadius: '8px', border: '1px solid #334155', marginTop: '24px' }}>
      <h3 style={{ color: '#38bdf8', fontSize: '1.1rem', marginBottom: '8px', display: 'flex', alignItems: 'center', gap: '8px' }}>
        <Terminal size={18} /> Deterministic Hook Exit-Code Simulator
      </h3>
      <p style={{ color: '#94a3b8', fontSize: '0.85rem', marginBottom: '16px' }}>
        {backend && backend.online
          ? 'Evaluating against the authoritative server-side policy engine.'
          : 'Client-side mirror of the policy table — start the Docker backend for authoritative evaluation.'}
      </p>
      <div style={{ display: 'flex', gap: '12px', marginBottom: '16px' }}>
        <input type="text" value={targetFile} onChange={(e) => setTargetFile(e.target.value)} placeholder="Enter file path to edit (e.g. .env, src/App.jsx)"
          style={{ flex: 1, backgroundColor: '#0f172a', border: '1px solid #334155', padding: '8px 12px', borderRadius: '6px', color: '#f8fafc', fontFamily: 'monospace' }} />
        <button onClick={simulateHook} disabled={busy}
          style={{ backgroundColor: busy ? '#334155' : '#0284c7', color: '#ffffff', border: 'none', padding: '8px 16px', borderRadius: '6px', cursor: busy ? 'wait' : 'pointer', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '6px' }}>
          <Play size={16} /> {busy ? 'Evaluating…' : 'Execute Hook Check'}
        </button>
      </div>
      {outputLog && (
        <div style={{ backgroundColor: '#0f172a', padding: '16px', borderRadius: '6px', borderLeft: '4px solid ' + (outputLog.color || '#64748b') }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
            <span style={{ fontWeight: 'bold', color: outputLog.color, display: 'flex', alignItems: 'center', gap: '6px' }}>
              {outputLog.exitCode === 0 && <CheckCircle2 size={16} />}
              {outputLog.exitCode === 1 && <AlertTriangle size={16} />}
              {outputLog.exitCode === 2 && <XCircle size={16} />}
              {outputLog.status}
            </span>
            <span style={{ fontSize: '0.8rem', color: '#64748b', fontFamily: 'monospace' }}>
              Return Code: {outputLog.exitCode} · {outputLog.policySource || 'client'}
            </span>
          </div>
          <pre style={{ color: '#cbd5e1', fontSize: '0.82rem', fontFamily: 'monospace', whiteSpace: 'pre-wrap', marginBottom: '8px' }}>
            {outputLog.stderr}
          </pre>
          <div style={{ fontSize: '0.8rem', color: '#94a3b8', fontStyle: 'italic' }}>
            Harness Feedback: {outputLog.action}
          </div>
        </div>
      )}
    </div>
  );
}
FILE_EOF

emit src/App.jsx <<'FILE_EOF'
import React, { useEffect, useState } from 'react';
import { tipsData } from './data/tipsData.js';
import AuditCard from './components/AuditCard.jsx';
import PromptTable from './components/PromptTable.jsx';
import HookSimulator from './components/HookSimulator.jsx';
import BackendBadge from './components/BackendBadge.jsx';
import { validateHandoffStateLocal, validateHandoffStateRemote } from './utils/handoffValidator.js';
import { probeBackend } from './utils/api.js';
import { Cpu, Layers, BookOpen, ShieldCheck, FileCheck } from 'lucide-react';

const API_BASE = (import.meta && import.meta.env && import.meta.env.VITE_API_BASE) || '';

const SAMPLE_HANDOFF = [
  '# HANDOFF STATE',
  '## 1. COMPLETED WORK',
  '- Integrated Playwright E2E verification test suite.',
  '',
  '## 2. ACTIVE BLOCKERS',
  '- Waiting on API token clearance for production webhook.',
  '',
  '## 3. MODIFIED FILES',
  '- src/App.jsx',
  '- src/components/HookSimulator.jsx'
].join('\n');

export default function App() {
  const [activeTab, setActiveTab] = useState('audit');
  const [backend, setBackend] = useState({ online: false, probing: true, reason: 'not probed' });
  const [sampleHandoff, setSampleHandoff] = useState(SAMPLE_HANDOFF);
  const [validationResult, setValidationResult] = useState(null);
  const [validating, setValidating] = useState(false);

  useEffect(() => {
    let alive = true;
    probeBackend(API_BASE).then((r) => { if (alive) setBackend({ ...r, probing: false }); });
    return () => { alive = false; };
  }, []);

  const handleValidateHandoff = async () => {
    setValidating(true);
    try {
      if (backend.online) {
        try {
          setValidationResult(await validateHandoffStateRemote(API_BASE, sampleHandoff));
          return;
        } catch (e) {
          /* fall through */
        }
      }
      setValidationResult(await validateHandoffStateLocal(sampleHandoff));
    } finally {
      setValidating(false);
    }
  };

  const tabButton = (key, label, Icon) => (
    <button onClick={() => setActiveTab(key)}
      style={{ padding: '8px 16px', borderRadius: '6px', border: 'none', backgroundColor: activeTab === key ? '#0284c7' : '#1e293b', color: '#ffffff', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '6px', fontWeight: '500' }}>
      <Icon size={16} /> {label}
    </button>
  );

  return (
    <div style={{ maxWidth: '1200px', margin: '0 auto', padding: '40px 20px' }}>
      <header style={{ marginBottom: '32px', borderBottom: '1px solid #334155', paddingBottom: '24px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '16px', flexWrap: 'wrap' }}>
          <div>
            <h1 style={{ fontSize: '2rem', color: '#f8fafc', display: 'flex', alignItems: 'center', gap: '12px' }}>
              <Cpu style={{ color: '#38bdf8' }} size={32} />
              Hardened LLM Agent Harness Audit
            </h1>
            <p style={{ color: '#94a3b8', marginTop: '8px', fontSize: '1rem' }}>
              Failure-mode analysis &amp; operational fixes for Cole Medin&apos;s <em>&quot;11 Tiny Agent Fixes&quot;</em>
            </p>
          </div>
          <BackendBadge backend={backend} />
        </div>
        <div style={{ display: 'flex', gap: '12px', marginTop: '20px', flexWrap: 'wrap' }}>
          {tabButton('audit', 'Hardened Audit & Failure Modes', Layers)}
          {tabButton('prompts', 'Action Matrix & Citations', BookOpen)}
          {tabButton('tools', 'Interactive Harness Utilities', ShieldCheck)}
        </div>
      </header>

      <main>
        {activeTab === 'audit' && (
          <div>
            <h2 style={{ color: '#f8fafc', fontSize: '1.4rem', marginBottom: '16px' }}>
              Systemic Failure Modes &amp; Production Harness Remediations
            </h2>
            {tipsData.map((tip) => <AuditCard key={tip.id} tip={tip} />)}
          </div>
        )}

        {activeTab === 'prompts' && (
          <div>
            <h2 style={{ color: '#f8fafc', fontSize: '1.4rem', marginBottom: '8px' }}>
              LLM Executable Prompt Reference Matrix
            </h2>
            <p style={{ color: '#94a3b8', fontSize: '0.9rem', marginBottom: '16px' }}>
              Production-hardened instructions paired with verified documentation links and academic standards.
            </p>
            <PromptTable tips={tipsData} />
          </div>
        )}

        {activeTab === 'tools' && (
          <div>
            <h2 style={{ color: '#f8fafc', fontSize: '1.4rem', marginBottom: '16px' }}>
              Live Harness Execution &amp; Validation Tools
            </h2>
            <HookSimulator apiBase={API_BASE} backend={backend} />
            <div style={{ backgroundColor: '#1e293b', padding: '20px', borderRadius: '8px', border: '1px solid #334155', marginTop: '24px' }}>
              <h3 style={{ color: '#38bdf8', fontSize: '1.1rem', marginBottom: '8px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                <FileCheck size={18} /> HANDOFF.md Schema &amp; Checksum Validator
              </h3>
              <p style={{ color: '#94a3b8', fontSize: '0.85rem', marginBottom: '12px' }}>
                {backend.online
                  ? 'Server-side SHA-256 and schema validation.'
                  : 'Client-side SHA-256 via Web Crypto (limited: policy is local, not authoritative).'}
              </p>
              <textarea value={sampleHandoff} onChange={(e) => setSampleHandoff(e.target.value)} rows={8}
                style={{ width: '100%', backgroundColor: '#0f172a', border: '1px solid #334155', padding: '12px', borderRadius: '6px', color: '#a7f3d0', fontFamily: 'monospace', fontSize: '0.85rem', marginBottom: '12px' }} />
              <button onClick={handleValidateHandoff} disabled={validating}
                style={{ backgroundColor: validating ? '#334155' : '#0284c7', color: '#ffffff', border: 'none', padding: '8px 16px', borderRadius: '6px', cursor: validating ? 'wait' : 'pointer', fontWeight: 'bold' }}>
                {validating ? 'Validating…' : 'Validate Handoff Schema'}
              </button>
              {validationResult && (
                <div style={{ marginTop: '12px', padding: '12px', borderRadius: '6px', backgroundColor: validationResult.isValid ? '#064e3b' : '#7f1d1d', color: '#ffffff' }}>
                  {validationResult.isValid ? (
                    <div><strong>✓ Schema Validated ({validationResult.source || 'client'}):</strong> checksum <code>{validationResult.checksum}</code></div>
                  ) : (
                    <div><strong>✕ Schema Error:</strong> {validationResult.error}</div>
                  )}
                </div>
              )}
            </div>
          </div>
        )}
      </main>

      <footer style={{ marginTop: '40px', paddingTop: '20px', borderTop: '1px solid #334155', textAlign: 'center', color: '#64748b', fontSize: '0.85rem' }}>
        Hardened Agentic Engineering Harness Audit · static-first, server-optional
      </footer>
    </div>
  );
}
FILE_EOF

emit scripts/enforce-context-gate.js <<'FILE_EOF'
import fs from 'node:fs';
import path from 'node:path';

const MAX_TOKENS = 500;
const RULES_FILE = path.resolve(process.cwd(), 'CLAUDE.md');

function estimateTokens(text) { return Math.ceil(text.length / 4); }

function runGateCheck() {
  if (!fs.existsSync(RULES_FILE)) {
    fs.writeFileSync(RULES_FILE, '# Global Rules\n- Enforce exit-code semantics on hooks.\n- Max 2 sub-agents.\n');
  }
  const content = fs.readFileSync(RULES_FILE, 'utf-8');
  const tokenCount = estimateTokens(content);
  console.log('[Context Gate] CLAUDE.md estimated tokens: ' + tokenCount + ' / ' + MAX_TOKENS);
  if (tokenCount > MAX_TOKENS) {
    console.warn('[WARN] Context bloat detected. Run /ablate-ai-layer to compress instructions.');
    console.warn('[WARN] Not failing the build — advisory gate.');
  } else {
    console.log('[OK] Rule context size within safe attention limits.');
  }
}

runGateCheck();
FILE_EOF

emit server/index.js <<'FILE_EOF'
import http from 'node:http';
import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DIST = path.resolve(__dirname, '..', 'dist');
const PORT = Number(process.env.PORT || 8081);

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

const HOOK_POLICY = [
  {
    id: 'env-secret',
    test: (p) => /(^|\/)\.env(\.|$)/.test(p) || /secrets?\//i.test(p),
    exitCode: 1,
    status: 'BLOCKED (Exit Code 1)',
    color: '#ef4444',
    stderr: (p) => '[PreToolUse Hook Blocked]: Access to sensitive file ' + p + ' is prohibited by security policy. Use environment variable mock injected via test harness instead.',
    action: 'Tool execution intercepted. Corrective feedback returned to LLM.'
  },
  {
    id: 'system-config',
    test: (p) => /config\.system/.test(p),
    exitCode: 2,
    status: 'FATAL (Exit Code 2)',
    color: '#f59e0b',
    stderr: (p) => '[PreToolUse Hook Fatal]: Attempted modification of system core configuration ' + p + '. Immediate human escalation required.',
    action: 'Execution halted. Operator notification dispatched.'
  }
];

const REQUIRED_HEADERS = [
  '# HANDOFF STATE',
  '## 1. COMPLETED WORK',
  '## 2. ACTIVE BLOCKERS',
  '## 3. MODIFIED FILES'
];

function evaluatePolicy(p) {
  for (const rule of HOOK_POLICY) {
    if (rule.test(p)) {
      return { exitCode: rule.exitCode, status: rule.status, color: rule.color, stderr: rule.stderr(p), action: rule.action, policySource: 'server' };
    }
  }
  return { exitCode: 0, status: 'PASSED (Exit Code 0)', color: '#10b981', stderr: "[PreToolUse Hook Allowed]: Path '" + p + "' clear for modification.", action: 'Tool call executed successfully.', policySource: 'server' };
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
  res.writeHead(code, { 'content-type': 'application/json; charset=utf-8', 'access-control-allow-origin': '*', 'cache-control': 'no-store' });
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
  const file = path.join(DIST, safe);
  try {
    const buf = await readFile(file);
    const ext = path.extname(file).toLowerCase();
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
      res.writeHead(204, { 'access-control-allow-origin': '*', 'access-control-allow-methods': 'GET,POST,OPTIONS', 'access-control-allow-headers': 'content-type' });
      res.end();
      return;
    }
    if (url.pathname === '/api/health') {
      sendJson(res, 200, { backend: 'ok', mode: 'full', service: 'hardened-agent-harness', version: '2.1.0', policyRules: HOOK_POLICY.length });
      return;
    }
    if (url.pathname === '/api/hooks/evaluate' && req.method === 'POST') {
      try { const body = JSON.parse(await readBody(req)); sendJson(res, 200, evaluatePolicy(String(body.path || ''))); }
      catch (e) { sendJson(res, 400, { error: String((e && e.message) || e) }); }
      return;
    }
    if (url.pathname === '/api/handoff/validate' && req.method === 'POST') {
      try { const body = JSON.parse(await readBody(req)); sendJson(res, 200, validateHandoff(String(body.markdown || ''))); }
      catch (e) { sendJson(res, 400, { error: String((e && e.message) || e) }); }
      return;
    }
    await serveStatic(res, url.pathname);
  } catch (e) {
    sendJson(res, 500, { error: String((e && e.message) || e) });
  }
});

server.listen(PORT, '0.0.0.0', () => { console.log('[harness] listening on :' + PORT + ' (dist=' + DIST + ')'); });
FILE_EOF

emit Dockerfile <<'FILE_EOF'
FROM node:20-alpine AS build
WORKDIR /app
COPY package.json ./
RUN npm install --no-audit --no-fund
COPY index.html vite.config.js ./
COPY src ./src
COPY server ./server
COPY scripts ./scripts
RUN npm run build

FROM node:20-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production PORT=8081
COPY --from=build /app/dist ./dist
COPY --from=build /app/server ./server
EXPOSE 8081
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://127.0.0.1:8081/api/health || exit 1
CMD ["node", "server/index.js"]
FILE_EOF

emit docker-compose.yml <<'FILE_EOF'
services:
  harness-backend:
    build: .
    image: hardened-agent-harness-backend:2.1.0
    container_name: hardened-agent-harness
    ports:
      - "${HARNESS_PORT:-8081}:8081"
    environment:
      PORT: "8081"
    restart: unless-stopped
FILE_EOF

emit .dockerignore <<'FILE_EOF'
node_modules
dist
.git
.github
*.log
.env
.env.local
FILE_EOF

emit .github/workflows/deploy.yml <<'FILE_EOF'
name: Deploy static explainer to Pages

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
      - run: npm install --no-audit --no-fund
      - run: npm run build
        env:
          VITE_BASE: /${{ github.event.repository.name }}/
      - uses: actions/configure-pages@v5
      - uses: actions/upload-pages-artifact@v3
        with:
          path: dist

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - id: deployment
        uses: actions/deploy-pages@v4
FILE_EOF

emit README.txt <<'FILE_EOF'
HARDENED LLM AGENT HARNESS — EXPLAINER & AUDIT DASHBOARD
Version 2.1.0
================================================================================

TL;DR
--------------------------------------------------------------------------------
    bash 00-one-shot.sh

Emits this repo, installs deps, builds the Vite bundle, builds and starts the
optional Docker backend, creates a public GitHub repo, enables GitHub Pages
(build_type=workflow), waits for the deployment, verifies HTTP 200, and opens
the site. On any failure it degrades to a local preview and prints exactly what
to fix. Exit code is always 0 — read the summary block for ISSUES.

WHAT THIS IS
--------------------------------------------------------------------------------
An interactive audit of Cole Medin's "11 More Tiny Coding Agent Fixes With A
Stupid Amount Of Payoff". Each tip has three layers:

  * Naive problem   — the failure mode as described in the video.
  * Real-world mode — how it actually bites in production harnesses.
  * Hardened fix    — the deterministic mechanism that prevents it.

For each tip the dashboard ships an executable LLM prompt, a systemic
explanation, and a citation to official docs, arXiv, or an ISBN-backed text.

The app is static-first: every feature works as a client-side React page. The
optional Docker backend adds an authoritative server-side policy engine and
real server-side SHA-256 handoff validation.

ARCHITECTURE
--------------------------------------------------------------------------------
  Browser (React 18 + Vite 5)
     | probe /api/health (2.5 s timeout)
     +--> online  : Docker backend :8081 — /api/health, /api/hooks/evaluate,
     |              /api/handoff/validate, serves dist/
     +--> offline : static mode — client-side mirror of the policy table,
                    Web Crypto SHA-256, banner "static mode — limited"

The Pages deployment is HTTPS. Browsers block HTTPS -> http://localhost as
mixed content, so the Pages site always runs in static mode. This is expected
and surfaced in the UI, not hidden.

THE 11 AUDITED FAILURE MODES
--------------------------------------------------------------------------------
  #   Tip                                          Hardened mechanism
  --  -------------------------------------------  ------------------------------------------
  1   Premature completion / self-attestation       Isolated adversarial reviewer agent
  2   Attestation without runtime evidence          Mandatory STDOUT + DOM artifact capture
  3   Passing mock tests on broken apps             Real browser E2E via xvfb runners
  4   Probabilistic rule non-compliance             Deterministic PreToolUse hooks (exit 1/2)
  5   Global context bloat                         CI token gate (<500 tokens)
  6   Context rot / autoregressive drift           Schema-validated HANDOFF.md + SHA-256
  7   Loss of developer control                    Explicit human-in-the-loop approval gates
  8   Verbose overshooting                         Diff-bounding hooks (max 2 files)
  9   Sub-agent token sprawl                       Depth limit 1, max 2 concurrent workers
  10  Over-testing basic changes                   Blast-radius tiering (LOW/MED/HIGH)
  11  Tangential task chasing                      NOTICES.md out-of-scope queue

QUICK START — ONE-SHOT
--------------------------------------------------------------------------------
Prerequisites: bash, git, Node 18+, npm, curl. Optional: Docker, GitHub CLI
(`gh`) authenticated via `gh auth login`.

    chmod +x 00-one-shot.sh
    ./00-one-shot.sh

Environment overrides:

    TARGET_DIR=/path/to/repo     REPO_NAME=my-explainer
    HARNESS_PORT=8081            PREVIEW_PORT=4173
    LOG=/tmp/one-shot.log

MANUAL SETUP (NO SCRIPT)
--------------------------------------------------------------------------------
    npm install
    npm run dev          # http://localhost:3000
    npm run build        # dist/
    npm run preview      # http://localhost:4173
    npm run check-context

DOCKER BACKEND
--------------------------------------------------------------------------------
    docker compose build
    docker compose up -d

    curl http://localhost:8081/api/health
    # {"backend":"ok","mode":"full","service":"hardened-agent-harness",
    #  "version":"2.1.0","policyRules":2}

    open http://localhost:8081/

The runtime image contains only node:20-alpine, dist/, and server/. The server
has zero npm dependencies.

API:

  GET  /api/health
  POST /api/hooks/evaluate    { "path": ".env" }
  POST /api/handoff/validate  { "markdown": "# HANDOFF STATE ..." }

GITHUB PAGES DEPLOYMENT
--------------------------------------------------------------------------------
The one-shot script does this automatically. Manual equivalent:

    git init -b main
    git add -A
    git commit -m "feat: hardened agent harness explainer"
    gh repo create <owner>/<repo> --public --source=. --remote=origin --push
    gh api -X POST "repos/<owner>/<repo>/pages" -f build_type=workflow
    gh api "repos/<owner>/<repo>/pages" --jq '.html_url'

A 409 on the Pages POST means Pages already exists — treated as success.
A 422 on a repo already publishing from a branch is expected; the workflow's
configure-pages@v5 step is the fallback enabler.

GRACEFUL DEGRADATION CONTRACT
--------------------------------------------------------------------------------
  Condition                          Behaviour
  ---------------------------------  ------------------------------------------
  Docker available                   Backend built and started; UI shows
                                     "server policy engine".
  Docker missing / build fails       Warn + continue; Pages and local preview
                                     still built; UI shows "static mode —
                                     limited"; hook simulator and handoff
                                     validator use client-side mirrors.
  gh CLI missing / not authenticated Warn + skip repo creation and Pages;
                                     local preview is opened instead.
  Pages API 409                     Treated as success.
  Pages API 422                     Warn; rely on configure-pages@v5.
  Pages HTTP not 200 within 120 s   Warn; print html_url and troubleshooting
                                     command; open it anyway.
  All remote paths fail              Local `vite preview` on :4173 is opened.

Exit code is always 0. Read the summary block for ISSUES.

TROUBLESHOOTING
--------------------------------------------------------------------------------
  Pages 404 after deploy
      CDN propagation can take 30–90 s. If it still 404s:
      gh api repos/<owner>/<repo>/pages --jq .build_type  must return "workflow".
      gh run list -R <owner>/<repo>  to inspect the workflow run.

  Assets 404 on Pages but 200 locally
      `base` is wrong. vite.config.js derives it from GITHUB_REPOSITORY or
      VITE_BASE; verify the workflow sets VITE_BASE.

  History expansion on `!`
      00-one-shot.sh starts with `set +H` and every heredoc is quoted.
      If pasting blocks interactively, prepend `set +H`.

  emit() reports "empty or missing"
      Directory not writable, or the heredoc delimiter was typo'd so it
      swallowed the rest of the block.

  Docker healthcheck unhealthy
      docker compose logs harness-backend
      The healthcheck calls wget -qO- http://127.0.0.1:8081/api/health.

FILE MAP
--------------------------------------------------------------------------------
  package.json                     Vite + React 18 + lucide-react
  vite.config.js                   base from GITHUB_REPOSITORY / VITE_BASE
  index.html                       dark-theme root
  src/main.jsx                     ReactDOM root
  src/App.jsx                      3-tab shell + backend probe
  src/data/tipsData.js             11 tips
  src/utils/api.js                 probeBackend, evaluateHookRemote/Local
  src/utils/handoffValidator.js    SHA-256 (Web Crypto) + schema check
  src/components/AuditCard.jsx     3-column failure card
  src/components/PromptTable.jsx   prompt + citation matrix
  src/components/BackendBadge.jsx  online / static / probing badge
  src/components/HookSimulator.jsx exit-code simulator
  scripts/enforce-context-gate.js  advisory 500-token audit
  server/index.js                  zero-dependency API + static SPA server
  Dockerfile                       multi-stage; runtime has no npm deps
  docker-compose.yml               port ${HARNESS_PORT:-8081}
  .github/workflows/deploy.yml     Pages workflow
FILE_EOF

# ===========================================================================
step "3. Verify emitted tree"
# ===========================================================================
COUNT=$(find . -type f -not -path './.git/*' -not -path './node_modules/*' -not -path './dist/*' | wc -l)
ok "files under $TARGET_DIR (excluding .git/node_modules/dist): $COUNT"
find . -type f -not -path './.git/*' -not -path './node_modules/*' -not -path './dist/*' | sort

# ===========================================================================
step "4. npm install + vite build"
# ===========================================================================
if command -v node >/dev/null 2>&1; then
  NODE_MAJOR=$(node -v | cut -c2- | cut -d. -f1)
  if [ "${NODE_MAJOR:-0}" -lt 18 ]; then
    err "Node $(node -v) is too old — need >= 18"
  else
    ok "Node $(node -v)"
  fi
else
  err "node not found — install Node 18+ and re-run"
fi

if command -v npm >/dev/null 2>&1 && [ -f package.json ]; then
  npm install --no-audit --no-fund >"$TMP/npm-install.log" 2>&1
  if [ "$?" -eq 0 ]; then
    ok "npm install"
  else
    err "npm install failed — see $TMP/npm-install.log"
    tail -n 15 "$TMP/npm-install.log" | tee -a "$LOG"
  fi

  npm run build >"$TMP/vite-build.log" 2>&1
  if [ "$?" -eq 0 ] && [ -f dist/index.html ]; then
    ok "vite build (dist/ ready)"
  else
    err "vite build failed — see $TMP/vite-build.log"
    tail -n 20 "$TMP/vite-build.log" | tee -a "$LOG"
  fi
fi

# ===========================================================================
step "5. Docker backend (optional)"
# ===========================================================================
DOCKER_OK="no"
if command -v docker >/dev/null 2>&1; then
  docker info >"$TMP/docker-info.log" 2>&1
  if [ "$?" -eq 0 ]; then
    DOCKER_OK="yes"
    ok "docker available"
  else
    warn "docker CLI present but daemon unreachable — backend skipped"
  fi
else
  warn "docker not found — backend skipped (static mode remains fully usable)"
fi

if [ "$DOCKER_OK" = "yes" ] && [ -f docker-compose.yml ]; then
  docker compose build >"$TMP/docker-build.log" 2>&1
  if [ "$?" -eq 0 ]; then
    ok "docker compose build"
  else
    err "docker compose build failed — see $TMP/docker-build.log"
    tail -n 20 "$TMP/docker-build.log" | tee -a "$LOG"
    DOCKER_OK="no"
  fi
fi

if [ "$DOCKER_OK" = "yes" ] && [ -f docker-compose.yml ]; then
  docker compose up -d >"$TMP/docker-up.log" 2>&1
  if [ "$?" -eq 0 ]; then
    ok "docker compose up -d"
    WAIT=0
    while [ "$WAIT" -lt 30 ]; do
      curl -fsS --max-time 3 "http://localhost:${HARNESS_PORT}/api/health" >"$TMP/health.json" 2>"$TMP/health.err"
      if [ "$?" -eq 0 ]; then break; fi
      sleep 1
      WAIT=$((WAIT + 1))
    done
    if [ "$WAIT" -lt 30 ]; then
      ok "backend healthy after ${WAIT}s"
      note "  $(cat "$TMP/health.json")"
    else
      warn "backend did not become healthy within 30 s"
      docker compose logs --tail=20 harness-backend | tee -a "$LOG"
    fi
  else
    err "docker compose up failed — see $TMP/docker-up.log"
    tail -n 20 "$TMP/docker-up.log" | tee -a "$LOG"
    DOCKER_OK="no"
  fi
fi

# ===========================================================================
step "6. GitHub repo + Pages"
# ===========================================================================
GH_OK="no"
if command -v gh >/dev/null 2>&1; then
  gh auth status >"$TMP/gh-auth.log" 2>&1
  if [ "$?" -eq 0 ]; then
    GH_OK="yes"
    GH_OWNER=$(gh api user --jq '.login' 2>"$TMP/gh-owner.err")
    ok "gh authenticated as $GH_OWNER"
  else
    warn "gh installed but not authenticated — run: gh auth login"
  fi
else
  warn "gh CLI not found — remote creation skipped"
fi

PAGES_URL=""
PAGES_VERIFIED="no"
PAGES_RC="1"

if [ "$GH_OK" = "yes" ]; then
  if [ ! -d .git ]; then
    git init -b main >"$TMP/git-init.log" 2>&1
    if [ "$?" -eq 0 ]; then ok "git init -b main"; else err "git init failed"; GH_OK="no"; fi
  fi
fi

if [ "$GH_OK" = "yes" ]; then
  git add -A >"$TMP/git-add.log" 2>&1
  git -c user.name="${GIT_AUTHOR_NAME:-harness}" \
      -c user.email="${GIT_AUTHOR_EMAIL:-harness@localhost}" \
      commit -m "feat: hardened agent harness explainer v2.1.0" >"$TMP/git-commit.log" 2>&1
  COMMIT_RC=$?
  if [ "$COMMIT_RC" -eq 0 ]; then
    ok "git commit"
  elif grep -qi "nothing to commit" "$TMP/git-commit.log"; then
    ok "git commit (nothing to commit)"
  else
    warn "git commit rc=$COMMIT_RC"
  fi

  if gh repo view "$GH_OWNER/$REPO_NAME" >"$TMP/gh-view.log" 2>&1; then
    ok "remote exists: $GH_OWNER/$REPO_NAME"
    git remote get-url origin >"$TMP/git-remote.log" 2>&1
    if [ "$?" -ne 0 ]; then
      git remote add origin "https://github.com/$GH_OWNER/$REPO_NAME.git" >"$TMP/git-remote-add.log" 2>&1
    fi
    git push -u origin main >"$TMP/git-push.log" 2>&1
    if [ "$?" -eq 0 ]; then ok "git push"; else err "git push failed — see $TMP/git-push.log"; tail -n 10 "$TMP/git-push.log" | tee -a "$LOG"; fi
  else
    gh repo create "$GH_OWNER/$REPO_NAME" --public --source=. --remote=origin --push >"$TMP/gh-create.log" 2>&1
    if [ "$?" -eq 0 ]; then
      ok "gh repo create + push"
    else
      err "gh repo create failed — see $TMP/gh-create.log"
      tail -n 15 "$TMP/gh-create.log" | tee -a "$LOG"
      GH_OK="no"
    fi
  fi
fi

if [ "$GH_OK" = "yes" ]; then
  gh api -X POST "repos/$GH_OWNER/$REPO_NAME/pages" -f build_type=workflow >"$TMP/pages.json" 2>"$TMP/pages.err"
  PAGES_RC=$?
  if [ "$PAGES_RC" -eq 0 ]; then
    ok "Pages enabled (build_type=workflow)"
  else
    PAGES_ERR="$(cat "$TMP/pages.err")"
    case "$PAGES_ERR" in
      *409*) ok "Pages already exists (409) — treating as success"; PAGES_RC=0 ;;
      *422*) warn "Pages API 422 — relying on configure-pages@v5 in the workflow"; PAGES_RC=0 ;;
      *) err "Pages API failed (rc=$PAGES_RC): $PAGES_ERR" ;;
    esac
  fi
fi

if [ "$GH_OK" = "yes" ] && [ "$PAGES_RC" -eq 0 ]; then
  RUN_WAIT=0
  while [ "$RUN_WAIT" -lt 90 ]; do
    RUN_ID=$(gh run list -R "$GH_OWNER/$REPO_NAME" --workflow=deploy.yml --limit 1 --json databaseId --jq '.[0].databaseId' 2>"$TMP/gh-run.err")
    if [ -n "$RUN_ID" ] && [ "$RUN_ID" != "null" ]; then
      STATUS=$(gh run view "$RUN_ID" -R "$GH_OWNER/$REPO_NAME" --json status --jq '.status' 2>"$TMP/gh-status.err")
      if [ "$STATUS" = "completed" ]; then
        CONCL=$(gh run view "$RUN_ID" -R "$GH_OWNER/$REPO_NAME" --json conclusion --jq '.conclusion' 2>"$TMP/gh-concl.err")
        if [ "$CONCL" = "success" ]; then ok "Pages workflow $RUN_ID succeeded"; else warn "Pages workflow $RUN_ID concluded: $CONCL"; fi
        break
      fi
    fi
    sleep 5
    RUN_WAIT=$((RUN_WAIT + 5))
  done

  PAGES_URL="https://${GH_OWNER}.github.io/${REPO_NAME}/"
  note "  Pages URL: $PAGES_URL"
  HTTP_WAIT=0
  LAST_CODE="unknown"
  while [ "$HTTP_WAIT" -lt 120 ]; do
    LAST_CODE=$(curl -s -o "$TMP/pages.html" -w '%{http_code}' --max-time 10 "$PAGES_URL" 2>"$TMP/curl-pages.err")
    if [ "$LAST_CODE" = "200" ]; then PAGES_VERIFIED="yes"; break; fi
    sleep 5
    HTTP_WAIT=$((HTTP_WAIT + 5))
  done
  if [ "$PAGES_VERIFIED" = "yes" ]; then
    ok "Pages live: $PAGES_URL (HTTP 200 after ${HTTP_WAIT}s)"
  else
    warn "Pages not 200 within 120 s (last code: $LAST_CODE)"
    note "  gh api repos/$GH_OWNER/$REPO_NAME/pages --jq .build_type"
    note "  gh run list -R $GH_OWNER/$REPO_NAME"
  fi
fi

# ===========================================================================
step "7. Open best available target"
# ===========================================================================
OPEN_URL=""
OPEN_LABEL=""

if [ "$PAGES_VERIFIED" = "yes" ] && [ -n "$PAGES_URL" ]; then
  OPEN_URL="$PAGES_URL"; OPEN_LABEL="GitHub Pages (HTTP 200 verified)"
elif [ "$DOCKER_OK" = "yes" ]; then
  OPEN_URL="http://localhost:${HARNESS_PORT}/"; OPEN_LABEL="local Docker backend"
elif [ -f dist/index.html ]; then
  nohup npx --yes vite preview --port "$PREVIEW_PORT" >"$TMP/preview.log" 2>&1 &
  PREVIEW_WAIT=0
  while [ "$PREVIEW_WAIT" -lt 20 ]; do
    curl -fsS --max-time 2 "http://localhost:${PREVIEW_PORT}/" >"$TMP/preview.html" 2>"$TMP/preview.err"
    if [ "$?" -eq 0 ]; then break; fi
    sleep 1
    PREVIEW_WAIT=$((PREVIEW_WAIT + 1))
  done
  if [ "$PREVIEW_WAIT" -lt 20 ]; then
    OPEN_URL="http://localhost:${PREVIEW_PORT}/"; OPEN_LABEL="local vite preview (static mode — limited)"
  else
    err "vite preview did not start within 20 s — see $TMP/preview.log"
  fi
else
  err "nothing to open — no Pages, no Docker, no dist/"
fi

if [ -n "$OPEN_URL" ]; then
  note "  Opening: $OPEN_LABEL"
  note "  $OPEN_URL"
  if command -v xdg-open >/dev/null 2>&1; then xdg-open "$OPEN_URL" >"$TMP/open.log" 2>&1 &
  elif command -v open >/dev/null 2>&1; then open "$OPEN_URL" >"$TMP/open.log" 2>&1 &
  else warn "no xdg-open / open — open the URL manually"
  fi
fi

# ===========================================================================
step "Summary"
# ===========================================================================
echo ""
echo "  Repo root : $TARGET_DIR"
if [ "$DOCKER_OK" = "yes" ]; then
  echo "  Backend   : docker :${HARNESS_PORT} (full mode)"
else
  echo "  Backend   : not running (static mode — limited)"
fi
if [ "$PAGES_VERIFIED" = "yes" ]; then
  echo "  Pages     : $PAGES_URL (HTTP 200)"
else
  echo "  Pages     : ${PAGES_URL:-not deployed} (unverified)"
fi
echo "  Open URL  : ${OPEN_URL:-none}"
echo ""
if [ "$ISSUES" -eq 0 ]; then
  echo "🎉 One-shot completed with no recorded issues"
else
  echo "🔥 One-shot completed with $ISSUES issue(s) — see lines marked ❌"
fi
echo ""
echo "  Logs: $LOG"
echo "  Tmp : $TMP"

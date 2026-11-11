HARDENED LLM AGENT HARNESS — EXPLAINER & AUDIT DASHBOARD
Version 3.0.2
================================================================================

TL;DR
--------------------------------------------------------------------------------
    chmod +x 00-one-shot.sh
    ./00-one-shot.sh

Converges idempotently. Preflight gate -> file lock -> emit -> verify -> build
-> Docker -> GitHub -> Pages -> open. Never aborts on a single failure; prints
a summary-first result. Exit code is always 0.

WHAT CHANGED IN 3.0.2
--------------------------------------------------------------------------------
  - Preflight gate: Docker daemon, compose syntax, port ownership, git state,
    node/npm versions, gh auth. No mutation before the gate passes.
  - Same-stack port warning vs foreign-process hard failure.
  - File lock (flock, mkdir fallback) prevents concurrent runs.
  - DRY_RUN=1 prints the plan without mutating.
  - Target-side marker .one-shot-state.json records the last successful SHA.
  - Summary is printed first: cd <repo>, then verified URLs.
  - Hook wrapper demonstrates the background-stdout redirect contract.
  - Workflow accepts an explicit deploy_sha input for dispatch replay.
  - public/.nojekyll is emitted to stop Jekyll eating underscore assets.

RE-RUN BEHAVIOUR
--------------------------------------------------------------------------------
  Stage            Guard
  ---------------  ---------------------------------------------------------
  preflight        gate before any mkdir/emit/install
  lock             flock -n or mkdir fallback
  target dir       does not nest inside a directory of the same name
  emit()           deterministic overwrite; every file is canonical
  git init         skipped if .git already exists
  git remote add   skipped if origin is already configured
  git commit       "nothing to commit" is success
  gh repo create   skipped if gh repo view succeeds; "already exists" = success
  Pages POST       409 (exists) and 422 (branch-published) = success
  workflow poll    matched to the current HEAD SHA, not an old run
  docker build     layer cache; up -d --force-recreate is idempotent
  npm install      lockfile-stable; repeated runs converge

HOOK CONTRACT (corrected)
--------------------------------------------------------------------------------
Official Claude Code hooks reference, not folklore:

  exit 0  allow (or JSON permissionDecision on stdout)
  exit 2  block; stderr is fed back to the model as feedback
  exit 1  NON-BLOCKING error; stderr goes to the user, NOT to the model

A policy hook that exits 1 expecting to block does not block. Exit 2 is the
only reliable block through exit codes. The finer-grained path is exit 0 with
JSON:

  {"hookSpecificOutput": {"hookEventName": "PreToolUse",
                          "permissionDecision": "deny"|"allow"|"ask",
                          "permissionDecisionReason": "..."}}

onFailure:"block" (Claude Code v2.1.295+) makes a crashed or timed-out hook
fail closed instead of letting the tool call through. The wrapper also
redirects background stdout/stderr so a metrics upload cannot keep the hook's
pipe open and turn an allow into a block.

THREE CONSUMERS, ONE POLICY
--------------------------------------------------------------------------------
  public/hook_policy.json
        |
        +--> scripts/hook_runner.py   (Claude Code PreToolUse, authoritative)
        +--> server/index.js          (Docker /api/hooks/evaluate)
        +--> src/utils/api.js         (browser fetch; fallback embedded)

Edit the policy once. The Python hook, the server, and the UI all read it.

PREFLIGHT GATE
--------------------------------------------------------------------------------
Run before any mutation. A failing gate prints the exact fix and exits without
touching the system.

  Check                 Behaviour on failure
  --------------------  ----------------------------------------------------
  bash / git / node     hard fail
  node < 18             hard fail
  npm / curl            hard fail
  python3               warn (hook verification skipped)
  docker daemon         warn (backend skipped; static mode remains)
  docker compose config hard fail if compose file exists and is invalid
  port HARNESS_PORT     warn if held by this stack ("will be replaced")
                        hard fail if held by a foreign process
  gh auth               warn (remote skipped)

HOOK RUNNER
--------------------------------------------------------------------------------
    python3 scripts/hook_runner.py --self-test
    echo '{"tool_name":"Read","tool_input":{"file_path":".env"}}' \
      | python3 scripts/hook_runner.py --json
    echo '{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}' \
      | python3 scripts/hook_runner.py --exit-code

Flags:

  --json        print hookSpecificOutput JSON and exit 0 (default)
  --exit-code   use exit-code contract (0 allow / 2 deny)
  --policy PATH explicit policy file
  --self-test   run built-in assertions (.env deny, src/App.jsx allow, rm -rf / deny)

External checks (rule.check.argv) run through Popen with
start_new_session=True. On timeout the process group is SIGTERM'd, then
SIGKILL'd after a 2 s grace. subprocess.run is never used: it kills only the
direct child and leaves grandchildren holding the pipes open.

.claude/settings.json uses exec form (command + args) and onFailure:"block".
The wrapper scripts/hook_entry.sh runs the Python runner and propagates its
exit code with `|| exit $?`, then starts any background telemetry with
stdout/stderr redirected.

WORKFLOW SHA PINNING
--------------------------------------------------------------------------------
The workflow currently uses version tags for readability. For production,
pin every `uses:` to a full 40-char commit SHA. Resolve a tag to a SHA with:

    gh api repos/actions/checkout/git/ref/tags/v4 --jq '.object.sha'

Then replace `actions/checkout@v4` with
`actions/checkout@<40-char-sha>`. Do the same for setup-node, configure-pages,
upload-pages-artifact, and deploy-pages. Tags are mutable; SHAs are not.

DISPATCH REPLAY
--------------------------------------------------------------------------------
The workflow accepts an optional deploy_sha input. A dispatch run checks out
that SHA instead of the default-branch tip:

    gh workflow run deploy.yml -f deploy_sha="$(git rev-parse HEAD)"

This makes dispatch replay deterministic and auditable.

ARCHITECTURE
--------------------------------------------------------------------------------
  Browser (React 18 + Vite 5)
     | probe /api/health (2.5 s timeout)
     +--> online  : Docker backend :8081 — /api/health, /api/hooks/evaluate,
     |              /api/handoff/validate, serves dist/
     +--> offline : static mode — policy fetched from /hook_policy.json,
                    Web Crypto SHA-256, banner "static mode — limited"

Claude Code
     |
     +--> PreToolUse hook -> bash scripts/hook_entry.sh
            -> python3 scripts/hook_runner.py --json
            reads public/hook_policy.json, emits permissionDecision

The Pages deployment is HTTPS. Browsers block HTTPS -> http://localhost as
mixed content, so the Pages site always runs in static mode. The Docker backend
is the only path to server-authoritative evaluation.

THE 11 AUDITED FAILURE MODES
--------------------------------------------------------------------------------
  #   Tip                                          Hardened mechanism
  --  -------------------------------------------  ------------------------------------------
  1   Premature completion / self-attestation       Isolated adversarial reviewer agent
  2   Attestation without runtime evidence          Mandatory STDOUT + DOM artifact capture
  3   Passing mock tests on broken apps             Real browser E2E via xvfb runners
  4   Probabilistic rule non-compliance             PreToolUse hooks: exit 2 or JSON deny
  5   Global context bloat                         CI token gate (<500 tokens)
  6   Context rot / autoregressive drift           Schema-validated HANDOFF.md + SHA-256
  7   Loss of developer control                    Explicit human-in-the-loop approval gates
  8   Verbose overshooting                         Diff-bounding hooks (max 2 files)
  9   Sub-agent token sprawl                       Depth limit 1, max 2 concurrent workers
  10  Over-testing basic changes                   Blast-radius tiering (LOW/MED/HIGH)
  11  Tangential task chasing                      NOTICES.md out-of-scope queue

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
    #  "version":"3.0.2","policyRules":5,"policySource":"server-fetched"}

    open http://localhost:8081/

API:

  GET  /api/health
  POST /api/hooks/evaluate    { "tool": "Read", "path": ".env" }
  POST /api/handoff/validate  { "markdown": "# HANDOFF STATE ..." }

GITHUB PAGES DEPLOYMENT
--------------------------------------------------------------------------------
Manual equivalent of the one-shot:

    git init -b main
    git add -A
    git commit -m "feat: hardened agent harness explainer"
    gh repo create <owner>/<repo> --public --source=. --remote=origin --push
    gh api -X POST "repos/<owner>/<repo>/pages" -f build_type=workflow
    gh api "repos/<owner>/<repo>/pages" --jq '.html_url'

A 409 on the Pages POST means Pages already exists — treated as success. A 422
on a repo already publishing from a branch is expected; configure-pages@v5 in
the workflow is the fallback enabler.

GRACEFUL DEGRADATION CONTRACT
--------------------------------------------------------------------------------
  Condition                          Behaviour
  ---------------------------------  ------------------------------------------
  Docker available                   Backend built and started; UI shows
                                     "server policy engine".
  Docker missing / build fails       Warn + continue; Pages and local preview
                                     still built; UI shows "static mode —
                                     limited"; hook simulator uses the fetched
                                     policy, then the embedded fallback.
  python3 missing                    Hook runner self-test skipped; the repo
                                     still builds and deploys. Hooks do not
                                     run until python3 is installed.
  gh CLI missing / not authenticated Warn + skip repo creation and Pages;
                                     local preview is opened instead.
  Pages API 409 / 422               Treated as success.
  Pages HTTP not 200 within 120 s   Warn; print html_url and the troubleshooting
                                     command; open it anyway.
  All remote paths fail              Local `vite preview` on :4173 is opened.

Exit code is always 0. Read the summary block for ISSUES.

TROUBLESHOOTING
--------------------------------------------------------------------------------
  Hook blocks nothing / every tool call proceeds
      The hook is probably exiting 1. Exit 1 is non-blocking. Exit 2, or exit 0
      with permissionDecision:"deny". Check with:
        python3 scripts/hook_runner.py --self-test

  Hook fails open on crash
      onFailure:"block" requires Claude Code v2.1.295+. Check the version;
      older versions let a crashed hook through.

  Pages 404 after deploy
      CDN propagation can take 30–90 s. If it still 404s:
      gh api repos/<owner>/<repo>/pages --jq .build_type  must return "workflow".
      gh run list -R <owner>/<repo>  to inspect the workflow run.

  Assets 404 on Pages but 200 locally
      base is wrong. vite.config.js derives it from GITHUB_REPOSITORY or
      VITE_BASE; verify the workflow sets VITE_BASE. Also check public/.nojekyll
      is present.

  Re-run nests the repo
      Fixed: if the current directory is already named hardened-agent-harness,
      TARGET_DIR defaults to it instead of creating a child.

  Re-run re-creates the remote or fails on "already exists"
      Fixed: gh repo view is checked first; "already exists" is treated as
      success. git remote add is guarded by git remote get-url origin.

  Port 8081 held by a foreign process
      Preflight hard-fails. Stop the process or set HARNESS_PORT=8082.
      A port held by this stack is a warning ("will be replaced").

  Concurrent one-shot runs
      File lock prevents it. Lock path: /tmp/harness-one-shot.lock (flock) or
      /tmp/harness-one-shot.lock.d (mkdir fallback). Remove stale locks only
      after confirming no run is active.

FILE MAP
--------------------------------------------------------------------------------
  package.json                     Vite + React 18 + lucide-react
  vite.config.js                   base from GITHUB_REPOSITORY / VITE_BASE
  index.html                       dark-theme root
  src/main.jsx                     ReactDOM root
  src/App.jsx                      3-tab shell + backend probe + policy fetch
  src/data/tipsData.js             11 tips (Tip 4 corrected)
  src/utils/api.js                 probeBackend, loadPolicy, evaluateHookLocal
  src/utils/policyFallback.js      embedded fallback (two critical rules)
  src/utils/handoffValidator.js    SHA-256 (Web Crypto) + schema check
  src/components/AuditCard.jsx     3-column failure card
  src/components/PromptTable.jsx   prompt + citation matrix
  src/components/BackendBadge.jsx  online / static / probing badge
  src/components/HookSimulator.jsx tool selector + policy evaluation
  public/hook_policy.json          single source of truth (5 rules)
  public/.nojekyll                 stop Jekyll eating underscore assets
  scripts/hook_runner.py           PreToolUse runner (Popen, process-group kill)
  scripts/hook_entry.sh            wrapper: propagate exit, redirect background
  scripts/upload_metrics.sh        silent telemetry placeholder
  scripts/enforce-context-gate.js  advisory 500-token audit
  .claude/settings.json            PreToolUse wiring + onFailure:"block"
  server/index.js                  zero-dependency API + static SPA server
  Dockerfile                       multi-stage; runtime has no npm deps
  docker-compose.yml               port ${HARNESS_PORT:-8081}
  .github/workflows/deploy.yml     Pages workflow + dispatch SHA input

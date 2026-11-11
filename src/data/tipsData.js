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
    solution: "Convert critical natural language constraints into deterministic PreToolUse hooks with the correct exit-code contract.",
    failureMode: "A policy hook exits 1 expecting to block; Claude Code treats exit 1 as a non-blocking error and the tool call proceeds.",
    hardenedFix: "Hooks exit 2 to block (stderr fed back) or exit 0 with permissionDecision:\"deny\" JSON; onFailure:\"block\" makes crashes fail closed.",
    promptName: "Hook Guardrail Extraction Prompt",
    prompt: "Analyze the repository rules file. Extract every MUST/NEVER statement (secret reads, bun vs npm enforcement, destructive commands). Emit PreToolUse hooks that block with exit 2 and stderr, or exit 0 with hookSpecificOutput.permissionDecision:\"deny\" and a permissionDecisionReason. Set onFailure:\"block\" on every hook.",
    explanation: "Replaces probabilistic natural-language compliance with deterministic process interception and a fail-closed crash policy.",
    citations: [
      { text: "Claude Code Hooks reference — exit codes and onFailure", url: "https://code.claude.com/docs/en/hooks" },
      { text: "Claude Code v2.1.295 release — onFailure:\"block\"", url: "https://code.claude.com/docs/en/changelog" }
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

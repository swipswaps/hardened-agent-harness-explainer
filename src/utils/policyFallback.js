// Embedded fallback used only when public/hook_policy.json cannot be fetched.
// The shared policy file is the single source of truth for the Python hook,
// the Node server, and the browser.
export const FALLBACK_RULES = [
  {
    id: 'env-secret-read',
    description: 'Block reads/writes/edits of .env files and secrets/ directories',
    tools: ['Read', 'Write', 'Edit', 'MultiEdit', 'Bash'],
    path_regex: '(^|/)\\.env(\\.|$)|(^|/)secrets?/',
    decision: 'deny',
    reason: 'Access to sensitive path "{path}" is prohibited. Use an environment variable mock injected via the test harness instead.'
  },
  {
    id: 'system-config-write',
    description: 'Block edits to system core configuration',
    tools: ['Write', 'Edit', 'MultiEdit', 'Bash'],
    path_regex: 'config\\.system$',
    decision: 'deny',
    reason: 'Modification of system core configuration "{path}" requires human escalation.'
  }
];

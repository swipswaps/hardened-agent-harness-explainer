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

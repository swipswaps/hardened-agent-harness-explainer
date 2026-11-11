import React, { useEffect, useState } from 'react';
import { tipsData } from './data/tipsData.js';
import AuditCard from './components/AuditCard.jsx';
import PromptTable from './components/PromptTable.jsx';
import HookSimulator from './components/HookSimulator.jsx';
import BackendBadge from './components/BackendBadge.jsx';
import { validateHandoffStateLocal, validateHandoffStateRemote } from './utils/handoffValidator.js';
import { probeBackend, loadPolicy } from './utils/api.js';
import { FALLBACK_RULES } from './utils/policyFallback.js';
import { Cpu, Layers, BookOpen, ShieldCheck, FileCheck } from 'lucide-react';

const API_BASE = (import.meta && import.meta.env && import.meta.env.VITE_API_BASE) || '';
const BASE_URL = (import.meta && import.meta.env && import.meta.env.BASE_URL) || '/';

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
  const [policy, setPolicy] = useState({ rules: FALLBACK_RULES, source: 'client-embedded' });
  const [sampleHandoff, setSampleHandoff] = useState(SAMPLE_HANDOFF);
  const [validationResult, setValidationResult] = useState(null);
  const [validating, setValidating] = useState(false);

  useEffect(() => {
    let alive = true;
    probeBackend(API_BASE).then((r) => { if (alive) setBackend({ ...r, probing: false }); });
    loadPolicy(BASE_URL).then((p) => { if (alive) setPolicy(p); });
    return () => { alive = false; };
  }, []);

  const handleValidateHandoff = async () => {
    setValidating(true);
    try {
      if (backend.online) {
        try {
          setValidationResult(await validateHandoffStateRemote(API_BASE, sampleHandoff));
          return;
        } catch (e) { /* fall through */ }
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
            <HookSimulator apiBase={API_BASE} backend={backend} rules={policy.rules} policySource={policy.source} />
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

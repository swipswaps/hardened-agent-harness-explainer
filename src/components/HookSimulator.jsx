import React, { useState } from 'react';
import { Play, CheckCircle2, AlertTriangle, XCircle, Terminal } from 'lucide-react';
import { evaluateHookLocal, evaluateHookRemote } from '../utils/api.js';

const TOOLS = ['Read', 'Write', 'Edit', 'Bash'];

export default function HookSimulator({ apiBase = '', backend, rules, policySource }) {
  const [tool, setTool] = useState('Read');
  const [target, setTarget] = useState('.env');
  const [outputLog, setOutputLog] = useState(null);
  const [busy, setBusy] = useState(false);

  const simulateHook = async () => {
    setBusy(true);
    try {
      const payload = tool === 'Bash'
        ? { tool, command: target }
        : { tool, path: target };
      if (backend && backend.online) {
        setOutputLog(await evaluateHookRemote(apiBase, payload));
      } else {
        setOutputLog(evaluateHookLocal(payload, rules, policySource));
      }
    } catch (e) {
      const payload = tool === 'Bash'
        ? { tool, command: target }
        : { tool, path: target };
      const local = evaluateHookLocal(payload, rules, policySource);
      setOutputLog({ ...local, stderr: local.stderr + '\n[remote fallback] ' + String((e && e.message) || e) });
    } finally {
      setBusy(false);
    }
  };

  const inputStyle = {
    backgroundColor: '#0f172a', border: '1px solid #334155',
    padding: '8px 12px', borderRadius: '6px', color: '#f8fafc',
    fontFamily: 'monospace'
  };

  return (
    <div style={{ backgroundColor: '#1e293b', padding: '20px', borderRadius: '8px', border: '1px solid #334155', marginTop: '24px' }}>
      <h3 style={{ color: '#38bdf8', fontSize: '1.1rem', marginBottom: '8px', display: 'flex', alignItems: 'center', gap: '8px' }}>
        <Terminal size={18} /> PreToolUse Hook Simulator
      </h3>
      <p style={{ color: '#94a3b8', fontSize: '0.85rem', marginBottom: '16px' }}>
        {backend && backend.online
          ? 'Evaluating against the authoritative server-side policy engine.'
          : 'Client-side policy (' + policySource + '). Exit 2 blocks; exit 0 allows. Start the Docker backend for authoritative evaluation.'}
      </p>

      <div style={{ display: 'flex', gap: '12px', marginBottom: '16px', flexWrap: 'wrap' }}>
        <select value={tool} onChange={(e) => setTool(e.target.value)} style={{ ...inputStyle, minWidth: '110px' }}>
          {TOOLS.map((t) => <option key={t} value={t}>{t}</option>)}
        </select>
        <input
          type="text"
          value={target}
          onChange={(e) => setTarget(e.target.value)}
          placeholder={tool === 'Bash' ? 'Command (e.g. rm -rf /)' : 'Path (e.g. .env, src/App.jsx)'}
          style={{ ...inputStyle, flex: 1, minWidth: '240px' }}
        />
        <button onClick={simulateHook} disabled={busy}
          style={{ backgroundColor: busy ? '#334155' : '#0284c7', color: '#ffffff', border: 'none', padding: '8px 16px', borderRadius: '6px', cursor: busy ? 'wait' : 'pointer', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '6px' }}>
          <Play size={16} /> {busy ? 'Evaluating…' : 'Evaluate'}
        </button>
      </div>

      {outputLog && (
        <div style={{ backgroundColor: '#0f172a', padding: '16px', borderRadius: '6px', borderLeft: '4px solid ' + (outputLog.color || '#64748b') }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px', flexWrap: 'wrap', gap: '6px' }}>
            <span style={{ fontWeight: 'bold', color: outputLog.color, display: 'flex', alignItems: 'center', gap: '6px' }}>
              {outputLog.exitCode === 0 && <CheckCircle2 size={16} />}
              {outputLog.exitCode === 1 && <AlertTriangle size={16} />}
              {outputLog.exitCode === 2 && <XCircle size={16} />}
              {outputLog.status}
            </span>
            <span style={{ fontSize: '0.8rem', color: '#64748b', fontFamily: 'monospace' }}>
              Exit {outputLog.exitCode} · {outputLog.policySource || 'client'}
              {outputLog.matchedRule ? ' · ' + outputLog.matchedRule : ''}
            </span>
          </div>
          <pre style={{ color: '#cbd5e1', fontSize: '0.82rem', fontFamily: 'monospace', whiteSpace: 'pre-wrap', marginBottom: '8px' }}>
            {outputLog.stderr}
          </pre>
          <div style={{ fontSize: '0.8rem', color: '#94a3b8', fontStyle: 'italic' }}>
            {outputLog.action}
          </div>
        </div>
      )}
    </div>
  );
}

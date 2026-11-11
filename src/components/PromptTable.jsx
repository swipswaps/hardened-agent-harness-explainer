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

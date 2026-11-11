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

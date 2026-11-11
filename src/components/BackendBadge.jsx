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

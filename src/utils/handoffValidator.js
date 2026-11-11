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
  if (!res.ok) throw new Error('handoff/validate HTTP ' + res.status);
  const body = await res.json();
  return { ...body, source: 'server' };
}

// ── DOM Elements ──────────────────────────────────
const dropZone        = document.getElementById('dropZone');
const fileInput       = document.getElementById('fileInput');
const fileList        = document.getElementById('fileList');
const transcribeBtn   = document.getElementById('transcribeBtn');
const btnText         = document.getElementById('btnText');
const btnSpinner      = document.getElementById('btnSpinner');
const resultsContainer = document.getElementById('resultsContainer');
const historyContainer = document.getElementById('historyContainer');
const copyAllBtn      = document.getElementById('copyAllBtn');
const refreshBtn      = document.getElementById('refreshBtn');
const toast           = document.getElementById('toast');

let selectedFiles = [];

// ── Toast ──────────────────────────────────────────
function showToast(msg, type = 'success') {
  toast.textContent = msg;
  toast.className = `toast ${type}`;
  setTimeout(() => { toast.className = 'toast hidden'; }, 3200);
}

// ── File Selection ─────────────────────────────────
function addFiles(files) {
  for (const f of files) {
    if (!selectedFiles.find(x => x.name === f.name)) selectedFiles.push(f);
  }
  renderFileList();
}

function renderFileList() {
  fileList.innerHTML = selectedFiles.map((f, i) =>
    `<li>📦 ${f.name} <small>(${(f.size/1024).toFixed(1)} KB)</small></li>`
  ).join('');
  transcribeBtn.disabled = selectedFiles.length === 0;
}

dropZone.addEventListener('click', () => fileInput.click());
fileInput.addEventListener('change', e => addFiles(e.target.files));

dropZone.addEventListener('dragover', e => { e.preventDefault(); dropZone.classList.add('drag-over'); });
dropZone.addEventListener('dragleave', () => dropZone.classList.remove('drag-over'));
dropZone.addEventListener('drop', e => {
  e.preventDefault();
  dropZone.classList.remove('drag-over');
  addFiles(e.dataTransfer.files);
});

// ── Transcribe ─────────────────────────────────────
transcribeBtn.addEventListener('click', async () => {
  if (!selectedFiles.length) return;

  btnText.classList.add('hidden');
  btnSpinner.classList.remove('hidden');
  transcribeBtn.disabled = true;

  const formData = new FormData();
  selectedFiles.forEach(f => formData.append('files', f));

  try {
    const res = await fetch('/transcribe', { method: 'POST', body: formData });
    if (!res.ok) {
      const err = await res.json();
      throw new Error(err.detail || 'Transcription failed');
    }
    const data = await res.json();
    renderResults(data);
    showToast(`✅ ${data.length} file(s) transcribed successfully`);
    selectedFiles = [];
    renderFileList();
    loadHistory();

  } catch (err) {
    showToast(`❌ ${err.message}`, 'error');
  } finally {
    btnText.classList.remove('hidden');
    btnSpinner.classList.add('hidden');
    transcribeBtn.disabled = false;
  }
});

// ── Render Results ─────────────────────────────────
function renderResults(items) {
  resultsContainer.innerHTML = items.map(item => `
    <div class="log-entry">
      <div class="log-meta">
        [${new Date(item.created_at).toLocaleTimeString()}]
        FILE: ${item.filename} |
        LANG: ${item.language.toUpperCase()} |
        SIZE: ${item.file_size_kb} KB
      </div>
      <div class="log-text">${item.transcript || '(No speech detected)'}</div>
    </div>
  `).join('');
}

// ── Copy All ───────────────────────────────────────
copyAllBtn.addEventListener('click', () => {
  const texts = [...document.querySelectorAll('.log-text')]
    .map(el => el.textContent).join('\n\n---\n\n');
  if (!texts.trim()) return showToast('Nothing to copy', 'error');

  if (navigator.clipboard && window.isSecureContext) {
    navigator.clipboard.writeText(texts).then(() => showToast('📋 Copied to clipboard!'));
  } else {
    const ta = document.createElement('textarea');
    ta.value = texts;
    ta.style.cssText = 'position:fixed;left:-9999px';
    document.body.appendChild(ta);
    ta.select();
    document.execCommand('copy');
    document.body.removeChild(ta);
    showToast('📋 Copied!');
  }
});

// ── History ────────────────────────────────────────
async function loadHistory() {
  try {
    const res  = await fetch('/history?limit=15');
    const data = await res.json();

    if (!data.length) {
      historyContainer.innerHTML = '<p class="muted-msg">No transcriptions yet.</p>';
      return;
    }

    historyContainer.innerHTML = data.map(item => `
      <div class="history-item">
        <div class="history-filename" title="${item.filename}">📄 ${item.filename}</div>
        <div class="history-preview">${item.transcript || ''}</div>
        <div class="history-meta">
          <span class="history-lang">${item.language}</span>
          <span class="history-date">${new Date(item.created_at).toLocaleDateString()}</span>
          <button class="delete-btn" data-id="${item.id}" title="Delete">🗑</button>
        </div>
      </div>
    `).join('');

  } catch {
    historyContainer.innerHTML = '<p class="muted-msg">Failed to load logs.</p>';
  }
}

historyContainer.addEventListener('click', async e => {
  if (!e.target.classList.contains('delete-btn')) return;
  const res = await fetch(`/transcription/${e.target.dataset.id}`, { method: 'DELETE' });
  if (res.ok) { showToast('🗑 Deleted'); loadHistory(); }
});

refreshBtn.addEventListener('click', loadHistory);

// ── Init ───────────────────────────────────────────
loadHistory();

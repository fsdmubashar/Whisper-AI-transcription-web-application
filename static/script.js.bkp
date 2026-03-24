/**
 * VoiceScript Frontend Logic
 * File upload, transcription API call, history management
 */

// ── DOM Elements ──────────────────────────────────────
const dropZone       = document.getElementById('dropZone');
const fileInput      = document.getElementById('fileInput');
const fileList       = document.getElementById('fileList');
const transcribeBtn  = document.getElementById('transcribeBtn');
const btnText        = document.getElementById('btnText');
const btnSpinner     = document.getElementById('btnSpinner');
const resultsSection = document.getElementById('resultsSection');
const resultsContainer = document.getElementById('resultsContainer');
const historyContainer = document.getElementById('historyContainer');
const copyAllBtn     = document.getElementById('copyAllBtn');
const refreshBtn     = document.getElementById('refreshBtn');
const toast          = document.getElementById('toast');

let selectedFiles = [];

// ── Toast Notification ────────────────────────────────
function showToast(message, type = 'success') {
  toast.textContent = message;
  toast.className = `toast ${type}`;
  setTimeout(() => { toast.className = 'toast hidden'; }, 3500);
}

// ── File Handling ─────────────────────────────────────
function addFiles(newFiles) {
  for (const f of newFiles) {
    if (!selectedFiles.find(x => x.name === f.name)) {
      selectedFiles.push(f);
    }
  }
  renderFileList();
}

function renderFileList() {
  fileList.innerHTML = '';
  selectedFiles.forEach((f, i) => {
    const li = document.createElement('li');
    li.innerHTML = `
      <span>🎵 ${f.name} <small style="color:var(--muted)">(${(f.size/1024).toFixed(1)} KB)</small></span>
      <button class="remove-btn" data-i="${i}" title="Remove">✕</button>
    `;
    fileList.appendChild(li);
  });
  transcribeBtn.disabled = selectedFiles.length === 0;
}

fileList.addEventListener('click', e => {
  if (e.target.classList.contains('remove-btn')) {
    selectedFiles.splice(+e.target.dataset.i, 1);
    renderFileList();
  }
});

// ── Drag & Drop ───────────────────────────────────────
dropZone.addEventListener('click', () => fileInput.click());
fileInput.addEventListener('change', () => addFiles(fileInput.files));

dropZone.addEventListener('dragover', e => {
  e.preventDefault();
  dropZone.classList.add('drag-over');
});
dropZone.addEventListener('dragleave', () => dropZone.classList.remove('drag-over'));
dropZone.addEventListener('drop', e => {
  e.preventDefault();
  dropZone.classList.remove('drag-over');
  addFiles(e.dataTransfer.files);
});

// ── Transcribe ────────────────────────────────────────
transcribeBtn.addEventListener('click', async () => {
  if (selectedFiles.length === 0) return;

  // Loading state
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
    showToast(`✅ ${data.length} file(s) transcribed!`);

    // Reset
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

// ── Render Results ────────────────────────────────────
function renderResults(items) {
  resultsSection.classList.remove('hidden');
  resultsContainer.innerHTML = '';

  items.forEach(item => {
    const div = document.createElement('div');
    div.className = 'result-item';
    div.innerHTML = `
      <div class="result-meta">
        <span>📄 ${item.filename}</span>
        <span class="lang-badge">${item.language}</span>
        <span>${item.file_size_kb} KB</span>
        <span>${new Date(item.created_at).toLocaleString()}</span>
      </div>
      <div class="result-text">${item.transcript || '(No speech detected)'}</div>
    `;
    resultsContainer.appendChild(div);
  });

  resultsSection.scrollIntoView({ behavior: 'smooth' });
}

// ── Copy All ──────────────────────────────────────────
copyAllBtn.addEventListener('click', () => {
  const texts = [...document.querySelectorAll('.result-text')].map(el => el.textContent).join('\n\n---\n\n');
  navigator.clipboard.writeText(texts).then(() => showToast('📋 Copied to clipboard!'));
});

// ── History ───────────────────────────────────────────
async function loadHistory() {
  try {
    const res  = await fetch('/history?limit=20');
    const data = await res.json();

    if (!data.length) {
      historyContainer.innerHTML = '<p class="muted">Abhi tak koi transcription nahi hui.</p>';
      return;
    }

    historyContainer.innerHTML = '';
    data.forEach(item => {
      const div = document.createElement('div');
      div.className = 'history-item';
      div.innerHTML = `
        <div class="h-text">
          <strong>${item.filename}</strong>
          <span class="lang-badge" style="margin-left:.4rem">${item.language}</span><br/>
          <span>${(item.transcript || '').substring(0, 120)}${item.transcript?.length > 120 ? '…' : ''}</span>
        </div>
        <div style="display:flex;flex-direction:column;align-items:flex-end;gap:.4rem">
          <span class="h-meta">${new Date(item.created_at).toLocaleDateString()}</span>
          <button class="delete-btn" data-id="${item.id}" title="Delete">🗑️</button>
        </div>
      `;
      historyContainer.appendChild(div);
    });

  } catch {
    historyContainer.innerHTML = '<p class="muted">History load nahi hui.</p>';
  }
}

// Delete history item
historyContainer.addEventListener('click', async e => {
  if (!e.target.classList.contains('delete-btn')) return;
  const id = e.target.dataset.id;

  const res = await fetch(`/transcription/${id}`, { method: 'DELETE' });
  if (res.ok) {
    showToast('🗑️ Deleted!');
    loadHistory();
  }
});

refreshBtn.addEventListener('click', loadHistory);

// ── Init ──────────────────────────────────────────────
loadHistory();

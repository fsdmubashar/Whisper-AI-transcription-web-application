// ── ELEMENTS ──
const dropZone = document.getElementById('dropZone');
const fileInput = document.getElementById('fileInput');
const fileList = document.getElementById('fileList');
const transcribeBtn = document.getElementById('transcribeBtn');
const btnText = document.getElementById('btnText');
const btnSpinner = document.getElementById('btnSpinner');
const resultsSection = document.getElementById('resultsSection');
const resultsContainer = document.getElementById('resultsContainer');
const historyContainer = document.getElementById('historyContainer');
const copyAllBtn = document.getElementById('copyAllBtn');
const refreshBtn = document.getElementById('refreshBtn');
const toast = document.getElementById('toast');

let selectedFiles = [];

// ── TOAST FIX ──
function showToast(message, type = 'success') {
    toast.textContent = message;
    toast.className = `toast ${type}`;
    toast.classList.remove('hidden');
    setTimeout(() => { toast.classList.add('hidden'); }, 4000);
}

// ── COPY ALL LOGIC (FIXED) ──
copyAllBtn.addEventListener('click', () => {
    const textBlocks = document.querySelectorAll('.result-text');
    if (textBlocks.length === 0) {
        showToast("No content to copy!", "error");
        return;
    }

    // Saare results ko ek string mein jamah karna
    const allText = Array.from(textBlocks)
        .map(el => el.innerText)
        .join('\n\n--- NEXT FILE ---\n\n');

    // Modern clipboard API with fallback
    if (navigator.clipboard && window.isSecureContext) {
        navigator.clipboard.writeText(allText).then(() => {
            showToast("✅ Copied to clipboard!");
        }).catch(err => {
            console.error('Copy failed', err);
            fallbackCopy(allText);
        });
    } else {
        fallbackCopy(allText);
    }
});

function fallbackCopy(text) {
    const textArea = document.createElement("textarea");
    textArea.value = text;
    document.body.appendChild(textArea);
    textArea.select();
    try {
        document.execCommand('copy');
        showToast("✅ Copied to clipboard!");
    } catch (err) {
        showToast("❌ Copy failed", "error");
    }
    document.body.removeChild(textArea);
}

// ── FILE HANDLING ──
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
        li.className = 'file-item';
        li.style.cssText = "display:flex; justify-content:space-between; font-size:0.8rem; background:rgba(255,255,255,0.05); padding:8px; margin-top:5px; border-radius:4px;";
        li.innerHTML = `
      <span>📄 ${f.name.substring(0,25)}...</span>
      <button onclick="removeFile(${i})" style="background:none; border:none; color:#f43f5e; cursor:pointer;">✕</button>
    `;
    fileList.appendChild(li);
    });
    transcribeBtn.disabled = selectedFiles.length === 0;
}

window.removeFile = (index) => {
    selectedFiles.splice(index, 1);
    renderFileList();
};

// ── DRAG & DROP ──
dropZone.onclick = () => fileInput.click();
fileInput.onchange = () => addFiles(fileInput.files);

dropZone.ondragover = (e) => { e.preventDefault(); dropZone.style.borderColor = "#3b82f6"; };
dropZone.ondragleave = () => { dropZone.style.borderColor = ""; };
dropZone.ondrop = (e) => {
    e.preventDefault();
    dropZone.style.borderColor = "";
    addFiles(e.dataTransfer.files);
};

// ── API CALL ──
transcribeBtn.onclick = async () => {
    btnText.classList.add('hidden');
    btnSpinner.classList.remove('hidden');
    transcribeBtn.disabled = true;

    const formData = new FormData();
    selectedFiles.forEach(f => formData.append('files', f));

    try {
        const res = await fetch('/transcribe', { method: 'POST', body: formData });
        if (!res.ok) throw new Error("Server error occurred");
        
        const data = await res.json();
        renderResults(data);
        showToast(`Processed ${data.length} files successfully`);
        
        selectedFiles = [];
        renderFileList();
        loadHistory();
    } catch (err) {
        showToast(err.message, 'error');
    } finally {
        btnText.classList.remove('hidden');
        btnSpinner.classList.add('hidden');
        transcribeBtn.disabled = false;
    }
};

function renderResults(items) {
    resultsSection.classList.remove('hidden');
    resultsContainer.innerHTML = '';
    items.forEach(item => {
        const div = document.createElement('div');
        div.className = 'result-item';
        div.innerHTML = `
      <div style="font-size:0.7rem; color:#94a3b8; margin-bottom:5px;">FILE: ${item.filename} | LANG: ${item.language}</div>
      <div class="result-text">${item.transcript || 'No speech detected.'}</div>
    `;
        resultsContainer.appendChild(div);
    });
}

// ── HISTORY ──
async function loadHistory() {
    try {
        const res = await fetch('/history?limit=10');
        const data = await res.json();
        historyContainer.innerHTML = '';
        
        if (data.length === 0) {
            historyContainer.innerHTML = '<p class="muted">No logs found.</p>';
            return;
        }

        data.forEach(item => {
            const div = document.createElement('div');
            div.style.cssText = "padding:10px 0; border-bottom:1px solid #242b38; display:flex; justify-content:space-between; align-items:center;";
            div.innerHTML = `
                <div>
                    <div style="font-weight:600; font-size:0.85rem;">${item.filename}</div>
                    <div style="font-size:0.75rem; color:#94a3b8;">${item.transcript ? item.transcript.substring(0, 50) + '...' : 'Empty'}</div>
                </div>
                <button onclick="deleteLog('${item.id}')" style="background:none; border:none; cursor:pointer;">🗑️</button>
            `;
            historyContainer.appendChild(div);
        });
    } catch (e) {
        historyContainer.innerHTML = '<p class="muted">Error loading logs.</p>';
    }
}

window.deleteLog = async (id) => {
    await fetch(`/transcription/${id}`, { method: 'DELETE' });
    loadHistory();
};

refreshBtn.onclick = loadHistory;
loadHistory();

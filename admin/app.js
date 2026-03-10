// ═══════════════════════════════════════════════════════════════════════════
// Event Photo Finder – Admin Panel JavaScript
// Replace CONFIG values below with your actual Supabase credentials.
// ═══════════════════════════════════════════════════════════════════════════

const CONFIG = {
  supabaseUrl: 'https://whlunyumdvqphtgkkvvw.supabase.co',
  supabaseAnonKey: 'sb_publishable_zaMqWw_LQ1wTwkiqWMNX_Q_f2VqWf0_',
  r2UploadEndpoint: 'https://photo-finder-upload.devmahi-me.workers.dev', // Cloudflare Worker URL
};

// ─── Supabase REST helper ───────────────────────────────────────────────────
async function sbFetch(path, options = {}) {
  const res = await fetch(`${CONFIG.supabaseUrl}/rest/v1${path}`, {
    ...options,
    headers: {
      'apikey': CONFIG.supabaseAnonKey,
      'Authorization': `Bearer ${CONFIG.supabaseAnonKey}`,
      'Content-Type': 'application/json',
      'Prefer': 'return=representation',
      ...(options.headers || {}),
    },
  });
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}

// ─── Toast ──────────────────────────────────────────────────────────────────
function showToast(message, type = 'success') {
  const tc = document.getElementById('toast-container');
  const t = document.createElement('div');
  t.className = `toast ${type}`;
  t.textContent = message;
  tc.appendChild(t);
  setTimeout(() => t.remove(), 3500);
}

// ─── Navigation ─────────────────────────────────────────────────────────────
document.querySelectorAll('.nav-item').forEach(link => {
  link.addEventListener('click', (e) => {
    e.preventDefault();
    const section = link.dataset.section;
    document.querySelectorAll('.nav-item').forEach(l => l.classList.remove('active'));
    document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
    link.classList.add('active');
    document.getElementById(`section-${section}`).classList.add('active');
  });
});

// ─── Events ─────────────────────────────────────────────────────────────────
let eventsCache = [];

async function loadEvents() {
  const loading = document.getElementById('events-loading');
  const table = document.getElementById('events-table');
  const tbody = document.getElementById('events-body');

  loading.style.display = 'block';
  table.style.display = 'none';

  try {
    eventsCache = await sbFetch('/events?order=event_date.desc');
    tbody.innerHTML = '';

    for (const ev of eventsCache) {
      // Count photos
      let photoCount = '—';
      try {
        const cnt = await sbFetch(`/photos?event_id=eq.${ev.id}&select=id`);
        photoCount = cnt.length;
      } catch (_) { }

      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td><strong>${ev.title}</strong></td>
        <td>${ev.event_date}</td>
        <td><span class="badge badge-purple">₹${ev.price}</span></td>
        <td>${photoCount}</td>
        <td>
          <button class="btn btn-danger" style="padding:6px 12px;font-size:12px;" onclick="deleteEvent('${ev.id}')">Delete</button>
        </td>`;
      tbody.appendChild(tr);
    }

    // Populate upload select
    const sel = document.getElementById('upload-event-select');
    sel.innerHTML = '<option value="">-- Select an event --</option>';
    eventsCache.forEach(ev => {
      const opt = document.createElement('option');
      opt.value = ev.id;
      opt.textContent = ev.title;
      sel.appendChild(opt);
    });

    loading.style.display = 'none';
    table.style.display = 'table';
  } catch (err) {
    loading.textContent = `Error: ${err.message}`;
  }
}

async function deleteEvent(id) {
  if (!confirm('Delete this event and all its photos?')) return;
  try {
    await sbFetch(`/events?id=eq.${id}`, { method: 'DELETE' });
    showToast('Event deleted.');
    loadEvents();
  } catch (err) {
    showToast(`Error: ${err.message}`, 'error');
  }
}

// Create event form toggle
document.getElementById('btn-create-event').addEventListener('click', () => {
  const form = document.getElementById('create-event-form');
  form.style.display = form.style.display === 'none' ? 'block' : 'none';
});

document.getElementById('btn-cancel-event').addEventListener('click', () => {
  document.getElementById('create-event-form').style.display = 'none';
});

document.getElementById('btn-save-event').addEventListener('click', async () => {
  const title = document.getElementById('event-title').value.trim();
  const date = document.getElementById('event-date').value;
  const cover = document.getElementById('event-cover').value.trim();
  const price = parseInt(document.getElementById('event-price').value, 10);

  if (!title || !date) {
    showToast('Title and date are required.', 'error');
    return;
  }

  try {
    await sbFetch('/events', {
      method: 'POST',
      body: JSON.stringify({ title, event_date: date, cover_image: cover, price }),
    });
    showToast('Event created!');
    document.getElementById('create-event-form').style.display = 'none';
    // Reset form
    ['event-title', 'event-date', 'event-cover'].forEach(id => document.getElementById(id).value = '');
    document.getElementById('event-price').value = '500';
    loadEvents();
  } catch (err) {
    showToast(`Error: ${err.message}`, 'error');
  }
});

// ─── Photo Upload ────────────────────────────────────────────────────────────
const fileInput = document.getElementById('file-input');
const fileDrop = document.getElementById('file-drop');
const fileSelected = document.getElementById('file-selected');
let selectedFile = null;

fileDrop.addEventListener('click', () => fileInput.click());

fileDrop.addEventListener('dragover', (e) => {
  e.preventDefault();
  fileDrop.classList.add('dragover');
});

fileDrop.addEventListener('dragleave', () => fileDrop.classList.remove('dragover'));

fileDrop.addEventListener('drop', (e) => {
  e.preventDefault();
  fileDrop.classList.remove('dragover');
  const file = e.dataTransfer.files[0];
  if (file && file.name.endsWith('.zip')) setFile(file);
  else showToast('Please drop a .zip file.', 'error');
});

fileInput.addEventListener('change', () => {
  if (fileInput.files[0]) setFile(fileInput.files[0]);
});

function setFile(file) {
  selectedFile = file;
  fileDrop.style.display = 'none';
  fileSelected.style.display = 'block';
  fileSelected.textContent = `📦 ${file.name} (${(file.size / 1024 / 1024).toFixed(2)} MB)`;
}

document.getElementById('btn-upload').addEventListener('click', async () => {
  const eventId = document.getElementById('upload-event-select').value;
  const statusEl = document.getElementById('upload-status');
  const progressWrap = document.getElementById('upload-progress-wrap');
  const progressFill = document.getElementById('progress-fill');
  const progressLabel = document.getElementById('progress-label');

  if (!eventId) { showToast('Please select an event.', 'error'); return; }
  if (!selectedFile) { showToast('Please select a ZIP file.', 'error'); return; }

  statusEl.style.display = 'none';

  try {
    progressWrap.style.display = 'flex';
    progressFill.style.width = '10%';
    progressLabel.textContent = '10%';

    const formData = new FormData();
    formData.append('file', selectedFile);
    formData.append('event_id', eventId);
    formData.append('supabase_url', CONFIG.supabaseUrl);
    formData.append('supabase_key', CONFIG.supabaseAnonKey);

    // Simulated progress (actual progress requires streaming)
    let pct = 10;
    const interval = setInterval(() => {
      pct = Math.min(pct + 8, 90);
      progressFill.style.width = `${pct}%`;
      progressLabel.textContent = `${pct}%`;
    }, 400);

    const res = await fetch(CONFIG.r2UploadEndpoint, {
      method: 'POST',
      body: formData,
    });

    clearInterval(interval);

    if (!res.ok) throw new Error(await res.text());

    const result = await res.json();

    progressFill.style.width = '100%';
    progressLabel.textContent = '100%';

    statusEl.className = 'status-message success';
    statusEl.textContent = `✓ Uploaded ${result.count ?? 'all'} photos successfully!`;
    statusEl.style.display = 'block';

    showToast('Photos uploaded!');
    setTimeout(() => { progressWrap.style.display = 'none'; }, 1000);
  } catch (err) {
    document.getElementById('upload-progress-wrap').style.display = 'none';
    statusEl.className = 'status-message error';
    statusEl.textContent = `✗ Upload failed: ${err.message}`;
    statusEl.style.display = 'block';
    showToast(`Upload error: ${err.message}`, 'error');
  }
});

// ─── Init ────────────────────────────────────────────────────────────────────
loadEvents();

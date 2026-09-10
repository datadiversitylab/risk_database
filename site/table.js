// Shared table for the browse and priority pages
// Loads the prebuilt index once and filters it in the browser

let DATA = [];
let OPTS = {};

function loadIndex(cb) {
  fetch('data/index.json')
    .then(r => r.json())
    .then(d => { DATA = d; cb(d); })
    .catch(() => {
      document.getElementById('table').innerHTML =
        '<div class="empty">No predictions published yet. Run <code>build.R</code> ' +
        'once prediction files exist.</div>';
    });
}

function renderControls(data, opts) {
  OPTS = opts || {};
  const groups = [...new Set(data.map(d => d.group))].sort();
  const g = document.getElementById('group');
  groups.forEach(x => g.add(new Option(x, x)));

  const st = document.getElementById('status');
  if (st) {
    [...new Set(data.map(d => d.status))].sort().forEach(x => st.add(new Option(x, x)));
  }

  ['q', 'group', 'status', 'minp', 'lowonly', 'topn', 'hidelow'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.addEventListener('input', () => renderTable(DATA, OPTS));
  });
}

function val(id, fallback) {
  const el = document.getElementById(id);
  if (!el) return fallback;
  return el.type === 'checkbox' ? el.checked : el.value;
}

function renderTable(data, opts) {
  opts = opts || OPTS;
  let rows = data.slice();

  const q = String(val('q', '')).trim().toLowerCase();
  if (q) rows = rows.filter(d => d.species.toLowerCase().includes(q));

  const group = val('group', '');
  if (group) rows = rows.filter(d => d.group === group);

  const status = val('status', '');
  if (status) rows = rows.filter(d => d.status === status);

  const minp = parseFloat(val('minp', 0));
  if (minp > 0) rows = rows.filter(d => d.prob >= minp);

  if (val('lowonly', false)) rows = rows.filter(d => d.low);
  if (val('hidelow', false)) rows = rows.filter(d => !d.low);

  rows.sort((a, b) => (b.prob || 0) - (a.prob || 0));

  const total = rows.length;
  const limit = opts.priority ? parseInt(val('topn', 100), 10) : 200;
  rows = rows.slice(0, limit);

  document.getElementById('count').textContent =
    total === 0 ? 'No species match these filters.'
                : 'Showing ' + rows.length + ' of ' + total.toLocaleString() + ' species.';

  if (!rows.length) { document.getElementById('table').innerHTML = ''; return; }

  const body = rows.map((d, i) => {
    const pct = Math.round((d.prob || 0) * 100);
    const rank = opts.priority ? '<td>' + (i + 1) + '</td>' : '';
    return '<tr>' + rank +
      '<td><a href="species.html?id=' + d.id + '"><em>' + d.species + '</em></a></td>' +
      '<td>' + d.group + '</td>' +
      '<td>' + (d.status || '') + '</td>' +
      '<td><span class="prob-bar" style="width:' + Math.max(pct, 2) + 'px"></span> ' +
      (d.prob != null ? d.prob.toFixed(2) : '') + '</td>' +
      '<td>' + d.n + '</td>' +
      '<td>' + (d.low ? '<span class="flag">models disagree</span>' : '') + '</td>' +
      '</tr>';
  }).join('');

  const head = (opts.priority ? '<th>#</th>' : '') +
    '<th>Species</th><th>Group</th><th>Predicted</th><th>Probability</th>' +
    '<th>Models</th><th></th>';

  document.getElementById('table').innerHTML =
    '<table class="results"><thead><tr>' + head + '</tr></thead><tbody>' + body + '</tbody></table>';
}

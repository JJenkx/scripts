// ==UserScript==
// @name        TableTools Enhanced again ChatGPT
// @namespace   ameboide
// @description Adds filters, sorting, and stats to tables with enhanced data type support, including sizes like MiB, GiB, etc.
// @include     *
// @version     2.5
// ==/UserScript==

function clickHandler(event) {
  let table = event.target.closest('table');
  if (!table) return;

  let td = event.target.closest('td, th');
  let ctrl = event.ctrlKey || event.metaKey;
  let alt = event.altKey;
  let shift = event.shiftKey;
  let leftClick = event.button == 0;

  if (ctrl && shift && !alt && leftClick) toggleInputFilters(table);
  else if (ctrl && shift && !alt && leftClick) toggleSelectFilters(table);
  else if (ctrl && !shift && alt && leftClick) sortTableByTd(table, td);
  else if (ctrl && shift && alt && leftClick) toggleStats(table);
}

function toggleInputFilters(table) {
  toggleFilters(table, 'tt_input_filters', 'input');
}

function toggleSelectFilters(table) {
  toggleFilters(table, 'tt_select_filters', 'select');
  fillSelectFilters(table);
}

function fillSelectFilters(table) {
  let thead = table.querySelector('thead.tt_select_filters');
  if (!thead) return;

  let cols = countCols(table);
  let lists = new Array(cols).fill(null).map(() => ({}));

  for (let tr of table.querySelectorAll('tbody tr:not(.tt_hidden), :scope > tr:not(.tt_hidden)')) {
    let c = 0;
    for (let td of tr.querySelectorAll('td, th')) {
      let text = clean(td.textContent);
      if (!lists[c][text]) lists[c][text] = 0;
      lists[c][text]++;
      c += td.colSpan || 1;
    }
  }

  for (let col = 0; col < cols; col++) {
    let sel = thead.querySelector(`select[data-col="${col}"]`);
    let value = sel.value;
    sel.innerHTML = '';

    let option = document.createElement('option');
    sel.appendChild(option);
    let keys = Object.keys(lists[col]).sort((a, b) => {
      let ret = lists[col][b] - lists[col][a];
      return ret == 0 ? (a > b ? 1 : -1) : ret;
    });
    for (let text of keys) {
      option = document.createElement('option');
      option.textContent = `${text} (${lists[col][text]})`;
      option.value = `=${text}`;
      if (option.value == value) option.selected = 'selected';
      sel.appendChild(option);
    }
  }
}

function toggleFilters(table, klass, inputTag) {
  let thead = table.querySelector(`thead.${klass}`);
  if (thead) {
    thead.remove();
    filterColumns(table);
    return;
  }

  let cols = countCols(table);
  thead = document.createElement('thead');
  thead.classList.add(klass, 'tt_filters');
  let tr = document.createElement('tr');
  thead.appendChild(tr);
  table.prepend(thead);

  for (let i = 0; i < cols; i++) {
    let td = document.createElement('td');
    let input = document.createElement(inputTag);
    input.dataset.col = i;
    input.addEventListener('change', () => filterColumns(table), false);
    input.addEventListener('keyup', (event) => { if (event.keyCode == 13) filterColumns(table); }, false);
    tr.appendChild(td);
    input.style.width = `${td.scrollWidth}px`;
    td.appendChild(input);
  }
}

function countCols(table) {
  let tds = Array.from(table.querySelector('tr').querySelectorAll('td, th'));
  return tds.reduce((total, td) => total + (td.colSpan || 1), 0);
}

function filterColumns(table) {
  table.querySelectorAll('tr.tt_hidden').forEach(tr => tr.classList.remove('tt_hidden'));
  table.querySelectorAll('.tt_filters input, .tt_filters select').forEach(input => filterColumn(input));
  fillSelectFilters(table);
  fillStats(table);
}

function filterColumn(input) {
  let col = input.dataset.col;
  let text = input.value;
  if (!text) return;

  let filter = inputToFilters(text);
  let trs = input.closest('table').querySelectorAll('tbody tr, :scope > tr');

  trs.forEach(tr => {
    if (!matchFilters(colText(tr, col), filter)) tr.classList.add('tt_hidden');
  });
}

function inputToFilters(textOr) {
  return textOr.split(' || ').map(textAnd => {
    return textAnd.split(' && ').map(text => {
      let m = text.match(/^\/(.+)\/$/);
      if (m) return { re: new RegExp(m[1], 'i') };

      text = clean(text);
      let comp = null;
      if (m = text.match(/^([<>=!\\])(.*)/)) {
        comp = m[1] == '\\' ? null : m[1];
        text = m[2];
      }
      return { comp: comp, text: text };
    });
  });
}

function matchFilters(text, ors) {
  return ors.some(ands => ands.every(filter => matchFilter(text, filter)));
}

function colText(tr, col) {
  let c = 0;
  for (let td of tr.querySelectorAll('td, th')) {
      c += td.colSpan || 1;
      if (c <= col) continue;
      // Clean the text and remove commas
      return clean(td.textContent.replace(/,/g, ''));
  }
  return '';
}


function matchFilter(content, filter) {
  if (filter.re) return content.match(filter.re);

  let text = filter.text;
  if (!filter.comp) return content.includes(text);

  let contentVal = content;
  let filterVal = text;

  if (isNum(content) && isNum(text)) {
    contentVal = parseNum(content);
    filterVal = parseNum(text);
  } else if (isDate(content) && isDate(text)) {
    contentVal = parseDate(content);
    filterVal = parseDate(text);
  } else if (isSize(content) && isSize(text)) {
    contentVal = parseSize(content);
    filterVal = parseSize(text);
  }

  switch (filter.comp) {
    case '<': return contentVal < filterVal;
    case '>': return contentVal > filterVal;
    case '=': return contentVal == filterVal;
    case '!': return contentVal != filterVal;
  }
}

function isNum(text) {
  return text && !isNaN(text.replace(/,/g, ''));
}

function parseNum(text) {
  return parseFloat(text.replace(/,/g, ''));
}

function isDate(text) {
  let datePatterns = [
    /^\d{1,2}\/\d{1,2}\/\d{4}$/,
    /^\d{4}-\d{1,2}-\d{1,2}$/
  ];
  return datePatterns.some(pattern => pattern.test(text));
}

function parseDate(text) {
  let date = new Date(text);
  return !isNaN(date) ? date.getTime() : null;
}

function isCurrency(text) {
  return /^[£$€]\s?\d[\d,\.]*$/.test(text);
}

function parseCurrency(text) {
  let num = text.replace(/[£$€\s,]/g, '');
  return parseFloat(num);
}

function isSize(text) {
  let regex = /^\s*\d+(\.\d+)?\s*(B|KB|MB|GB|TB|PB|EB|ZB|YB|KIB|MIB|GIB|TIB|PIB|EIB|ZIB|YIB)\s*$/i;
  return regex.test(text);
}

function parseSize(text) {
  const units = {
      'B': 1,
      'KB': 1e3,
      'MB': 1e6,
      'GB': 1e9,
      'TB': 1e12,
      'PB': 1e15,
      'EB': 1e18,
      'ZB': 1e21,
      'YB': 1e24,
      'KIB': 1024,
      'MIB': Math.pow(1024, 2),
      'GIB': Math.pow(1024, 3),
      'TIB': Math.pow(1024, 4),
      'PIB': Math.pow(1024, 5),
      'EIB': Math.pow(1024, 6),
      'ZIB': Math.pow(1024, 7),
      'YIB': Math.pow(1024, 8),
  };

  // Remove commas and sanitize input
  text = text.replace(/,/g, '').trim();

  const regex = /^(\d+(\.\d+)?)\s*(B|KB|MB|GB|TB|PB|EB|ZB|YB|KIB|MIB|GIB|TIB|PIB|EIB|ZIB|YIB)$/i;
  const match = text.match(regex);

  if (match) {
      const num = parseFloat(match[1]);
      const unit = match[3].toUpperCase();

      // Custom rule: If "GB", add 1 to the value in bytes
      if (unit === 'GB') {
          const sizeInBytes = (num * 1e9) + 1;
          console.log(`Original: ${text}, Parsed Size: ${sizeInBytes} (Custom Rule Applied)`);
          return sizeInBytes;
      }

      // Use binary (1024-based) multipliers for binary units (e.g., `KIB`, `MIB`) and decimal otherwise
      const multiplier = units[unit] || NaN;

      const sizeInBytes = num * multiplier;
      console.log(`Original: ${text}, Parsed Size: ${sizeInBytes}`);
      return sizeInBytes;
  }

  console.log(`Invalid size format: ${text}`);
  return NaN; // Return NaN if invalid size format
}

function clean(string) {
  return string.trim().toLowerCase().replace(/\s+/g, ' ');
}

function sortTableByTd(table, td) {
  let col = 0;
  for (let tdi of td.parentNode.querySelectorAll('td, th')) {
    if (tdi == td) break;
    col += tdi.colSpan || 1;
  }

  let lastSortCol = parseInt(table.dataset.lastSortCol);
  let lastSortOrder = parseInt(table.dataset.lastSortOrder);

  let order;
  if (lastSortCol === col) {
    // Toggle order
    order = -lastSortOrder || -1;
  } else {
    // Default to descending order
    order = -1;
  }

  table.dataset.lastSortCol = col;
  table.dataset.lastSortOrder = order;

  // Remove sort indicators from previous header
  let prevSortedTh = table.querySelector('th.sorted-asc, td.sorted-asc, th.sorted-desc, td.sorted-desc');
  if (prevSortedTh) {
    prevSortedTh.classList.remove('sorted-asc', 'sorted-desc');
  }

  // Add sort indicator to current header (optional)
  // td.classList.remove('sorted-asc', 'sorted-desc');
  // td.classList.add(order === 1 ? 'sorted-asc' : 'sorted-desc');

  sortTable(table, col, order);
}

//fuck
function sortTable(table, col, order) {
  const trs = Array.from(table.querySelectorAll('tbody tr, :scope > tr'));
  const tbody = table.querySelector('tbody') || table;

  const rowsWithValues = trs.map(tr => {
      const text = colText(tr, col);
      let value = text;
      let valueType = 'string';

      if (isNum(text)) {
          value = parseNum(text);
          valueType = 'number';
      } else if (isDate(text)) {
          value = parseDate(text);
          valueType = 'date';
      } else if (isCurrency(text)) {
          value = parseCurrency(text);
          valueType = 'number';
      } else if (isSize(text)) {
          value = parseSize(text);
          valueType = 'number';
      }

      console.log(`Row: ${text}, Parsed Value: ${value}, Type: ${valueType}`);
      return { tr, value, valueType }; // Exclude `text`
  });

  console.log('Sorting Values:', rowsWithValues.map(row => row.value));

  rowsWithValues.sort((a, b) => {
      if (a.valueType === b.valueType) {
          return (a.value - b.value) * order;
      } else {
          const typeOrder = { 'number': 1, 'date': 2, 'string': 3 };
          return (typeOrder[a.valueType] - typeOrder[b.valueType]) * order;
      }
  });

  rowsWithValues.forEach(row => tbody.appendChild(row.tr));
}


function toggleStats(table) {
  let thead = table.querySelector('thead.tt_stats');
  if (thead) {
    thead.remove();
    return;
  }

  let cols = countCols(table);

  thead = document.createElement('thead');
  thead.classList.add('tt_stats');
  let tr = document.createElement('tr');
  thead.appendChild(tr);
  table.prepend(thead);

  for (let i = 0; i < cols; i++) {
    let td = document.createElement('td');
    tr.appendChild(td);
  }
  fillStats(table);
}

function fillStats(table) {
  let tr = table.querySelector('thead.tt_stats tr');
  if (!tr) return;

  let i = 0;
  tr.querySelectorAll('td').forEach(td => {
    let stats = colStats(table, i);
    let html = '';
    for (let key in stats) html += `<strong>${key}:</strong> <span>${stats[key]}</span><br/>`;
    td.innerHTML = html;
    i++;
  });
}

function colStats(table, col) {
  let distinct = {};
  let sum = 0, min = null, max = null;
  let isTime = true;
  let isSizeCol = true;
  let trs = table.querySelectorAll('tbody tr:not(.tt_hidden), :scope > tr:not(.tt_hidden)');

  trs.forEach(tr => {
    let text = colText(tr, col);
    if (!distinct[text]) distinct[text] = 0;
    distinct[text]++;

    if (isTime && text && !text.match(/^(\d+:)?\d{1,2}:\d{1,2}$/)) {
      isTime = false;
      sum = 0;
    }

    if (isSizeCol && isSize(text)) {
      let sizeValue = parseSize(text);
      sum += sizeValue;
      if (min === null || sizeValue < min) min = sizeValue;
      if (max === null || sizeValue > max) max = sizeValue;
    } else if (isTime && text) {
      sum += timeToInt(text);
    } else if (isNum(text)) {
      let num = parseNum(text);
      sum += num;
      if (min === null || num < min) min = num;
      if (max === null || num > max) max = num;
    } else {
      isSizeCol = false;
    }
  });

  let count0 = Object.keys(distinct).filter(text => text.match(/^(0+(\.0+|(:0+)+)?)?$/)).reduce((sum, key) => sum + distinct[key], 0);
  let stats = {
    Count: trs.length,
    CountNot0: trs.length - count0,
    CountDistinct: Object.keys(distinct).length,
    Min: min,
    Max: max
  };

  if (sum > 0) {
    if (isTime) {
      stats.Avg = intToTime(sum / stats.Count);
      stats.AvgNot0 = intToTime(sum / stats.CountNot0);
      stats.Sum = intToTime(sum);
    } else if (isSizeCol) {
      stats.Avg = formatSize(sum / stats.Count);
      stats.AvgNot0 = formatSize(sum / stats.CountNot0);
      stats.Sum = formatSize(sum);
    } else {
      stats.Avg = (sum / stats.Count).toFixed(3);
      stats.AvgNot0 = (sum / stats.CountNot0).toFixed(3);
      stats.Sum = sum;
    }
  }
  return stats;
}

function formatSize(bytes) {
  if (bytes === 0) return '0 B';
  let k = 1024;
  let sizes = ['B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB', 'ZiB', 'YiB'];
  let i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

function timeToInt(text) {
  let parts = text.split(':').map(Number);
  let seconds = 0;
  while (parts.length) {
    seconds += parts.pop() * Math.pow(60, parts.length);
  }
  return seconds;
}

function intToTime(secs) {
  let hours = Math.floor(secs / 3600);
  let minutes = Math.floor((secs % 3600) / 60);
  let seconds = secs % 60;
  return [hours, minutes, seconds].map(zpad).join(':');
}

function zpad(num) {
  return String(Math.floor(num)).padStart(2, '0');
}

// Removed styles related to arrows
let style = document.createElement('style');
style.innerHTML = `
.tt_hidden { display: none; }
.tt_stats { background-color: #ffc; }
/* Uncomment if you want minimal visual indication in the header
th.sorted-asc::after,
td.sorted-asc::after {
  content: ' ▲';
}
th.sorted-desc::after,
td.sorted-desc::after {
  content: ' ▼';
}
*/
`;
document.head.appendChild(style);

window.addEventListener('mousedown', clickHandler, true);

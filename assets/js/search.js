const input = document.getElementById("search-input");
const results = document.getElementById("search-results");
const topInput = document.getElementById("search-input-top");
const topResults = document.getElementById("search-results-top");

const attachSearch = (inputEl, resultsEl) => {
  if (!inputEl || !resultsEl) return;
  let index = [];

  const render = (items) => {
    if (!items.length) {
      resultsEl.innerHTML = "<div class=\"search-empty\">No results</div>";
      return;
    }
    resultsEl.innerHTML = items
      .map(
        (it) =>
          `<a class="search-item" href="${it.url}"><div class="search-title">${it.title}</div><div class="search-snippet">${it.snippet}</div></a>`
      )
      .join("");
  };

  const buildResults = (query) => {
    const q = query.toLowerCase();
    const items = [];
    for (const entry of index) {
      const hay = entry.text.toLowerCase();
      const pos = hay.indexOf(q);
      if (pos === -1) continue;
      const start = Math.max(0, pos - 60);
      const end = Math.min(entry.text.length, pos + 140);
      const snippet = entry.text.slice(start, end).replace(/\s+/g, " ");
      items.push({ title: entry.title, url: entry.url, snippet: snippet + "…" });
      if (items.length >= 25) break;
    }
    render(items);
  };

  fetch("/assets/js/search-index.json")
    .then((r) => r.json())
    .then((data) => {
      index = data;
    })
    .catch(() => {
      resultsEl.innerHTML = "<div class=\"search-empty\">Search unavailable</div>";
    });

  inputEl.addEventListener("input", (e) => {
    const q = e.target.value.trim();
    if (!q) {
      resultsEl.innerHTML = "";
      return;
    }
    buildResults(q);
  });
};

attachSearch(input, results);
attachSearch(topInput, topResults);

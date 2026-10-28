(function () {
  var MESES = ["janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho",
    "agosto", "setembro", "outubro", "novembro", "dezembro"];

  function esc(s) {
    return String(s).replace(/[&<>"']/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
    });
  }

  function formatDate(iso) {
    var m = /^(\d{4})-(\d{2})-(\d{2})/.exec(iso || "");
    if (!m) return esc(iso || "");
    return parseInt(m[3], 10) + " de " + MESES[parseInt(m[2], 10) - 1] + " de " + m[1];
  }

  function tagsHtml(tags) {
    if (!tags || !tags.length) return "";
    return '<span class="tags">' + tags.map(function (t) {
      return '<span class="tag">' + esc(t) + "</span>";
    }).join("") + "</span>";
  }

  // Tema claro/escuro
  var root = document.documentElement;
  try {
    var saved = localStorage.getItem("tema");
    if (saved) root.setAttribute("data-theme", saved);
  } catch (e) {}
  var toggle = document.getElementById("theme-toggle");
  if (toggle) {
    toggle.addEventListener("click", function () {
      var current = root.getAttribute("data-theme") ||
        (window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light");
      var next = current === "dark" ? "light" : "dark";
      root.setAttribute("data-theme", next);
      try { localStorage.setItem("tema", next); } catch (e) {}
    });
  }

  document.querySelectorAll("[data-year]").forEach(function (el) {
    el.textContent = new Date().getFullYear();
  });

  var page = document.body.getAttribute("data-page");

  function fetchOrFail(url, asJson) {
    return fetch(url).then(function (r) {
      if (!r.ok) throw new Error(r.status);
      return asJson ? r.json() : r.text();
    });
  }

  if (page === "home") {
    var list = document.getElementById("post-list");
    fetchOrFail("posts/index.json", true).then(function (posts) {
      if (!posts.length) {
        list.outerHTML = '<p class="empty">Ainda não há textos publicados.</p>';
        return;
      }
      list.innerHTML = posts.map(function (p) {
        return '<li class="post-item">' +
          '<div class="meta">' + formatDate(p.data) + tagsHtml(p.tags) + "</div>" +
          '<h2><a href="post.html?p=' + encodeURIComponent(p.slug) + '">' + esc(p.titulo) + "</a></h2>" +
          (p.resumo ? "<p>" + esc(p.resumo) + "</p>" : "") +
          "</li>";
      }).join("");
    }).catch(function () {
      list.outerHTML = '<p class="error">Não foi possível carregar os textos. ' +
        "Se abriste o ficheiro diretamente, usa o servidor local (serve.ps1).</p>";
    });
  }

  if (page === "post") {
    var box = document.getElementById("article");
    var slug = new URLSearchParams(location.search).get("p");
    if (!slug || !/^[\w-]+$/.test(slug)) {
      box.innerHTML = '<p class="error">Texto não encontrado.</p>';
      return;
    }
    Promise.all([
      fetchOrFail("posts/index.json", true),
      fetchOrFail("posts/" + slug + ".md", false)
    ]).then(function (res) {
      var meta = res[0].filter(function (p) { return p.slug === slug; })[0] || {};
      var body = res[1].replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n?/, "");
      document.title = (meta.titulo ? meta.titulo + " — " : "") + "Depende da Perspectiva";
      box.innerHTML =
        '<header class="article-header"><div class="meta">' + formatDate(meta.data) +
        tagsHtml(meta.tags) + "</div><h1>" + esc(meta.titulo || slug) + "</h1></header>" +
        '<div class="prose">' + marked.parse(body) + "</div>";
    }).catch(function () {
      box.innerHTML = '<p class="error">Texto não encontrado.</p>';
    });
  }
})();

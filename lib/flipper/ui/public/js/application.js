document.addEventListener("DOMContentLoaded", function () {
  document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(function(el) {
    new bootstrap.Tooltip(el)
  })

  document.querySelectorAll(".js-toggle-trigger").forEach(function (trigger) {
    trigger.addEventListener("click", function () {
      var container = this.closest(".js-toggle-container");
      container.classList.toggle("toggle-on");
    });
  });

  document.querySelectorAll("*[data-confirmation-text]").forEach(function (element) {
    element.addEventListener("click", function (e) {
      var expected = element.getAttribute("data-confirmation-text");
      var actual = prompt(element.getAttribute("data-confirmation-prompt"));

      if (expected !== actual) {
        e.preventDefault();
      }
    });
  });

  var search = document.getElementById("feature-search");
  if (search) {
    var items = Array.prototype.slice.call(document.querySelectorAll("[data-feature-search-item]"));
    var texts = items.map(function (item) {
      return item.textContent.toLowerCase().replace(/\s+/g, " ");
    });
    var empty = document.querySelector("[data-feature-search-empty]");
    var status = document.querySelector("[data-feature-search-status]");

    var escapeRegExp = function (term) {
      return term.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    };

    var unhighlight = function (item) {
      var marks = item.querySelectorAll("mark");
      if (!marks.length) return;
      marks.forEach(function (mark) {
        mark.replaceWith(document.createTextNode(mark.textContent));
      });
      item.normalize();
    };

    var highlight = function (item, pattern) {
      var walker = document.createTreeWalker(item, NodeFilter.SHOW_TEXT);
      var nodes = [];
      while (walker.nextNode()) {
        if (pattern.test(walker.currentNode.nodeValue)) nodes.push(walker.currentNode);
        pattern.lastIndex = 0;
      }
      nodes.forEach(function (node) {
        var fragment = document.createDocumentFragment();
        node.nodeValue.split(pattern).forEach(function (part, index) {
          if (!part) return;
          if (index % 2) {
            var mark = document.createElement("mark");
            mark.textContent = part;
            fragment.appendChild(mark);
          } else {
            fragment.appendChild(document.createTextNode(part));
          }
        });
        node.parentNode.replaceChild(fragment, node);
      });
    };

    var filter = function () {
      var query = search.value.trim();
      var terms = query.toLowerCase().split(/\s+/).filter(Boolean);
      var pattern = terms.length ? new RegExp("(" + terms.map(escapeRegExp).join("|") + ")", "gi") : null;
      var shown = 0;

      items.forEach(function (item, index) {
        var match = terms.every(function (term) { return texts[index].indexOf(term) !== -1; });
        item.hidden = !match;
        unhighlight(item);
        if (match) {
          shown++;
          if (pattern) highlight(item, pattern);
        }
      });

      empty.hidden = shown > 0;
      status.textContent = terms.length ? shown + " of " + items.length + " features match" : "";

      var url = new URL(window.location.href);
      if (query) {
        url.searchParams.set("q", query);
      } else {
        url.searchParams.delete("q");
      }
      window.history.replaceState(null, "", url);
    };

    search.addEventListener("input", filter);
    search.addEventListener("keydown", function (e) {
      if (e.key === "Escape") {
        search.value = "";
        filter();
      }
    });
    document.addEventListener("keydown", function (e) {
      var tag = document.activeElement && document.activeElement.tagName;
      if (e.key === "/" && !e.metaKey && !e.ctrlKey && !e.altKey && tag !== "INPUT" && tag !== "TEXTAREA" && tag !== "SELECT") {
        e.preventDefault();
        search.focus();
      }
    });

    document.querySelector("[data-feature-search]").hidden = false;
    if (search.value) filter();
  }
});

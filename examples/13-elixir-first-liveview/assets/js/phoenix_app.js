import "phoenix_html";
import {Socket} from "phoenix";
import {LiveSocket} from "phoenix_live_view";
import "./app.js";

// Fallback bootstrap in case the Haxe client bundle did not connect LiveView.
if (!window.liveSocket) {
  let csrfMeta = document.querySelector("meta[name='csrf-token']");
  let csrfToken = csrfMeta ? csrfMeta.getAttribute("content") : "";
  let hooks = window.Hooks || {};
  let liveSocket = new LiveSocket("/live", Socket, {
    params: {_csrf_token: csrfToken},
    hooks
  });

  liveSocket.connect();
  window.liveSocket = liveSocket;
}

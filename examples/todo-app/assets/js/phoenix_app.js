// Phoenix/LiveView bootstrap + Haxe app integration
import "phoenix_html";
import {Socket} from "phoenix";
import {LiveSocket} from "phoenix_live_view";

// Pull in the Haxe-generated client bundle so client behaviors load
import "./app.js";

// Optional: When the Haxe client bundle is compiled with `-D todoapp_hx_live_socket_bootstrap`,
// it may bootstrap LiveSocket itself. Keep a guard to prevent double-connect.
if (!window.liveSocket) {
  const csrfToken = document
    .querySelector("meta[name='csrf-token']")
    ?.getAttribute("content");
  const hooks = window.Hooks || {};
  const liveSocket = new LiveSocket("/live", Socket, {
    params: {_csrf_token: csrfToken},
    hooks,
  });

  liveSocket.connect();
  window.liveSocket = liveSocket;
}

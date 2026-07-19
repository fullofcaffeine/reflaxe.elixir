// Canonical Phoenix/Vite entry. The Genes bundle is loaded after this module's
// static imports so opt-in integrations can initialize shared hooks first.
import "phoenix_html";
import {Socket} from "phoenix";
import {LiveSocket} from "phoenix_live_view";
// BEGIN reflaxe_elixir live_react_import
import {reactHooks} from "./live-react-hooks.js"
// END reflaxe_elixir live_react_import
// BEGIN reflaxe_elixir live_react_window_hooks
window.Hooks = {...(window.Hooks || {}), ...reactHooks}
// END reflaxe_elixir live_react_window_hooks

async function bootPhoenix() {
  // Haxe owns the primary typed LiveSocket bootstrap. Dynamic loading lets the
  // public LiveReact lifecycle initialize window.Hooks before Boot.main() runs.
  await import("./hx_app.js");

  // Keep the ordinary Phoenix bootstrap as a useful fallback when the Haxe
  // client intentionally omits or cannot complete LiveSocket initialization.
  if (!window.liveSocket) {
    const csrfToken = document
      .querySelector("meta[name='csrf-token']")
      ?.getAttribute("content");
    const liveSocket = new LiveSocket("/live", Socket, {
      params: {_csrf_token: csrfToken},
      hooks: window.Hooks || {},
    });

    liveSocket.connect();
    window.liveSocket = liveSocket;
  }
}

void bootPhoenix();

// Phoenix/LiveView bootstrap + Haxe hooks integration
import "phoenix_html";
import {Socket} from "phoenix";
import {LiveSocket} from "phoenix_live_view";

// Load Haxe-generated hooks without overriding this bootstrap
import "./hx_app.js";

const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content");
const hooks = window.Hooks || {};
const liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks});

liveSocket.connect();
window.liveSocket = liveSocket;

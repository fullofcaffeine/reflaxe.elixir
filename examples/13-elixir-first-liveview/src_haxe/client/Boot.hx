package client;

import StringTools;
import phoenix.Socket;
import phoenix.live_view.LiveSocket;
import phoenix.live_view.LiveSocket.LiveSocketParams;

/**
 * Typed LiveView client bootstrap compiled by Genes.
 */
class Boot {
	static function readCsrfToken():Null<String> {
		var meta = js.Browser.document.querySelector("meta[name='csrf-token']");
		return meta == null ? null : meta.getAttribute("content");
	}

	static function connectLiveView():Void {
		var params:LiveSocketParams = {};
		var csrfToken = readCsrfToken();
		if (csrfToken != null && StringTools.trim(csrfToken) != "") {
			params._csrf_token = csrfToken;
		}

		var hooks = js.Syntax.code("window.Hooks || {}");
		var liveSocket = new LiveSocket("/live", Socket, {
			params: params,
			hooks: hooks
		});

		liveSocket.connect();
		js.Syntax.code("window.liveSocket = {0}", liveSocket);
	}

	public static function main():Void {
		connectLiveView();
	}
}

package client.hooks;

import phoenix.live_view.HookContext;
import js.Browser;
import js.html.Event;

class CopyToClipboardHook {
	public static function mounted(hook:HookContext):Void {
		var el = hook.el;
		el.addEventListener("click", function(_:Event):Void {
			var text = el.getAttribute("data-copy-text");
			if (text == null || text == "") {
				return;
			}

			copyText(text, function(_success:Bool):Void {
				var eventName = el.getAttribute("data-copied-event");
				if (eventName == null || eventName == "") {
					eventName = "clipboard_copied";
				}

				var message = el.getAttribute("data-copied-message");
				if (message == null || message == "") {
					message = "Copied.";
				}

				// LiveView hook callbacks can throw host JS values; local UI feedback still runs.
				try {
					if (hook.pushEvent != null) {
						hook.pushEvent(eventName, {message: message});
					}
				} catch (_:Dynamic) {}

				el.classList.add("copied");
				Browser.window.setTimeout(function():Void {
					el.classList.remove("copied");
				}, 800);
			});
		});
	}

	static function copyText(text:String, done:Bool->Void):Void {
		var clipboard = Browser.navigator.clipboard;
		if (clipboard != null) {
			// Clipboard writes throw browser-specific JS values; any failure uses the textarea fallback.
			try {
				var promise = clipboard.writeText(text);
				promise.then(function(_):Void {
					done(true);
				}).catchError(function(_):Void {
					fallbackCopy(text, done);
				});
				return;
			} catch (_:Dynamic) {}
		}

		fallbackCopy(text, done);
	}

	static function fallbackCopy(text:String, done:Bool->Void):Void {
		var tmp = Browser.document.createTextAreaElement();
		tmp.value = text;
		tmp.setAttribute("readonly", "");
		tmp.style.position = "absolute";
		tmp.style.left = "-9999px";
		Browser.document.body.appendChild(tmp);
		tmp.select();

		var ok = false;
		// execCommand is a legacy browser API and may throw host JS values.
		try {
			ok = Browser.document.execCommand("copy");
		} catch (_:Dynamic) {}

		// DOM removal can throw host JS values; parentNode fallback keeps cleanup deterministic.
		try {
			tmp.remove();
		} catch (_:Dynamic) {
			if (tmp.parentNode != null) {
				tmp.parentNode.removeChild(tmp);
			}
		}

		done(ok);
	}
}

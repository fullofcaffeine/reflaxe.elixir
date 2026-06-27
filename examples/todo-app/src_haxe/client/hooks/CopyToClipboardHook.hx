package client.hooks;

import phoenix.live_view.HookContext;
import phoenix.live_view.HookContextTools;
import js.Browser;
import js.html.Event;
import shared.liveview.HookEvents;

class CopyToClipboardHook {
	public static function mounted(hook:HookContext):Void {
		var el = hook.el;
		el.addEventListener("click", function(_:Event):Void {
			var text = el.getAttribute("data-copy-text");
			if (text == null || text == "") {
				return;
			}

			copyText(text, function(_success:Bool):Void {
				var message = el.getAttribute("data-copied-message");
				if (message == null || message == "") {
					message = HookEvents.DefaultClipboardCopiedMessage;
				}

				// LiveView hook callbacks can throw host JS values; local UI feedback still runs.
				try {
					HookContextTools.pushEncoded(hook, HookEvents.encodeClientPush(HookEvents.clipboardCopied(message)));
				} catch (_:Dynamic) {
					// JS hook callback failures are host values; ignore to preserve local copy feedback.
				}

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
			} catch (_:Dynamic) {
				// Browser clipboard errors are host values; fall back to the legacy copy path.
			}
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
		} catch (_:Dynamic) {
			// Legacy browser copy errors are host values; report failure through `ok`.
		}

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

import {Register} from "../../genes/Register.js"

const $global = Register.$global

export const CopyToClipboardHook = Register.global("$hxClasses")["client.hooks.CopyToClipboardHook"] = 
class CopyToClipboardHook {
	static mounted(hook) {
		let el = hook.el;
		el.addEventListener("click", function (_) {
			let text = el.getAttribute("data-copy-text");
			if (text == null || text == "") {
				return;
			};
			CopyToClipboardHook.copyText(text, function (_success) {
				let eventName = el.getAttribute("data-copied-event");
				if (eventName == null || eventName == "") {
					eventName = "clipboard_copied";
				};
				let message = el.getAttribute("data-copied-message");
				if (message == null || message == "") {
					message = "Copied.";
				};
				try {
					if (hook.pushEvent != null) {
						hook.pushEvent(eventName, {"message": message});
					};
				}catch (_g) {
				};
				el.classList.add("copied");
				window.setTimeout(function () {
					el.classList.remove("copied");
				}, 800);
			});
		});
	}
	static copyText(text, done) {
		let clipboard = Register.$global.navigator.clipboard;
		if (clipboard != null && Object.prototype.hasOwnProperty.call(clipboard, "writeText")) {
			try {
				let promise = clipboard.writeText(text);
				promise.then(function (_) {
					done(true);
					return null;
				})["catch"](function (_) {
					CopyToClipboardHook.fallbackCopy(text, done);
					return null;
				});
				return;
			}catch (_g) {
			};
		};
		CopyToClipboardHook.fallbackCopy(text, done);
	}
	static fallbackCopy(text, done) {
		let tmp = window.document.createElement("textarea");
		tmp.value = text;
		tmp.setAttribute("readonly", "");
		tmp.style.position = "absolute";
		tmp.style.left = "-9999px";
		window.document.body.appendChild(tmp);
		tmp.select();
		let ok = false;
		try {
			ok = window.document.execCommand("copy");
		}catch (_g) {
		};
		try {
			tmp.remove();
		}catch (_g) {
			if (tmp.parentNode != null) {
				tmp.parentNode.removeChild(tmp);
			};
		};
		done(ok);
	}
	static get __name__() {
		return "client.hooks.CopyToClipboardHook"
	}
	get __class__() {
		return CopyToClipboardHook
	}
}


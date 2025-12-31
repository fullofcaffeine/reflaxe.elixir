package client.hooks;

import client.extern.PhoenixHookContext;
import js.Browser;
import js.html.Event;
import js.html.TextAreaElement;
import js.lib.Promise;

class CopyToClipboardHook {
  public static function mounted(hook: PhoenixHookContext): Void {
    var el = hook.el;
    el.addEventListener("click", function(_: Event): Void {
      var text = el.getAttribute("data-copy-text");
      if (text == null || text == "") {
        return;
      }

      copyText(text, function(_success: Bool): Void {
        var eventName = el.getAttribute("data-copied-event");
        if (eventName == null || eventName == "") {
          eventName = "clipboard_copied";
        }

        var message = el.getAttribute("data-copied-message");
        if (message == null || message == "") {
          message = "Copied.";
        }

        try {
          if (hook.pushEvent != null) {
            hook.pushEvent(eventName, {message: message});
          }
        } catch (_: Dynamic) {}

        el.classList.add("copied");
        Browser.window.setTimeout(function(): Void {
          el.classList.remove("copied");
        }, 800);
      });
    });
  }

  static function copyText(text: String, done: Bool->Void): Void {
    var clipboard: Dynamic = untyped Browser.navigator.clipboard;
    if (clipboard != null && Reflect.hasField(clipboard, "writeText")) {
      try {
        var promise: Promise<Dynamic> = cast clipboard.writeText(text);
        promise
          .then(function(_): Dynamic {
            done(true);
            return null;
          })
          .catchError(function(_): Dynamic {
            fallbackCopy(text, done);
            return null;
          });
        return;
      } catch (_: Dynamic) {}
    }

    fallbackCopy(text, done);
  }

  static function fallbackCopy(text: String, done: Bool->Void): Void {
    var tmp: TextAreaElement = cast Browser.document.createElement("textarea");
    tmp.value = text;
    tmp.setAttribute("readonly", "");
    tmp.style.position = "absolute";
    tmp.style.left = "-9999px";
    Browser.document.body.appendChild(tmp);
    tmp.select();

    var ok = false;
    try {
      ok = Browser.document.execCommand("copy");
    } catch (_: Dynamic) {}

    try {
      tmp.remove();
    } catch (_: Dynamic) {
      if (tmp.parentNode != null) {
        tmp.parentNode.removeChild(tmp);
      }
    }

    done(ok);
  }
}

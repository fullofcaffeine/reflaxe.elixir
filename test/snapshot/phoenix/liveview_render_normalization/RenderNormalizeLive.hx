package;

import phoenix.Phoenix.LiveView;
import phoenix.Phoenix.Socket;

@:liveview
class RenderNormalizeLive {
    public static function mount(params: Dynamic, session: Dynamic, socket: Socket<Dynamic>): Dynamic {
        return { ok: socket };
    }

    // Intentionally use a non-standard arg name to verify normalization to render(assigns)
    public static function render(a: Dynamic): String {
        return '<div>Render normalization</div>';
    }
}


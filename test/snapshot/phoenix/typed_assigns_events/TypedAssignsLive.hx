package;

import phoenix.Phoenix.LiveView;
import phoenix.Phoenix.Socket;

typedef TA = {
    var count: Int;
    var userName: String;
}

@:liveview
class TypedAssignsLive {
    public static function mount(params: Dynamic, session: Dynamic, socket: Socket<TA>): Dynamic {
        socket = LiveView.assign(socket, "count", 0);
        socket = LiveView.assign(socket, "user_name", "");
        return { ok: socket };
    }

    public static function handle_event_set_name(params: { name: String; }, socket: Socket<TA>): Dynamic {
        socket = LiveView.assign(socket, "user_name", params.name);
        return { noreply: socket };
    }

    public static function handle_event_reset(_params: Dynamic, socket: Socket<TA>): Dynamic {
        socket = LiveView.assign(socket, "user_name", "");
        socket = LiveView.assign(socket, "count", 0);
        return { noreply: socket };
    }

    public static function render(assigns: Dynamic): String {
        return '<div>\n  <h1>User: <%= @user_name %></h1>\n  <h2>Count: <%= @count %></h2>\n  <button phx-click="reset">Reset</button>\n</div>';
    }
}


package fixtures.hxxindex;

import HXX;
import elixir.types.Term;
import phoenix.LiveSocket;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.LiveView;
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.Socket;

typedef Assigns = {
    var count: Int;
}

/**
 * FixtureLiveView
 *
 * Minimal @:liveview module for tooling.
 *
 * - Uses `phx-click=${EventName.Increment}` and `phx-hook=${HookName.Ping}` so the compiler can derive
 *   per-module event/hook usage for editor tooling.
 * - Uses dot-components and slot tags so the tooling index can report per-template component/slot usage.
 */
@:liveview
class FixtureLiveView {
    @:native("handle_event")
    public static function handle_event(event: String, _params: Term, socket: Socket<Assigns>): HandleEventResult<Assigns> {
        return switch (event) {
            case EventName.Increment:
                var nextCount = socket.assigns.count + 1;
                NoReply(LiveView.assign(socket, "count", nextCount));
            case _:
                NoReply(socket);
        }
    }

    public function mount(_params: Term, _session: Term, socket: Socket<Assigns>): MountResult<Assigns> {
        socket = LiveView.assign(socket, "count", 0);
        return MountResult.Ok(socket);
    }

    public function render(assigns: Assigns): String {
        return HXX.hxx('
          <div id="fixture-liveview" phx-hook=${HookName.Ping}>
            <.card title="Hello">
              <:header label="Hi">Hi</:header>
              <button phx-click=${EventName.Increment}>+</button>
              <span>${assigns.count}</span>
            </.card>
          </div>
        ');
    }
}

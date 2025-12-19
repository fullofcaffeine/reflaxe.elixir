package;

import HXX;
import elixir.types.Term;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.LiveView;
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.Socket;

/**
 * LiveView fast_boot + hygiene gating smoke test.
 *
 * WHAT
 * - Small @:liveview module that exercises:
 *   - assign/assigns usage
 *   - handle_event with basic state transitions
 *   - HXX.hxx-based template rendering
 *
 * WHY
 * - Used with -D fast_boot and -D disable_hygiene_final to validate that
 *   the "fast" transformer profile still generates correct, idiomatic
 *   Elixir output for LiveView modules without running final cosmetic
 *   hygiene passes.
 *
 * HOW
 * - Snapshot harness compiles this module and compares the generated
 *   Elixir against intended output. Differences here indicate a
 *   behavior (not just cosmetic) change in the fast profile.
 */
@:native("TestAppWeb.FastBootLive")
@:liveview
class Main {
  public static function mount(params: Term, session: Term, socket: Socket<FastBootAssigns>): MountResult<FastBootAssigns> {
    // Exercise assign/assigns transforms without relying on raw param maps.
    socket = LiveView.assign(socket, "count", 0);
    socket = LiveView.assign(socket, "active", false);
    return Ok(socket);
  }

  public static function handle_event(event: String, params: Term, socket: Socket<FastBootAssigns>): HandleEventResult<FastBootAssigns> {
    // Event names are generic; no app-specific heuristics.
    switch (event) {
      case "increment":
        var next = socket.assigns.count + 1;
        socket = LiveView.assign(socket, "count", next);
      case "toggle":
        socket = LiveView.assign(socket, "active", !socket.assigns.active);
      case _:
    }
    return NoReply(socket);
  }

  /**
   * Render a small template using HXX.hxx to ensure HEEx transforms stay
   * correct under fast_boot gating.
   */
  public static function render(assigns:{ count:Int, active:Bool }):String {
    return HXX.hxx('
      <div>
        <span data-testid="count"><%= @count %></span>
        <span data-testid="status" class={if @active, do: "on", else: "off"}>status</span>
      </div>
    ');
  }

  static inline function ignore<T>(value:T):Void {}
}

typedef FastBootAssigns = {
  var count: Int;
  var active: Bool;
}

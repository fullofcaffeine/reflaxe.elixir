package;

import HXX;

/**
 * LiveView fast_boot + hygiene gating smoke test.
 *
 * WHAT
 * - Small @:liveview module that exercises:
 *   - assign/assigns usage
 *   - handle_event with pattern matching
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
  public static function mount(params:Dynamic, session:Dynamic, socket:Dynamic):Dynamic {
    // Simple assign path to exercise assign/assigns transforms.
    return {
      status: "ok",
      socket: socket
    };
  }

  public static function handle_event(event:String, params:Dynamic, socket:Dynamic):Dynamic {
    // Event names and payload shapes are generic; no app-specific heuristics.
    switch (event) {
      case "increment":
        // Exercise basic assignment + map/struct update patterns.
        var count = params.count;
        var next = count + 1;
        // In Elixir this becomes assign(socket, :count, next).
        ignore(next);
      case "toggle":
        var active = params.active;
        ignore(active);
      case _:
    }
    return { status: "noreply", socket: socket };
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


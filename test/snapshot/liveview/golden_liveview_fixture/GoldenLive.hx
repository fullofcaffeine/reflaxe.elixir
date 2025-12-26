package;

import HXX;
import elixir.types.Term;
import phoenix.LiveSocket;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.HandleInfoResult;
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.Socket;

typedef GoldenAssigns = {
    var counter: Int;
    var search_query: String;
    var sort_by: String;
    var selected_tags: Array<String>;
}

enum GoldenMessage {
    ExternalIncrement(amount: Int);
    ExternalReset;
}

/**
 * GoldenLive
 *
 * WHAT
 * - A minimal, runnable LiveView fixture used by snapshot tests to guard
 *   stable `handle_event/3` and `handle_info/2` shapes.
 *
 * WHY
 * - The todo-app exercises LiveView deeply, but its output is too large and too app-specific
 *   to serve as a stable, focused regression signal for callback shaping and naming.
 * - This fixture keeps coverage generic (no domain heuristics) while still validating
 *   event/params extraction and typed assigns updates.
 *
 * HOW
 * - Implements the canonical Phoenix callback names in Haxe (`handle_event`) and a
 *   Haxe-idiomatic variant (`handleInfo`) that must be normalized to `handle_info`.
 * - Uses LiveSocket macros to validate assign key conversion (camelCase → snake_case).
 *
 * EXAMPLES
 * Haxe:
 *   handle_event("toggle_tag", params, socket) -> updates `selectedTags`.
 * Elixir:
 *   def handle_event("toggle_tag", params, socket) do
 *     {:noreply, assign(socket, :selected_tags, ...)}
 *   end
 */
@:native("TestAppWeb.GoldenLive")
@:liveview
class GoldenLive {
    public static function mount(_params: Term, _session: Term, socket: Socket<GoldenAssigns>): MountResult<GoldenAssigns> {
        var live: LiveSocket<GoldenAssigns> = socket;
        live = live.merge({
            counter: 0,
            search_query: "",
            sort_by: "created",
            selected_tags: []
        });
        return Ok(live);
    }

    public static function handle_event(event: String, params: Term, socket: Socket<GoldenAssigns>): HandleEventResult<GoldenAssigns> {
        var live: LiveSocket<GoldenAssigns> = socket;

        if (event == "increment") {
            live = live.update(_.counter, (n) -> n + 1);
        } else if (event == "set_sort") {
            var sortByValue: Null<String> = cast Reflect.field(params, "sort_by");
            live = live.assign(_.sort_by, sortByValue != null ? sortByValue : "created");
        } else if (event == "search") {
            var queryValue: Null<String> = cast Reflect.field(params, "query");
            live = live.assign(_.search_query, queryValue != null ? queryValue : "");
        } else if (event == "toggle_tag") {
            var tag: Null<String> = cast Reflect.field(params, "tag");
            if (tag != null) {
                var currentTags = socket.assigns.selected_tags;
                var updatedTags = if (currentTags.contains(tag)) {
                    currentTags.filter((t) -> t != tag);
                } else {
                    elixir.List.insertAt(currentTags, 0, tag);
                };
                live = live.assign(_.selected_tags, updatedTags);
            }
        } else if (event == "set_priority") {
            var id = extractId(params);
            live = live.update(_.counter, (n) -> n + id);
        }

        return NoReply(live);
    }

    public static function handleInfo(msg: GoldenMessage, socket: Socket<GoldenAssigns>): HandleInfoResult<GoldenAssigns> {
        var live: LiveSocket<GoldenAssigns> = socket;
        var nextSocket = switch (msg) {
            case ExternalIncrement(amount):
                live.update(_.counter, (n) -> n + amount);
            case ExternalReset:
                live.merge({
                    counter: 0,
                    search_query: "",
                    selected_tags: []
                });
        };
        return NoReply(nextSocket);
    }

    public static function render(assigns: GoldenAssigns): String {
        return HXX.hxx('<div id="golden-live">
  <h1>Counter: ${assigns.counter}</h1>
  <p>Sort: ${assigns.sort_by}</p>
  <p>Query: ${assigns.search_query}</p>
  <p>Tags: ${assigns.selected_tags}</p>
  <button phx-click="increment">+</button>
</div>');
    }

    static function extractId(params: Term): Int {
        var idValue: Term = Reflect.field(params, "id");
        if (idValue == null) return 0;
        if (elixir.Kernel.isInteger(idValue)) return cast idValue;
        if (elixir.Kernel.isBinary(idValue)) {
            var parsed = Std.parseInt(cast idValue);
            return parsed != null ? parsed : 0;
        }
        return 0;
    }
}

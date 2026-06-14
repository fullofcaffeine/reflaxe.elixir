package live;

import HXX.*;
import elixir.ElixirMap;
import elixir.Kernel;
import elixir.types.Term;
import haxe.functional.Result;
import phoenix.Phoenix.EventParams;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.MountParams;
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.Session;
import phoenix.Phoenix.Socket;

typedef SearchAssigns = {
	query:String,
	catalog:Array<String>,
	visible:Array<String>,
	result_count:Int,
	validation_error:Null<String>
}

/**
 * Typed Elixir-first LiveView example.
 */
// @:native (class): pins the generated Elixir module name to match Phoenix/Ecto runtime expectations.

@:native("ElixirFirstLiveviewWeb.SearchLive")
// @:liveview: compiles this module as a Phoenix LiveView with LiveView callback semantics.
@:liveview
class SearchLive {
	public static function mount(_params:MountParams, _session:Session, socket:Socket<SearchAssigns>):MountResult<SearchAssigns> {
		var catalog = [
			"Phoenix LiveView",
			"Ecto Changesets",
			"Pattern Matching",
			"GenServer",
			"Supervision Trees",
			"PubSub",
			"Presence",
			"Telemetry"
		];

		var initialAssigns:SearchAssigns = {
			query: "",
			catalog: catalog,
			visible: catalog,
			result_count: catalog.length,
			validation_error: null
		};

		return Ok(socket.assign(initialAssigns));
	}

	public static function handle_event(event:String, params:EventParams, socket:Socket<SearchAssigns>):HandleEventResult<SearchAssigns> {
		if (event != "search") {
			return NoReply(socket);
		}

		var rawQuery:Term = ElixirMap.get(params, "query");
		var query:String = (rawQuery != null && Kernel.isBinary(rawQuery)) ? cast rawQuery : "";

		return NoReply(applySearch(socket, query));
	}

	static function applySearch(socket:Socket<SearchAssigns>, query:String):Socket<SearchAssigns> {
		return switch (SearchDomain.apply(query, socket.assigns.catalog)) {
			case Ok(state):
				socket.assign({
					query: state.query,
					visible: state.visible,
					result_count: state.result_count,
					validation_error: null
				});
			case Error(reason):
				socket.assign({
					query: socket.assigns.query,
					visible: socket.assigns.visible,
					result_count: socket.assigns.result_count,
					validation_error: reason
				});
		}
	}

	public static function render(assigns:SearchAssigns):String {
		return <main class="mx-auto max-w-3xl p-6">
	            <section class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
	                <header class="mb-4">
	                    <p class="text-xs uppercase tracking-[0.14em] text-slate-500">Elixir-first typed mode</p>
	                    <h1 class="text-2xl font-semibold text-slate-900">Live search with typed boundaries</h1>
	                    <p class="mt-1 text-sm text-slate-600">
	                        Uses Phoenix/Elixir extern surfaces and Result-based domain flow from Haxe.
	                    </p>
	                </header>

	                <form phx-change="search" class="mb-3">
	                    <input
	                        type="text"
	                        name="query"
	                        value=${assigns.query}
	                        placeholder="Search BEAM topics..."
	                        class="w-full rounded-lg border border-slate-300 px-3 py-2"
	                    />
	                </form>

	                <p class="mb-3 text-sm text-slate-600" data-testid="result-count">
	                    ${assigns.result_count} result(s)
	                </p>

	                <if ${assigns.validation_error != null}>
	                    <p class="mb-3 rounded-md border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
	                        ${assigns.validation_error}
	                    </p>
	                </if>

	                <ul class="space-y-2" data-testid="search-results">
	                    <for ${entry in assigns.visible}>
	                        <li class="rounded-md border border-slate-200 px-3 py-2 text-slate-800">${entry}</li>
	                    </for>
	                </ul>
	            </section>
	        </main>;
	}
}

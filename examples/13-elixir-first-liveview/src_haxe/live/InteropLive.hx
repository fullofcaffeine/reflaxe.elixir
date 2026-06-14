package live;

import HXX.*;
import elixir.ElixirMap;
import elixir.Kernel;
import elixir.types.Term;
import interop.LegacySlugBridge;
import phoenix.Phoenix.EventParams;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.MountParams;
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.Session;
import phoenix.Phoenix.Socket;

typedef InteropAssigns = {
	input:String,
	normalized:String
}

/**
 * InteropLive
 *
 * WHAT
 * - Dedicated page that demonstrates consuming a hand-written Elixir module from Haxe.
 *
 * WHY
 * - Most app logic should stay Haxe-first. This page shows the intentional boundary pattern
 *   for cases where an existing pure-Elixir module must be called.
 *
 * HOW
 * - Uses `interop.LegacySlugBridge`, which delegates to `interop.LegacySlugExtern`.
 */
@:native("ElixirFirstLiveviewWeb.InteropLive")
@:liveview
class InteropLive {
	public static function mount(params:MountParams, session:Session, socket:Socket<InteropAssigns>):MountResult<InteropAssigns> {
		var initialInput = "Haxe + Elixir Interop";
		var normalized = LegacySlugBridge.normalizeLabel(initialInput);
		return Ok(socket.assign({
			input: initialInput,
			normalized: normalized
		}));
	}

	public static function handle_event(event:String, params:EventParams, socket:Socket<InteropAssigns>):HandleEventResult<InteropAssigns> {
		if (event != "normalize") {
			return NoReply(socket);
		}

		var rawInput:Term = ElixirMap.get(params, "input");
		var input = (rawInput != null && Kernel.isBinary(rawInput)) ? cast rawInput : "";
		var normalized = LegacySlugBridge.normalizeLabel(input);
		return NoReply(socket.assign({
			input: input,
			normalized: normalized
		}));
	}

	public static function render(assigns:InteropAssigns):String {
		return <main class="mx-auto max-w-3xl p-6">
	            <section class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
	                <header class="mb-4">
	                    <p class="text-xs uppercase tracking-[0.14em] text-slate-500">Interop sample</p>
	                    <h1 class="text-2xl font-semibold text-slate-900">Handwritten Elixir module from Haxe</h1>
	                    <p class="mt-1 text-sm text-slate-600">
	                        This page calls <code>ElixirFirstLiveview.LegacySlug.normalize/1</code>
	                        through a typed Haxe extern + wrapper boundary.
	                    </p>
	                </header>

	                <form phx-change="normalize" class="mb-4">
	                    <label class="mb-1 block text-sm text-slate-700" for="slug-input">Input label</label>
	                    <input
	                        id="slug-input"
	                        type="text"
	                        name="input"
	                        value=${assigns.input}
	                        class="w-full rounded-lg border border-slate-300 px-3 py-2"
	                    />
	                </form>

	                <p class="text-sm text-slate-600">Normalized slug</p>
	                <p class="font-mono text-sm text-slate-900" data-testid="normalized-slug">${assigns.normalized}</p>
	            </section>
	        </main>;
	}
}

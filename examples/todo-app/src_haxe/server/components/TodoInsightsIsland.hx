package server.components;

import elixir.types.Term;
import phoenix.types.Assigns;

private typedef TodoInsightsAssigns = {
	var id:String;
	var title:String;
	var total:Int;
	var completed:Int;
	var pending:Int;
	var visible:Int;
	var filter:String;
}

/**
 * Typed Phoenix boundary for one fixed stock-LiveReact component.
 *
 * The native summary is deliberately useful on its own. Removing LiveReact or
 * failing to mount the island leaves current counts and the ordinary LiveView
 * filter controls intact.
 */
@:native("TodoAppWeb.ReactIslands.TodoInsights")
@:component
class TodoInsightsIsland {
	@:component
	public static function render(assigns:Assigns<TodoInsightsAssigns>):String {
		return <section data-testid="todo-insights-shell"
			class="mb-8 overflow-hidden rounded-2xl border border-indigo-200 bg-white shadow-lg dark:border-indigo-800 dark:bg-gray-800">
			<div class="border-b border-indigo-100 bg-gradient-to-r from-indigo-50 via-blue-50 to-cyan-50 px-6 py-5 dark:border-indigo-900 dark:from-indigo-950/60 dark:via-blue-950/50 dark:to-cyan-950/40">
				<div class="flex flex-wrap items-start justify-between gap-3">
					<div>
						<p class="text-xs font-bold uppercase tracking-[0.2em] text-indigo-600 dark:text-indigo-300">Haxe-authored React island</p>
						<h2 class="mt-1 text-xl font-bold text-gray-900 dark:text-white">${assigns.title}</h2>
					</div>
					<span class="rounded-full border border-indigo-200 bg-white/80 px-3 py-1 text-xs font-semibold text-indigo-700 dark:border-indigo-700 dark:bg-gray-900/60 dark:text-indigo-200">stock LiveReact · client only</span>
				</div>
				<p data-testid="todo-insights-native-fallback" class="mt-3 text-sm text-gray-600 dark:text-gray-300">
					LiveView summary: ${assigns.visible} visible of ${assigns.total}; ${assigns.completed} completed and ${assigns.pending} pending.
				</p>
			</div>

			<div class="p-6">
				<LiveReact.react
					id=${assigns.id}
					name="TodoInsights"
					title=${assigns.title}
					total=${assigns.total}
					completed=${assigns.completed}
					pending=${assigns.pending}
					visible=${assigns.visible}
					filter=${assigns.filter}
					ssr=${false}
				/>
			</div>
		</section>;
	}
}

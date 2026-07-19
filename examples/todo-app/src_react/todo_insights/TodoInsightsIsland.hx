package todo_insights;

import genes.react.Element;
import genes.react.JSX.*;
import genes.ts.Imports;
import haxe.DynamicAccess;
import shared.liveview.TodoInsightsEvents.TodoInsightsFilterInput;

enum abstract TodoInsightsFilter(String) to String {
	var All = "all";
	var Active = "active";
	var Completed = "completed";
}

typedef TodoInsightsInput = {
	final title:String;
	final total:Int;
	final completed:Int;
	final pending:Int;
	final visible:Int;
	final filter:TodoInsightsFilter;
}

typedef TodoInsightsProps = {
	> TodoInsightsInput,
	final onFilter:TodoInsightsFilter->Void;
}

/** Stock LiveReact capability narrowed to the one event operation we use. */
typedef LiveReactPushEvent = (event:String, payload:DynamicAccess<Dynamic>) -> Void;

typedef PushTodoInsightsFilter = (pushEvent:LiveReactPushEvent, input:TodoInsightsFilterInput) -> Void;
private final pushSetFilter:PushTodoInsightsFilter = Imports.namedImport("./todo-insights-events.generated.js", "pushSetFilter");

/** Inner application component: closed semantic props, with no raw LiveView bridge. */
@:expose
function TodoInsights(props:TodoInsightsProps):Element {
	function buttonClass(candidate:TodoInsightsFilter):String {
		var base = "rounded-xl border px-4 py-3 text-left transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500";
		var inactive = base
			+ " border-gray-200 bg-white text-gray-700 hover:border-indigo-300 hover:bg-indigo-50"
			+ " dark:border-gray-700 dark:bg-gray-900 dark:text-gray-200 dark:hover:border-indigo-700 dark:hover:bg-indigo-950/40";

		return candidate == props.filter ? base + " border-indigo-500 bg-indigo-600 text-white shadow-md" : inactive;
	}

	return <div data-testid="todo-insights" data-active-filter={props.filter}>
		<div className="grid gap-3 sm:grid-cols-3">
			<div className="rounded-xl bg-blue-50 p-4 dark:bg-blue-950/40">
				<div className="text-2xl font-black text-blue-700 dark:text-blue-300">{props.total}</div>
				<div className="text-xs font-bold uppercase tracking-wider text-blue-600/80 dark:text-blue-300/80">Total</div>
			</div>
			<div className="rounded-xl bg-emerald-50 p-4 dark:bg-emerald-950/40">
				<div className="text-2xl font-black text-emerald-700 dark:text-emerald-300">{props.completed}</div>
				<div className="text-xs font-bold uppercase tracking-wider text-emerald-600/80 dark:text-emerald-300/80">Completed</div>
			</div>
			<div className="rounded-xl bg-amber-50 p-4 dark:bg-amber-950/40">
				<div className="text-2xl font-black text-amber-700 dark:text-amber-300">{props.pending}</div>
				<div className="text-xs font-bold uppercase tracking-wider text-amber-600/80 dark:text-amber-300/80">Pending</div>
			</div>
		</div>

		<div className="mt-5 flex flex-wrap items-end justify-between gap-4">
			<div>
				<p className="text-sm font-semibold text-gray-900 dark:text-white">{props.visible} visible right now</p>
				<p className="text-xs text-gray-500 dark:text-gray-400">Choose a view here or use the native LiveView controls above.</p>
			</div>

			<div className="grid min-w-[18rem] grid-cols-3 gap-2" aria-label="React todo filters">
				<button type="button" data-testid="insights-filter-all" aria-pressed={props.filter == All}
					className={buttonClass(All)} onClick={() -> props.onFilter(All)}>
					<strong className="block text-sm">All</strong>
				</button>
				<button type="button" data-testid="insights-filter-active" aria-pressed={props.filter == Active}
					className={buttonClass(Active)} onClick={() -> props.onFilter(Active)}>
					<strong className="block text-sm">Active</strong>
				</button>
				<button type="button" data-testid="insights-filter-completed" aria-pressed={props.filter == Completed}
					className={buttonClass(Completed)} onClick={() -> props.onFilter(Completed)}>
					<strong className="block text-sm">Done</strong>
				</button>
			</div>
		</div>
	</div>;
}

/**
 * Trusted stock-LiveReact adapter.
 *
 * The raw transport is open because upstream injects bridge functions. This
 * function validates the exact public JSON fields, removes every native bridge
 * capability, and gives the inner component one semantic callback. It is a
 * boundary for trusted first-party code, not a sandbox for hostile components.
 */
@:expose
function TodoInsightsBoundary(raw:DynamicAccess<Dynamic>):Element {
	try {
		validateRawKeys(raw);

		var pushValue = requiredField(raw, "pushEvent");
		if (!Reflect.isFunction(pushValue))
			throw new haxe.Exception("TodoInsights.pushEvent must be a function");
		var pushEvent:LiveReactPushEvent = cast pushValue;

		var input:TodoInsightsInput = {
			title: expectString(requiredField(raw, "title"), "title"),
			total: expectInt(requiredField(raw, "total"), "total"),
			completed: expectInt(requiredField(raw, "completed"), "completed"),
			pending: expectInt(requiredField(raw, "pending"), "pending"),
			visible: expectInt(requiredField(raw, "visible"), "visible"),
			filter: expectFilter(requiredField(raw, "filter"))
		};

		return TodoInsights({
			title: input.title,
			total: input.total,
			completed: input.completed,
			pending: input.pending,
			visible: input.visible,
			filter: input.filter,
			onFilter: function(filter:TodoInsightsFilter):Void {
				pushSetFilter(pushEvent, {filter: filter});
			}
		});
	} catch (error:haxe.Exception) {
		return <section role="alert" data-testid="todo-insights-error"
			className="rounded-xl border border-red-300 bg-red-50 p-4 text-red-800 dark:border-red-800 dark:bg-red-950/40 dark:text-red-200">
			<strong className="block">React insights unavailable.</strong>
			<span className="text-sm">Native LiveView controls remain available. {error.message}</span>
		</section>;
	}
}

function requiredField(raw:DynamicAccess<Dynamic>, name:String):Dynamic {
	if (!raw.exists(name))
		throw new haxe.Exception("TodoInsights is missing " + name);
	return raw[name];
}

function expectString(value:Dynamic, name:String):String {
	if (!Std.isOfType(value, String))
		throw new haxe.Exception("TodoInsights." + name + " must be a string");
	return value;
}

function expectInt(value:Dynamic, name:String):Int {
	if (!Std.isOfType(value, Int))
		throw new haxe.Exception("TodoInsights." + name + " must be an integer");
	return value;
}

function expectFilter(value:Dynamic):TodoInsightsFilter {
	var filter = expectString(value, "filter");
	return switch (filter) {
		case "all": All;
		case "active": Active;
		case "completed": Completed;
		case _: throw new haxe.Exception("TodoInsights.filter must be all, active, or completed");
	};
}

function validateRawKeys(raw:DynamicAccess<Dynamic>):Void {
	for (name in raw.keys()) {
		var allowed = switch (name) {
			case "title" | "total" | "completed" | "pending" | "visible" | "filter": true;
			case "pushEvent" | "pushEventTo" | "handleEvent" | "removeHandleEvent" | "upload" | "uploadTo": true;
			case _: false;
		};

		if (!allowed)
			throw new haxe.Exception("Unexpected TodoInsights input: " + name);
	}
}

/**
 * Build entry point for this generated React module.
 *
 * Haxe starts a browser build from a class with `main()` and normally removes
 * declarations that no Haxe call can reach, which keeps generated files small.
 * Stock LiveReact is different: at runtime its JavaScript hook finds
 * `TodoInsightsBoundary` by name in the generated component registry. Haxe
 * cannot see that later lookup as an ordinary function call.
 *
 * Keeping this intentionally empty entry point in the same module tells Haxe
 * to compile the module; `@:expose` then preserves the two named React exports.
 * This function does not mount React or replace LiveReact's browser lifecycle.
 */
class TodoInsightsIsland {
	static function main():Void {}
}

import type {JSX} from "react"
import {pushSetFilter as __genes_import_pushSetFilter} from "./todo-insights-events.generated.js"
import {Reflect as Reflect__1} from "../Reflect.js"
import {Exception} from "../haxe/Exception.js"
import {Register} from "../genes/Register.js"
import type {TodoInsightsFilterInput} from "../shared/liveview/TodoInsightsEvents.js"

export type TodoInsightsInput = {
	completed: number,
	filter: "active" | "all" | "completed",
	pending: number,
	title: string,
	total: number,
	visible: number
}

export type TodoInsightsProps = {
	completed: number,
	filter: "active" | "all" | "completed",
	onFilter: (arg0: string) => void,
	pending: number,
	title: string,
	total: number,
	visible: number
}

/**
 * Stock LiveReact capability narrowed to the one event operation we use.
 */
export type LiveReactPushEvent = ((event: string, payload: {[key: string]: any}) => void)

export type PushTodoInsightsFilter = ((pushEvent: LiveReactPushEvent, input: TodoInsightsFilterInput) => void)

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
export class TodoInsightsIsland {
	static main(): void {
	}
	static get __name__(): string {
		return "todo_insights.TodoInsightsIsland"
	}
	get __class__(): Function {
		return TodoInsightsIsland
	}
}
Register.setHxClass("todo_insights.TodoInsightsIsland", TodoInsightsIsland);

export class TodoInsightsIsland_Fields_ {
	declare static pushSetFilter: PushTodoInsightsFilter;

	/**
	 * Inner application component: closed semantic props, with no raw LiveView bridge.
	 */
	static TodoInsights(props: TodoInsightsProps): JSX.Element {
		let buttonClass: ((candidate: string) => string) = function (candidate: string) {
			let base: string = "rounded-xl border px-4 py-3 text-left transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500";
			let inactive: string = base + " border-gray-200 bg-white text-gray-700 hover:border-indigo-300 hover:bg-indigo-50" + " dark:border-gray-700 dark:bg-gray-900 dark:text-gray-200 dark:hover:border-indigo-700 dark:hover:bg-indigo-950/40";
			if (candidate == props.filter) {
				return base + " border-indigo-500 bg-indigo-600 text-white shadow-md";
			} else {
				return inactive;
			};
		};
		let tmp = {"__genesJsxPropName": "data-testid", "__genesJsxPropValue": "todo-insights", "__genesJsxPropNext": {"__genesJsxPropName": "data-active-filter", "__genesJsxPropValue": props.filter, "__genesJsxPropNext": {"__genesJsxPropsEnd": true}}};
		let div: JSX.Element = <div className="text-2xl font-black text-blue-700 dark:text-blue-300">{props.total}</div>;
		let div_1: JSX.Element = <div className="text-xs font-bold uppercase tracking-wider text-blue-600/80 dark:text-blue-300/80">Total</div>;
		let div_2: JSX.Element = <div className="rounded-xl bg-blue-50 p-4 dark:bg-blue-950/40">{div}{div_1}</div>;
		let div_3: JSX.Element = <div className="text-2xl font-black text-emerald-700 dark:text-emerald-300">{props.completed}</div>;
		let div_4: JSX.Element = <div className="text-xs font-bold uppercase tracking-wider text-emerald-600/80 dark:text-emerald-300/80">Completed</div>;
		let div_5: JSX.Element = <div className="rounded-xl bg-emerald-50 p-4 dark:bg-emerald-950/40">{div_3}{div_4}</div>;
		let div_6: JSX.Element = <div className="text-2xl font-black text-amber-700 dark:text-amber-300">{props.pending}</div>;
		let div_7: JSX.Element = <div className="text-xs font-bold uppercase tracking-wider text-amber-600/80 dark:text-amber-300/80">Pending</div>;
		let div_8: JSX.Element = <div className="rounded-xl bg-amber-50 p-4 dark:bg-amber-950/40">{div_6}{div_7}</div>;
		let div_9: JSX.Element = <div className="grid gap-3 sm:grid-cols-3">{div_2}{div_5}{div_8}</div>;
		let p: JSX.Element = <p className="text-sm font-semibold text-gray-900 dark:text-white">{props.visible} visible right now</p>;
		let p_1: JSX.Element = <p className="text-xs text-gray-500 dark:text-gray-400">Choose a view here or use the native LiveView controls above.</p>;
		let div_10: JSX.Element = <div>{p}{p_1}</div>;
		let button: JSX.Element = <button type="button" data-testid="insights-filter-all" aria-pressed={props.filter == "all"} className={buttonClass("all")} onClick={function () {
			props.onFilter("all");
		}}><strong className="block text-sm">All</strong></button>;
		let button_1: JSX.Element = <button type="button" data-testid="insights-filter-active" aria-pressed={props.filter == "active"} className={buttonClass("active")} onClick={function () {
			props.onFilter("active");
		}}><strong className="block text-sm">Active</strong></button>;
		let button_2: JSX.Element = <button type="button" data-testid="insights-filter-completed" aria-pressed={props.filter == "completed"} className={buttonClass("completed")} onClick={function () {
			props.onFilter("completed");
		}}><strong className="block text-sm">Done</strong></button>;
		let div_11: JSX.Element = <div className="grid min-w-[18rem] grid-cols-3 gap-2" aria-label="React todo filters">{button}{button_1}{button_2}</div>;
		return <div data-testid={tmp.__genesJsxPropValue} data-active-filter={tmp.__genesJsxPropNext.__genesJsxPropValue}>{div_9}<div className="mt-5 flex flex-wrap items-end justify-between gap-4">{div_10}{div_11}</div></div>;
	}

	/**
	 * Trusted stock-LiveReact adapter.
	 *
	 * The raw transport is open because upstream injects bridge functions. This
	 * function validates the exact public JSON fields, removes every native bridge
	 * capability, and gives the inner component one semantic callback. It is a
	 * boundary for trusted first-party code, not a sandbox for hostile components.
	 */
	static TodoInsightsBoundary(raw: {[key: string]: any}): JSX.Element {
		try {
			TodoInsightsIsland_Fields_.validateRawKeys(raw);
			let pushValue: any = TodoInsightsIsland_Fields_.requiredField(raw, "pushEvent");
			if (!Reflect__1.isFunction(pushValue)) {
				throw new Exception("TodoInsights.pushEvent must be a function");
			};
			let pushEvent: LiveReactPushEvent = pushValue;
			let input_title: string = TodoInsightsIsland_Fields_.expectString(TodoInsightsIsland_Fields_.requiredField(raw, "title"), "title");
			let input_total: number = TodoInsightsIsland_Fields_.expectInt(TodoInsightsIsland_Fields_.requiredField(raw, "total"), "total");
			let input_completed: number = TodoInsightsIsland_Fields_.expectInt(TodoInsightsIsland_Fields_.requiredField(raw, "completed"), "completed");
			let input_pending: number = TodoInsightsIsland_Fields_.expectInt(TodoInsightsIsland_Fields_.requiredField(raw, "pending"), "pending");
			let input_visible: number = TodoInsightsIsland_Fields_.expectInt(TodoInsightsIsland_Fields_.requiredField(raw, "visible"), "visible");
			let input_filter: "active" | "all" | "completed" = TodoInsightsIsland_Fields_.expectFilter(TodoInsightsIsland_Fields_.requiredField(raw, "filter"));
			return TodoInsightsIsland_Fields_.TodoInsights({"title": input_title, "total": input_total, "completed": input_completed, "pending": input_pending, "visible": input_visible, "filter": input_filter, "onFilter": function (filter: string) {
				TodoInsightsIsland_Fields_.pushSetFilter(pushEvent, {"filter": filter});
			}});
		}catch (_g) {
			let error: Exception = Exception.caught(_g);
			let strong: JSX.Element = <strong className="block">React insights unavailable.</strong>;
			let tmp1: string = error.get_message();
			let span: JSX.Element = <span className="text-sm">Native LiveView controls remain available. {tmp1}</span>;
			return <section role="alert" data-testid="todo-insights-error" className="rounded-xl border border-red-300 bg-red-50 p-4 text-red-800 dark:border-red-800 dark:bg-red-950/40 dark:text-red-200">{strong}{span}</section>;
		};
	}
	static requiredField(raw: {[key: string]: any}, name: string): any {
		if (!Object.prototype.hasOwnProperty.call(raw, name)) {
			throw new Exception("TodoInsights is missing " + name);
		};
		return (raw[name] ?? null);
	}
	static expectString(value: any, name: string): string {
		if (typeof(value) != "string") {
			throw new Exception("TodoInsights." + name + " must be a string");
		};
		return Register.unsafeCast<string>(value);
	}
	static expectInt(value: any, name: string): number {
		if (!(typeof(value) == "number" && ((value | 0) === (value)))) {
			throw new Exception("TodoInsights." + name + " must be an integer");
		};
		return Register.unsafeCast<number>(value);
	}
	static expectFilter(value: any): "active" | "all" | "completed" {
		let filter: string = TodoInsightsIsland_Fields_.expectString(value, "filter");
		switch (filter) {
			case "active": {
				return "active";
				break;
			}
			case "all": {
				return "all";
				break;
			}
			case "completed": {
				return "completed";
				break;
			}
			default: {
				throw new Exception("TodoInsights.filter must be all, active, or completed");
			}
		};
	}
	static validateRawKeys(raw: {[key: string]: any}): void {
		let _g_1: number = 0;
		let _g1: string[] = Reflect__1.fields(raw);
		while (_g_1 < _g1.length) {
			let name: string = _g1[_g_1]!;
			++_g_1;
			let allowed: boolean;
			switch (name) {
				case "completed":case "filter":case "pending":case "title":case "total":case "visible": {
					allowed = true;
					break;
				}
				case "handleEvent":case "pushEvent":case "pushEventTo":case "removeHandleEvent":case "upload":case "uploadTo": {
					allowed = true;
					break;
				}
				default: {
					allowed = false;
				}
			};
			if (!allowed) {
				throw new Exception("Unexpected TodoInsights input: " + name);
			};
		};
	}
	static get __name__(): string {
		return "todo_insights._TodoInsightsIsland.TodoInsightsIsland_Fields_"
	}
	get __class__(): Function {
		return TodoInsightsIsland_Fields_
	}
}
Register.setHxClass("todo_insights._TodoInsightsIsland.TodoInsightsIsland_Fields_", TodoInsightsIsland_Fields_);


TodoInsightsIsland_Fields_.pushSetFilter = __genes_import_pushSetFilter
export const TodoInsights = TodoInsightsIsland_Fields_.TodoInsights
export const TodoInsightsBoundary = TodoInsightsIsland_Fields_.TodoInsightsBoundary
export const requiredField = TodoInsightsIsland_Fields_.requiredField
export const expectString = TodoInsightsIsland_Fields_.expectString
export const expectInt = TodoInsightsIsland_Fields_.expectInt
export const expectFilter = TodoInsightsIsland_Fields_.expectFilter
export const validateRawKeys = TodoInsightsIsland_Fields_.validateRawKeys

//# sourceMappingURL=TodoInsightsIsland.tsx.map
package reflaxe.elixir.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr.Position;

using StringTools;

/**
 * Compile-time HXX validation contract for one Live Event Protocol event.
 */
typedef LiveViewEventContract = {
	var eventName:String;
	var origin:String;
	var requiredValueKeys:Array<String>;
	var allowedValueKeys:Array<String>;
}

/**
 * LiveViewEventRegistry
 *
 * WHAT
 * - Compile-time registry of Phoenix LiveView event names derived from `handle_event/3` bodies.
 *
 * WHY
 * - We want TSX-level safety for `phx-*` event names in HXX/HEEx templates without requiring a
 *   manually maintained global `@:phxEventNames` registry.
 * - LiveView event names are conventionally expressed as string literals (or enum-abstract constants)
 *   in `handle_event/3` and `render/1`. When they drift, you get runtime-only failures.
 *
 * HOW
 * - Macro passes (via `AnnotatedModuleEnumerator.ensureKept()`) scan `@:liveview` modules and register:
 *   - switch/case patterns like `case "increment": ...`
 *   - patterns like `case EventName.Increment: ...` (compile-time string constants)
 * - The HEEx/HXX linter merges these names into the allowed set for `-D hxx_strict_phx_events`.
 *
 * EXAMPLES
 * Haxe:
 *   @:liveview class CounterLive {
 *     @:native("handle_event")
 *     static function handle_event(event: String, params: Term, socket: Socket<A>): HandleEventResult<A> {
 *       return switch (event) {
 *         case "increment": ...
 *         case _: ...
 *       }
 *     }
 *     static function render(a:A) return HXX.hxx('<button phx-click={"increment"}>+</button>');
 *   }
 *
 * Result:
 * - Under `-D hxx_strict_phx_events`, `"increment"` is accepted even without an explicit `@:phxEventNames` enum.
 */
class LiveViewEventRegistry {
	static var moduleToEvents:Map<String, Map<String, Bool>> = new Map();
	static var moduleToContracts:Map<String, Map<String, LiveViewEventContract>> = new Map();
	static var moduleToPos:Map<String, Position> = new Map();

	public static function register(moduleName:String, event:String, pos:Position):Void {
		if (moduleName == null || moduleName.length == 0)
			return;
		if (event == null)
			return;
		var name = StringTools.trim(event);
		if (name.length == 0)
			return;

		var events = moduleToEvents.get(moduleName);
		if (events == null) {
			events = new Map();
			moduleToEvents.set(moduleName, events);
		}
		events.set(name, true);

		if (!moduleToPos.exists(moduleName)) {
			moduleToPos.set(moduleName, pos);
		}
	}

	public static function registerMany(moduleName:String, events:Array<String>, pos:Position):Void {
		if (events == null)
			return;
		for (e in events)
			register(moduleName, e, pos);
	}

	public static function registerContracts(moduleName:String, contracts:Array<LiveViewEventContract>, pos:Position):Void {
		if (moduleName == null || moduleName.length == 0)
			return;
		if (contracts == null)
			return;

		var byEvent = moduleToContracts.get(moduleName);
		if (byEvent == null) {
			byEvent = new Map();
			moduleToContracts.set(moduleName, byEvent);
		}

		for (contract in contracts) {
			if (contract == null || contract.eventName == null)
				continue;
			var eventName = contract.eventName.trim();
			if (eventName.length == 0)
				continue;
			byEvent.set(eventName, contract);
			register(moduleName, eventName, pos);
		}
	}

	public static function getAllEventNames():Map<String, Bool> {
		var out:Map<String, Bool> = new Map();
		for (moduleName in moduleToEvents.keys()) {
			var events = moduleToEvents.get(moduleName);
			if (events == null)
				continue;
			for (name in events.keys())
				out.set(name, true);
		}
		return out;
	}

	public static function getEventsForModule(moduleName:String):Map<String, Bool> {
		var events = moduleToEvents.get(moduleName);
		return events != null ? events : new Map();
	}

	public static function getContractForModule(moduleName:String, eventName:String):Null<LiveViewEventContract> {
		if (moduleName == null || moduleName.length == 0)
			return null;
		if (eventName == null || eventName.length == 0)
			return null;
		var contracts = moduleToContracts.get(moduleName);
		return contracts != null ? contracts.get(eventName) : null;
	}

	public static function getSummary():String {
		var lines:Array<String> = [];
		for (moduleName in moduleToEvents.keys()) {
			var events = moduleToEvents.get(moduleName);
			if (events == null)
				continue;
			var names = [for (k in events.keys()) k];
			names.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));
			lines.push(moduleName + ": [" + names.join(", ") + "]");
		}
		return lines.join("\n");
	}
}
#end

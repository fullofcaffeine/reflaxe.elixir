package phoenix;

#if macro
import haxe.macro.Expr;
#end
import phoenix.types.AssignKey;

/**
 * LiveSocket - type-safe wrapper for `Phoenix.LiveView.Socket`.
 *
 * WHAT
 * - Provides two assign APIs on top of `Socket<TAssigns>`:
 *   - macro shorthand (`assign(_.field, value)`) for minimal Haxe code
 *   - typed keys (`assignKey(Keys.field, value)`) for stronger IDE completion and key-specific value typing
 *
 * WHY
 * - Assign keys are central to LiveView behavior and typos are costly.
 * - Haxe 4.3.7 completion is strongest when values are regular typed expressions
 *   (not macro `Expr` arguments). Typed keys unlock that path.
 *
 * HOW
 * - Macro shorthand methods:
 *   `assign`, `assignNew`, `update`.
 * - Completion-first typed-key methods:
 *   `assignKey`, `assignNewKey`, `updateKey`.
 * - `assign({...})` handles Phoenix-style bulk assigns with field validation and
 *   snake_case atom key rewriting.
 * - `merge({...})` is kept as a backward-compatible alias.
 * - Runtime stays idiomatic Phoenix: calls compile to `assign/3`, `assign_new/3`, `update/3`.
 *
 * EXAMPLES
 * Haxe:
 *   // Shortest syntax (macro shorthand)
 *   live = live.assign(_.count, 0);
 *   live = live.update(_.count, (n) -> n + 1);
 *
 *   // Best completion path (typed key tokens)
 *   live = live.assignKey(CounterAssignKeys.count, 0);
 *   live = live.updateKey(CounterAssignKeys.count, (n) -> n + 1);
 *
 * Elixir:
 *   socket
 *   |> assign(:count, 0)
 *   |> update(:count, &(&1 + 1))
 */
@:forward
abstract LiveSocket<T>(phoenix.Phoenix.Socket<T>) from phoenix.Phoenix.Socket<T> to phoenix.Phoenix.Socket<T> {
	/**
	 * Create a LiveSocket wrapper from a normal socket.
	 */
	public inline function new(socket:phoenix.Phoenix.Socket<T>) {
		this = socket;
	}

	/**
	 * Pipe operator for Phoenix-style chaining.
	 */
	@:op(A | B)
	public static inline function pipe<T>(socket:LiveSocket<T>, func:LiveSocket<T>->LiveSocket<T>):LiveSocket<T> {
		return func(socket);
	}

	/**
	 * Assign values using Phoenix-style arities.
	 *
	 * Haxe:
	 *   // Single key/value (macro selector)
	 *   live.assign(_.searchQuery, "term");
	 *
	 *   // Multiple assigns (map form, mirrors Phoenix assign/2)
	 *   live.assign({
	 *     search_query: "term",
	 *     sort_by: "created"
	 *   });
	 *
	 * Elixir:
	 *   assign(socket, :search_query, "term")
	 *   assign(socket, %{search_query: "term", sort_by: "created"})
	 */
	public macro function assign<T>(ethis:ExprOf<LiveSocket<T>>, fieldOrUpdates:Expr, ?value:Expr):ExprOf<LiveSocket<T>> {
		return phoenix.macros.AssignMacro.processAssign(ethis, fieldOrUpdates, value);
	}

	/**
	 * Assign one field using a typed key token (completion-first path).
	 */
	extern inline public function assignKey<V>(key:AssignKey<T, V>, value:V):LiveSocket<T> {
		return untyped __elixir__('Phoenix.Component.assign({0}, {1}, {2})', this, key, value);
	}

	/**
	 * Backward-compatible alias for `assign({...})`.
	 */
	public macro function merge<T>(ethis:ExprOf<LiveSocket<T>>, updates:Expr):ExprOf<LiveSocket<T>> {
		return phoenix.macros.AssignMacro.processMerge(ethis, updates);
	}

	/**
	 * Assign a default value only when the field is not already present
	 * (macro shorthand path).
	 */
	public macro function assignNew<T, V>(ethis:ExprOf<LiveSocket<T>>, fieldExpr:Expr, defaultFn:ExprOf<Void->V>):ExprOf<LiveSocket<T>> {
		return phoenix.macros.AssignMacro.processAssignNew(ethis, fieldExpr, defaultFn);
	}

	/**
	 * Assign a default value using a typed key token (completion-first path).
	 */
	extern inline public function assignNewKey<V>(key:AssignKey<T, V>, defaultFn:Void->V):LiveSocket<T> {
		return untyped __elixir__('Phoenix.Component.assign_new({0}, {1}, {2})', this, key, defaultFn);
	}

	/**
	 * Update an existing assign field (macro shorthand path).
	 */
	public macro function update<T, V>(ethis:ExprOf<LiveSocket<T>>, fieldExpr:Expr, updater:ExprOf<V->V>):ExprOf<LiveSocket<T>> {
		return phoenix.macros.AssignMacro.processUpdate(ethis, fieldExpr, updater);
	}

	/**
	 * Update an existing assign using a typed key token (completion-first path).
	 */
	extern inline public function updateKey<V>(key:AssignKey<T, V>, updater:V->V):LiveSocket<T> {
		return untyped __elixir__('Phoenix.Component.update({0}, {1}, {2})', this, key, updater);
	}

	/**
	 * Clear all flash messages from the socket.
	 */
	extern inline public function clearFlash():LiveSocket<T> {
		return untyped __elixir__('Phoenix.LiveView.clear_flash({0})', this);
	}

	/**
	 * Put a flash message on the socket.
	 */
	extern inline public function putFlash(type:phoenix.types.Flash.FlashType, message:String):LiveSocket<T> {
		return cast phoenix.Phoenix.LiveView.putFlash(cast this, type, message);
	}

	/**
	 * Push an event to client-side hooks.
	 */
	extern inline public function pushEvent<P>(event:String, payload:P):LiveSocket<T> {
		return untyped __elixir__('Phoenix.LiveView.push_event({0}, {1}, {2})', this, event, payload);
	}
}

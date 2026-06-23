package phoenix;

#if macro
import haxe.macro.Expr;
#end
import phoenix.types.AssignKey;
import phoenix.types.LiveStreamName;

/**
 * Socket assign extension macros for Phoenix LiveView callbacks.
 *
 * WHAT
 * - Adds assign helpers directly on `phoenix.Phoenix.Socket<TAssigns>`:
 *   - `assign(_.field, value)` / `assign({...})`
 *   - `assignKey(keys.field, value)` (optional typed-key mode)
 *   - `assignNew`, `assignNewKey`, `update`, `updateKey`, `merge`
 *   - `stream`, `streamInsert`, `streamDelete` with typed stream-name tokens
 *
 * WHY
 * - Phoenix callbacks naturally use `socket: Socket<TAssigns>`.
 * - This keeps callback code minimal without requiring a local conversion variable.
 *
 * HOW
 * - Each extension macro delegates to `phoenix.macros.AssignMacro`.
 * - Stream helpers delegate to `phoenix.macros.LiveStreamMacro`.
 * - Runtime output remains the same Phoenix calls (`assign/2`, `assign/3`, `assign_new/3`, `update/3`).
 *
 * EXAMPLES
 * Haxe:
 *   socket = socket.assign(_.count, 0);
 *   socket = socket.assign({search_query: "term"});
 *
 *   var keys = AssignKeys.of(CounterAssigns);
 *   socket = socket.assignKey(keys.count, 1);
 *
 *   var streams = LiveStreams.of(TodoAssigns);
 *   socket = socket.stream(streams.todos, todos);
 *
 * Elixir:
 *   assign(socket, :count, 0)
 *   assign(socket, %{search_query: "term"})
 *   assign(socket, :count, 1)
 *   Phoenix.LiveView.stream(socket, :todos, todos)
 */
class SocketAssignExtensions {
	/**
	 * Assign values using Phoenix-style arities.
	 */
	public static macro function assign<T>(ethis:ExprOf<phoenix.Phoenix.Socket<T>>, fieldOrUpdates:Expr, ?value:Expr):ExprOf<phoenix.Phoenix.Socket<T>> {
		return cast phoenix.macros.AssignMacro.processAssign(ethis, fieldOrUpdates, value);
	}

	/**
	 * Assign one field using a typed key token.
	 */
	public static macro function assignKey<T, V>(ethis:ExprOf<phoenix.Phoenix.Socket<T>>, keyExpr:ExprOf<AssignKey<T, V>>,
			value:ExprOf<V>):ExprOf<phoenix.Phoenix.Socket<T>> {
		return cast phoenix.macros.AssignMacro.processAssignKey(ethis, keyExpr, value);
	}

	/**
	 * Backward-compatible alias for `assign({...})`.
	 */
	public static macro function merge<T>(ethis:ExprOf<phoenix.Phoenix.Socket<T>>, updates:Expr):ExprOf<phoenix.Phoenix.Socket<T>> {
		return cast phoenix.macros.AssignMacro.processMerge(ethis, updates);
	}

	/**
	 * Assign a default value only when the field is not already present
	 * (macro shorthand path).
	 */
	public static macro function assignNew<T, V>(ethis:ExprOf<phoenix.Phoenix.Socket<T>>, fieldExpr:Expr,
			defaultFn:ExprOf<Void->V>):ExprOf<phoenix.Phoenix.Socket<T>> {
		return cast phoenix.macros.AssignMacro.processAssignNew(ethis, fieldExpr, defaultFn);
	}

	/**
	 * Assign a default value using a typed key token.
	 */
	public static macro function assignNewKey<T, V>(ethis:ExprOf<phoenix.Phoenix.Socket<T>>, keyExpr:ExprOf<AssignKey<T, V>>,
			defaultFn:ExprOf<Void->V>):ExprOf<phoenix.Phoenix.Socket<T>> {
		return cast phoenix.macros.AssignMacro.processAssignNewKey(ethis, keyExpr, defaultFn);
	}

	/**
	 * Update an existing assign field (macro shorthand path).
	 */
	public static macro function update<T, V>(ethis:ExprOf<phoenix.Phoenix.Socket<T>>, fieldExpr:Expr, updater:ExprOf<V->V>):ExprOf<phoenix.Phoenix.Socket<T>> {
		return cast phoenix.macros.AssignMacro.processUpdate(ethis, fieldExpr, updater);
	}

	/**
	 * Update an existing assign using a typed key token.
	 */
	public static macro function updateKey<T, V>(ethis:ExprOf<phoenix.Phoenix.Socket<T>>, keyExpr:ExprOf<AssignKey<T, V>>,
			updater:ExprOf<V->V>):ExprOf<phoenix.Phoenix.Socket<T>> {
		return cast phoenix.macros.AssignMacro.processUpdateKey(ethis, keyExpr, updater);
	}

	/**
	 * Initialize or reset a typed LiveView stream.
	 */
	public static macro function stream<T, V>(ethis:ExprOf<phoenix.Phoenix.Socket<T>>, streamName:ExprOf<LiveStreamName<T, V>>, items:ExprOf<Array<V>>,
			?opts:Expr):ExprOf<phoenix.Phoenix.Socket<T>> {
		return cast phoenix.macros.LiveStreamMacro.processStream(ethis, streamName, items, opts);
	}

	/**
	 * Insert or update one item in a typed LiveView stream.
	 */
	public static macro function streamInsert<T, V>(ethis:ExprOf<phoenix.Phoenix.Socket<T>>, streamName:ExprOf<LiveStreamName<T, V>>, item:ExprOf<V>,
			?opts:Expr):ExprOf<phoenix.Phoenix.Socket<T>> {
		return cast phoenix.macros.LiveStreamMacro.processStreamInsert(ethis, streamName, item, opts);
	}

	/**
	 * Delete one item from a typed LiveView stream.
	 */
	public static macro function streamDelete<T, V>(ethis:ExprOf<phoenix.Phoenix.Socket<T>>, streamName:ExprOf<LiveStreamName<T, V>>, item:ExprOf<V>,
			?opts:Expr):ExprOf<phoenix.Phoenix.Socket<T>> {
		return cast phoenix.macros.LiveStreamMacro.processStreamDelete(ethis, streamName, item, opts);
	}
}

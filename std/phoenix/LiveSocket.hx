package phoenix;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;
#end

/**
 * LiveSocket - Type-safe wrapper around Phoenix.LiveView.Socket with idiomatic assign operations
 * 
 * LiveSocket provides multiple ways to update assigns while maintaining compile-time type safety.
 * All field names are validated at compile time and automatically converted to snake_case for Phoenix.
 * 
 * ## Purpose & Design Philosophy
 * 
 * LiveSocket is an abstract type that wraps Socket<T> to provide a type-safe, ergonomic API
 * for LiveView development. It solves the #1 source of LiveView bugs: typos in assign keys.
 * 
 * ## Relationship with Socket<T>
 * 
 * - **Socket<T>** is the base Phoenix type - what framework functions expect
 * - **LiveSocket<T>** is an abstract wrapper adding type-safe methods
 * - **Seamless conversion**: No casting needed, implicit in both directions
 * 
 * ```haxe
 * // Phoenix functions expect Socket
 * function mount(params, session, socket: Socket<MyAssigns>) {
 *     // Implicit conversion to LiveSocket for type-safe operations
 *     var liveSocket: LiveSocket<MyAssigns> = socket;
 *     
 *     // Chain operations with full type safety
 *     return liveSocket
 *         .assign(_.userId, 123)        // Validated at compile time!
 *         .merge({name: "Alice", age: 30})
 *         .putFlash(Info, "Welcome!");
 *     // Returns Socket<MyAssigns> implicitly
 * }
 * ```
 * 
 * ## Key Features
 * 
 * - **Compile-time validation**: Field names checked against assigns type - typos caught early!
 * - **Automatic snake_case conversion**: `editingTodo` → `:editing_todo` for Phoenix
 * - **Multiple usage styles**: Phoenix pipes, method chaining, or function calls
 * - **Zero runtime overhead**: All transformations happen at compile time via macros
 * - **IntelliSense support**: Full IDE autocomplete for field names and values
 * 
 * ## Usage Examples
 * 
 * ### Phoenix-style pipe operator (most idiomatic for Elixir developers)
 * ```haxe
 * socket 
 *   |> assign(_.editingTodo, todo)
 *   |> assign(_.showForm, true)
 *   |> assign(_.selectedTags, ["urgent", "work"]);
 * ```
 * Compiles to:
 * ```elixir
 * socket 
 *   |> assign(:editing_todo, todo)
 *   |> assign(:show_form, true)
 *   |> assign(:selected_tags, ["urgent", "work"])
 * ```
 * 
 * ### Method chaining (familiar to Haxe/OOP developers)
 * ```haxe
 * socket
 *   .assign(_.editingTodo, todo)
 *   .assign(_.showForm, true)
 *   .assign(_.selectedTags, ["urgent", "work"]);
 * ```
 * 
 * ### Batch updates (efficient for multiple fields)
 * ```haxe
 * socket.merge({
 *     editingTodo: todo,
 *     showForm: true,
 *     selectedTags: ["urgent", "work"],
 *     totalTodos: todos.length
 * });
 * ```
 * Compiles to:
 * ```elixir
 * socket |> assign(%{
 *   editing_todo: todo,
 *   show_form: true,
 *   selected_tags: ["urgent", "work"],
 *   total_todos: length(todos)
 * })
 * ```
 * 
 * ### Conditional assigns (only set if not present)
 * ```haxe
 * socket
 *   .assignNew(_.currentUser, () -> loadUser())
 *   .assignNew(_.theme, () -> "dark");
 * ```
 * 
 * ### Update with function (transform existing value)
 * ```haxe
 * socket
 *   .update(_.counter, x -> x + 1)
 *   .update(_.todos, list -> list.concat([newTodo]));
 * ```
 * 
 * ## Type Safety Benefits
 * 
 * All field accesses are validated at compile time:
 * ```haxe
 * socket.assign(_.nonExistentField, value);  // Compile error!
 * socket.assign(_.editingTodo, wrongType);   // Type error!
 * ```
 * 
 * ## Field Name Conversion
 * 
 * The macro automatically converts Haxe naming conventions to Phoenix conventions:
 * - `editingTodo` → `:editing_todo`
 * - `showForm` → `:show_form`
 * - `currentUser` → `:current_user`
 * - `totalTodos` → `:total_todos`
 * 
 * @param T The type of the socket assigns structure
 */
@:forward
abstract LiveSocket<T>(phoenix.Phoenix.Socket<T>) from phoenix.Phoenix.Socket<T> to phoenix.Phoenix.Socket<T> {
	
	/**
	 * Create a new LiveSocket from a regular Socket.
	 * This is typically called automatically through implicit conversion.
	 */
	public inline function new(socket: phoenix.Phoenix.Socket<T>) {
		this = socket;
	}
	
	/**
	 * Pipe operator for Phoenix-style chaining.
	 * 
	 * Allows idiomatic Phoenix-style code:
	 * ```haxe
	 * socket |> assign(_.editingTodo, todo)
	 * ```
	 * 
	 * The `|>` operator is right-associative, allowing natural chaining:
	 * ```haxe
	 * socket 
	 *   |> assign(_.field1, value1)
	 *   |> assign(_.field2, value2)
	 *   |> assign(_.field3, value3)
	 * ```
	 * 
	 * @param socket The LiveSocket to update
	 * @param assignExpr The assign expression (must be a call to assign, merge, etc.)
	 * @return Updated LiveSocket with new assigns
	 */
	@:op(A | B)
	public static inline function pipe<T>(socket: LiveSocket<T>, func: LiveSocket<T> -> LiveSocket<T>): LiveSocket<T> {
		// Simple pipe operator implementation - just apply the function
		return func(socket);
	}
	
	/**
	 * Assign a single value to the socket with compile-time field validation.
	 * 
	 * The field is specified using underscore syntax for type safety:
	 * ```haxe
	 * socket.assign(_.editingTodo, todo)
	 * ```
	 * 
	 * The macro will:
	 * 1. Validate that `editingTodo` exists in the assigns type T
	 * 2. Check that the value type matches the field type
	 * 3. Convert `editingTodo` to `editing_todo` for Phoenix
	 * 4. Generate: `Phoenix.LiveView.assign(socket, :editing_todo, todo)`
	 * 
	 * **Note on Syntax**: The underscore pattern (`_.field`) provides compile-time safety
	 * but may feel unusual. We're exploring more intuitive alternatives for future versions.
	 * See [Future Assign Syntax Ideas](../../docs/07-patterns/future-assign-syntax-ideas.md)
	 * for proposals like field descriptors and typed builders.
	 * 
	 * @param fieldExpr Field access expression (_.fieldName)
	 * @param value The value to assign
	 * @return Updated LiveSocket
	 */
	public macro function assign<T>(ethis: ExprOf<LiveSocket<T>>, fieldExpr: Expr, value: Expr): ExprOf<LiveSocket<T>> {
		return phoenix.macros.AssignMacro.processAssign(ethis, fieldExpr, value);
	}
	
	/**
	 * Batch assign multiple values at once.
	 * 
	 * More efficient than multiple individual assigns:
	 * ```haxe
	 * socket.merge({
	 *     editingTodo: null,
	 *     showForm: false,
	 *     selectedTags: []
	 * })
	 * ```
	 * 
	 * All field names are validated and converted to snake_case:
	 * ```elixir
	 * assign(socket, %{
	 *   editing_todo: nil,
	 *   show_form: false,
	 *   selected_tags: []
	 * })
	 * ```
	 * 
	 * @param updates Object with fields to update (can be partial)
	 * @return Updated LiveSocket
	 */
	public macro function merge<T>(ethis: ExprOf<LiveSocket<T>>, updates: Expr): ExprOf<LiveSocket<T>> {
		return phoenix.macros.AssignMacro.processMerge(ethis, updates);
	}
	
	/**
	 * Conditionally assign a value only if the field is not already set.
	 * 
	 * Useful for setting defaults:
	 * ```haxe
	 * socket
	 *   .assignNew(_.theme, () -> getUserTheme())
	 *   .assignNew(_.locale, () -> "en_US")
	 * ```
	 * 
	 * The function is only called if the field is not present:
	 * ```elixir
	 * socket
	 *   |> assign_new(:theme, fn -> get_user_theme() end)
	 *   |> assign_new(:locale, fn -> "en_US" end)
	 * ```
	 * 
	 * @param fieldExpr Field access expression (_.fieldName)
	 * @param defaultFn Function that returns the default value
	 * @return Updated LiveSocket
	 */
	public macro function assignNew<T, V>(ethis: ExprOf<LiveSocket<T>>, fieldExpr: Expr, defaultFn: ExprOf<Void -> V>): ExprOf<LiveSocket<T>> {
		return phoenix.macros.AssignMacro.processAssignNew(ethis, fieldExpr, defaultFn);
	}
	
	/**
	 * Update an existing assign value using a transformation function.
	 * 
	 * Transform the current value:
	 * ```haxe
	 * socket
	 *   .update(_.counter, x -> x + 1)
	 *   .update(_.todos, list -> list.filter(t -> !t.completed))
	 * ```
	 * 
	 * Generates efficient update code:
	 * ```elixir
	 * socket
	 *   |> update(:counter, &(&1 + 1))
	 *   |> update(:todos, &Enum.filter(&1, fn t -> !t.completed end))
	 * ```
	 * 
	 * @param fieldExpr Field access expression (_.fieldName)
	 * @param updater Function that transforms the current value
	 * @return Updated LiveSocket
	 */
	public macro function update<T, V>(ethis: ExprOf<LiveSocket<T>>, fieldExpr: Expr, updater: ExprOf<V -> V>): ExprOf<LiveSocket<T>> {
		return phoenix.macros.AssignMacro.processUpdate(ethis, fieldExpr, updater);
	}
	
	/**
	 * Clear all flash messages from the socket.
	 * 
	 * ```haxe
	 * socket.clearFlash()
	 * ```
	 * 
	 * ## CRITICAL LESSON: Why `extern inline` is Required for Abstract Types with `__elixir__`
	 *
	 * Abstract type methods are typed when the abstract is imported (early in compilation),
	 * before Reflaxe can inject __elixir__. The solution is extern inline which delays the typing
	 * of the method body until it's actually used at call sites, after Reflaxe initialization.
	 *
	 * ### The Problem We Encountered
	 * When using `untyped __elixir__()` in abstract type methods, compilation fails with:
	 * "Unknown identifier: __elixir__"
	 * 
	 * ### Why This Happens
	 * 1. **Typing Phase Timing**: Abstract methods are typed when the abstract is imported
	 * 2. **Reflaxe Initialization**: `__elixir__` is injected AFTER Haxe's typing phase
	 * 3. **The Gap**: During typing, `__elixir__` doesn't exist yet
	 * 
	 * ### The Solution: `extern inline`
	 * - **`extern`**: Tells Haxe this is an external implementation
	 * - **`inline`**: Forces the function body to be inlined at call sites
	 * - **Result**: The `__elixir__` code is only typed when actually used, AFTER Reflaxe init
	 * 
	 * ### Why Regular Classes Work Without This
	 * - Regular class methods aren't forced to be typed immediately
	 * - Array.hx has `@:coreApi` which gives special compilation treatment
	 * - Abstract methods are essentially always inline, causing early typing
	 * 
	 * ### The Rule
	 * **ALWAYS use `extern inline` for abstract type methods that use `untyped __elixir__()`**
	 * 
	 * This critical lesson discovered after extensive debugging - see CLAUDE.md for full details.
	 * 
	 * @return Updated LiveSocket
	 */
	extern inline public function clearFlash(): LiveSocket<T> {
		return untyped __elixir__('Phoenix.LiveView.clear_flash({0})', this);
	}
	
	/**
	 * Put a flash message on the socket.
	 * 
	 * ```haxe
	 * socket.putFlash(Info, "Todo created successfully!")
	 * ```
	 * 
	 * @param type The flash type (Info, Error, Warning, Success)
	 * @param message The message to display
	 * @return Updated LiveSocket
	 */
	extern inline public function putFlash(type: phoenix.Phoenix.FlashType, message: String): LiveSocket<T> {
		return untyped __elixir__('Phoenix.LiveView.put_flash({0}, {1}, {2})', this, type, message);
	}
	
	/**
	 * Push an event to client-side hooks.
	 * 
	 * ```haxe
	 * socket.pushEvent("highlight", {id: todo.id})
	 * ```
	 * 
	 * @param event Event name
	 * @param payload Event payload
	 * @return Updated LiveSocket
	 */
	extern inline public function pushEvent<P>(event: String, payload: P): LiveSocket<T> {
		return untyped __elixir__('Phoenix.LiveView.push_event({0}, {1}, {2})', this, event, payload);
	}
}

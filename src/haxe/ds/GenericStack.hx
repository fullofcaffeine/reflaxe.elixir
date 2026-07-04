package haxe.ds;

import elixir.types.Term;

/**
 * GenericCell (Elixir target)
 *
 * WHAT
 * - Public linked-cell shape used by `haxe.ds.GenericStack.head`.
 *
 * WHY
 * - Upstream `GenericStack` exposes `head`, and upstream unitstd checks that
 *   empty stacks have a null head. The Elixir target therefore keeps the same
 *   value shape instead of hiding state in a target-only container.
 */
class GenericCell<T> {
	public var elt:T;
	public var next:GenericCell<T>;

	public function new(elt:T, next:GenericCell<T>) {
		this.elt = elt;
		this.next = next;
	}
}

/**
 * GenericStack (Elixir target)
 *
 * WHAT
 * - BEAM-safe implementation of the canonical Haxe `haxe.ds.GenericStack`
 *   API: `add`, `first`, `pop`, `isEmpty`, `remove`, `iterator`, and
 *   `toString`.
 *
 * WHY
 * - The upstream implementation relies on inline receiver mutation. When that
 *   code inlines into an expression, immutable Elixir values cannot observe
 *   the updated stack unless the caller rebinds the receiver in the same scope.
 *
 * HOW
 * - `add`, `pop`, and `remove` are registered in
 *   `ReceiverReturnConventions`, so generated callers receive updated stack
 *   state and rebind the local receiver.
 * - `remove` rebuilds the prefix before the removed cell rather than mutating
 *   nested `next` links in place.
 * - `iterator` and `toString` derive from a top-to-bottom list snapshot.
 *
 * EXAMPLES
 * ```haxe
 * var stack = new GenericStack<String>();
 * stack.add("first");
 * stack.add("second");
 * stack.pop(); // "second", with stack rebound to contain "first"
 * ```
 */
class GenericStack<T> {
	public var head:GenericCell<T>;

	public function new() {
		head = null;
	}

	public function add(item:T):Void {
		head = new GenericCell<T>(item, head);
	}

	public function first():Null<T> {
		return head == null ? null : head.elt;
	}

	public function pop():Null<T> {
		var result:Term = untyped __elixir__('
			(fn stack ->
			  case stack.head do
			    nil ->
			      {stack, nil}

			    cell ->
			      {%{stack | head: cell.next}, cell.elt}
			  end
			end).({0})
		', this);

		head = untyped __elixir__("elem({0}, 0).head", result);
		return untyped __elixir__("elem({0}, 1)", result);
	}

	public function isEmpty():Bool {
		return head == null;
	}

	public function remove(v:T):Bool {
		var result:Term = untyped __elixir__('
			(fn stack_head, value ->
			  {found, reversed_prefix, suffix} =
			    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {false, [], stack_head}, fn _, {_, prefix, cell} ->
			      cond do
			        is_nil(cell) ->
			          {:halt, {false, prefix, nil}}

			        cell.elt == value ->
			          {:halt, {true, prefix, cell.next}}

			        true ->
			          {:cont, {false, [cell.elt | prefix], cell.next}}
			      end
			    end)

			  new_head =
			    if found do
			      Enum.reduce(reversed_prefix, suffix, fn elt, next ->
			        GenericCell.new(elt, next)
			      end)
			    else
			      stack_head
			    end

			  {new_head, found}
			end).({0}, {1})
		', head, v);

		head = untyped __elixir__("elem({0}, 0)", result);
		return untyped __elixir__("elem({0}, 1)", result);
	}

	public function iterator():Iterator<T> {
		return cast untyped __elixir__('
			(fn values ->
			  key = {:reflaxe_generic_stack_iterator, make_ref()}
			  Process.put(key, values)

			  %{
			    has_next: fn ->
			      Process.get(key) != []
			    end,
			    next: fn ->
			      case Process.get(key) do
			        [value | rest] ->
			          Process.put(key, rest)
			          value

			        [] ->
			          nil
			      end
			    end
			  }
			end).({0})
		', toArray());
	}

	public function toString():String {
		return "{" + toArray().join(",") + "}";
	}

	function toArray():Array<T> {
		return cast untyped __elixir__('
			(fn stack_head ->
			  {reversed, _} =
			    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {[], stack_head}, fn _, {acc, cell} ->
			      if is_nil(cell) do
			        {:halt, {acc, nil}}
			      else
			        {:cont, {[cell.elt | acc], cell.next}}
			      end
			    end)

			  Enum.reverse(reversed)
			end).({0})
		', head);
	}
}

package haxe.ds;

#if elixir_output
import elixir.types.Term;
#end

#if elixir_output
private class VectorData<T> {
	public var length(default, null):Int;

	final ref:Term;
	final dictKey:Term;

	public function new(length:Int, items:Array<T>) {
		this.length = length;
		this.ref = untyped __elixir__(":erlang.unique_integer([:positive])");
		this.dictKey = untyped __elixir__('{:reflaxe_vector, {0}}', ref);
		putItems(items);
	}

	public function items():Array<T> {
		var stored:Null<Array<T>> = untyped __elixir__('Process.get({0})', dictKey);
		if (stored == null) {
			stored = [];
			putItems(stored);
		}
		return stored;
	}

	public function putItems(items:Array<T>):Void {
		untyped __elixir__('Process.put({0}, {1})', dictKey, items);
	}

	public function get(index:Int):T {
		return untyped __elixir__('Enum.at({0}, {1})', items(), index);
	}

	public function set(index:Int, value:T):T {
		putItems(untyped __elixir__('List.replace_at({0}, {1}, {2})', items(), index, value));
		return value;
	}
}
#else
private typedef VectorData<T> = Array<T>;
#end

/**
 * Fixed-length vector storage for the Elixir target.
 *
 * WHAT
 * - Implements the canonical `haxe.ds.Vector` API shape with indexed access,
 *   copy/blit helpers, iteration, mapping, joining, and sorting.
 *
 * WHY
 * - The upstream Vector abstract relies on mutable target arrays. On BEAM,
 *   ordinary arrays lower to immutable lists, so shared Vector state needs a
 *   stable backing cell instead of caller-local list rebinding.
 *
 * HOW
 * - Macro/tooling contexts use a small pure-Haxe array-backed model.
 * - Elixir output stores the current items in process-local state keyed by a
 *   per-vector reference. Mutating APIs update that state, preserving aliases
 *   produced by `toData()`/`fromData()` and ordinary variable copies.
 */
abstract Vector<T>(VectorData<T>) {
	public var length(get, never):Int;

	public function new(length:Int, ?defaultValue:T) {
		var items:Array<T> = [];
		for (_ in 0...length) {
			items.push(defaultValue);
		}
		#if elixir_output
		this = new VectorData<T>(length, items);
		#else
		this = items;
		#end
	}

	inline function get_length():Int {
		#if elixir_output
		return this.length;
		#else
		return this.length;
		#end
	}

	@:op([])
	public inline function get(index:Int):T {
		#if elixir_output
		return this.get(index);
		#else
		return this[index];
		#end
	}

	@:op([])
	public inline function set(index:Int, value:T):T {
		#if elixir_output
		return this.set(index, value);
		#else
		return this[index] = value;
		#end
	}

	public function fill(value:T):Void {
		#if elixir_output
		this.putItems(untyped __elixir__('List.duplicate({0}, {1})', value, this.length));
		#else
		for (i in 0...this.length) {
			this[i] = value;
		}
		#end
	}

	public static function blit<T>(src:Vector<T>, srcPos:Int, dest:Vector<T>, destPos:Int, len:Int):Void {
		#if elixir_output
		var srcData:VectorData<T> = src.toData();
		var destData:VectorData<T> = dest.toData();
		var srcItems = srcData.items();
		var destItems = destData.items();
		destData.putItems(untyped __elixir__('
			Enum.reduce(0..({4} - 1)//1, {1}, fn offset, acc ->
			  List.replace_at(acc, {3} + offset, Enum.at({0}, {2} + offset))
			end)
		', srcItems, destItems, srcPos, destPos, len));
		#else
		if (src == dest && srcPos < destPos) {
			var i = srcPos + len;
			var j = destPos + len;
			for (_ in 0...len) {
				i--;
				j--;
				src[j] = src[i];
			}
		} else {
			for (i in 0...len) {
				dest[destPos + i] = src[srcPos + i];
			}
		}
		#end
	}

	public function toArray():Array<T> {
		#if elixir_output
		return this.items().copy();
		#else
		return this.copy();
		#end
	}

	public inline function toData():VectorData<T> {
		return this;
	}

	public static inline function fromData<T>(data:VectorData<T>):Vector<T> {
		return cast data;
	}

	public static function fromArrayCopy<T>(array:Array<T>):Vector<T> {
		#if elixir_output
		return cast new VectorData<T>(array.length, array.copy());
		#else
		return cast array.copy();
		#end
	}

	public function copy():Vector<T> {
		#if elixir_output
		return cast new VectorData<T>(this.length, this.items().copy());
		#else
		return cast this.copy();
		#end
	}

	public function join(sep:String):String {
		#if elixir_output
		return untyped __elixir__('Enum.map({0}, fn item -> Std.string(item) end) |> Enum.join({1})', this.items(), sep);
		#else
		var b = new StringBuf();
		for (i in 0...this.length) {
			b.add(Std.string(this[i]));
			if (i < this.length - 1) {
				b.add(sep);
			}
		}
		return b.toString();
		#end
	}

	public function map<S>(f:T->S):Vector<S> {
		#if elixir_output
		var mapped:Array<S> = untyped __elixir__('Enum.map({0}, {1})', this.items(), f);
		return cast new VectorData<S>(this.length, mapped);
		#else
		var result = new Vector<S>(this.length);
		for (i in 0...this.length) {
			result[i] = f(this[i]);
		}
		return result;
		#end
	}

	public inline function sort(f:T->T->Int):Void {
		#if elixir_output
		var comparator = function(left:T, right:T):Bool {
			return f(left, right) < 0;
		};
		this.putItems(untyped __elixir__('Enum.sort({0}, {1})', this.items(), comparator));
		#else
		this.sort(f);
		#end
	}

	public function iterator():haxe.iterators.ArrayIterator<T> {
		#if elixir_output
		var snapshot = this.items();
		return cast Type.createInstance(haxe.iterators.ArrayIterator, [snapshot]);
		#else
		return cast Type.createInstance(haxe.iterators.ArrayIterator, [this]);
		#end
	}
}

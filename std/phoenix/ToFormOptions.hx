package phoenix;

#if (elixir || reflaxe_runtime)
import elixir.types.Atom;
import elixir.types.Term;

/**
 * Keyword options for Phoenix.Component.to_form/2.
 *
 * Phoenix expects a keyword list, not a map. Use `ToFormOptions.build(...)`
 * instead of passing a Haxe object literal when calling `Component.toForm`.
 */
abstract ToFormOptions(Term) from Term to Term {
	public static inline function build(?as:Atom, ?id:String, ?errors:Term, ?action:Atom, ?method:String, ?multipart:Bool):ToFormOptions {
		return untyped __elixir__('
          [
            as: if(Kernel.is_nil({0}), do: nil, else: String.to_atom({0})),
            id: {1},
            errors: {2},
            action: if(Kernel.is_nil({3}), do: nil, else: String.to_atom({3})),
            method: {4},
            multipart: {5}
          ]
          |> Enum.filter(fn {_, value} -> value != nil end)
        ', as, id, errors, action, method, multipart);
	}
}
#end

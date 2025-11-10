package ecto;

#if (elixir || reflaxe_runtime)

class ChangesetTools {
    public static inline function castWithStringFields(data: Dynamic, params: Dynamic, fields: Array<String>): Dynamic {
        return untyped __elixir__('Ecto.Changeset.cast({0}, {1}, Enum.map({2}, &String.to_atom/1))', data, params, fields);
    }
}

#end


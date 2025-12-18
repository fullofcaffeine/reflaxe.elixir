package ecto;

#if (elixir || reflaxe_runtime)

import elixir.types.Term;

/**
 * Params normalization helpers for Ecto.
 *
 * WHAT
 * - Convert Haxe record/map params with camelCase or string keys into an Elixir
 *   map with snake_case atom keys and values coerced to the target schema types
 *   (including NaiveDateTime for date strings).
 *
 * WHY
 * - When using Ecto.Changeset.change/2 directly (as done by generated schemas),
 *   we still want robust type normalization identical to our typed Changeset.new
 *   wrapper, but without requiring app code to embed __elixir__ fragments.
 *
 * HOW
 * - Delegates to a small Elixir fragment that:
 *   1) Turns keys into snake_case atoms
 *   2) Looks up each field type from the provided schema struct
 *   3) Coerces strings to integers/booleans/NaiveDateTime as appropriate
 */
class Params {
    public static inline function normalizeFor<T>(data: T, params: Term): Term {
        return untyped __elixir__(
            '
            (fn data, params ->
               snake_params = for {k, v} <- Map.to_list(params), into: %{} do
                 key = if is_atom(k), do: k, else: String.to_atom(Macro.underscore(to_string(k)))
                 {key, v}
               end
               normalized_params = for {k, v} <- Map.to_list(snake_params), into: %{} do
                 type = data.__struct__.__schema__(:type, k)
                 v2 = case {type, v} do
                   {{:array, :string}, bin} when is_binary(bin) ->
                     bin |> String.split(",", trim: true) |> Enum.map(&String.trim/1)
                   {:integer, bin} when is_binary(bin) ->
                     case Integer.parse(bin) do {int, _} -> int; :error -> bin end
                   {:boolean, bin} when is_binary(bin) ->
                     case String.downcase(String.trim(bin)) do
                       "true" -> true; "false" -> false; _ -> bin
                     end
                   {:naive_datetime, bin} when is_binary(bin) ->
                     case NaiveDateTime.from_iso8601(bin) do
                       {:ok, ndt} -> ndt
                       {:error, _} ->
                         case NaiveDateTime.from_iso8601(bin <> " 00:00:00") do
                           {:ok, ndt2} -> ndt2
                           {:error, _} ->
                             case Date.from_iso8601(bin) do
                               {:ok, d} -> case NaiveDateTime.new(d, ~T[00:00:00]) do {:ok, ndt3} -> ndt3; _ -> bin end
                               _ -> bin
                             end
                         end
                     end
                   {_, bin} when is_binary(bin) and bin == "" -> nil
                   _ -> v
                 end
                 {k, v2}
               end
               normalized_params
            end).({0}, {1})
            ', data, params);
    }
}

#end

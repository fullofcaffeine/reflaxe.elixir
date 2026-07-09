defmodule Serializer do
  import Kernel, except: [to_string: 1], warn: false
  defp __haxe_static_get__(key, init) do
    static_key = {:__haxe_static__, Serializer, key}
    (case Process.get(static_key) do
      {:set, value} -> value
      nil ->
        value = init
        _ = Process.put(static_key, {:set, value})
        value
    end)
  end
  defp __haxe_static_put__(key, value) do
    static_key = {:__haxe_static__, Serializer, key}
    _ = Process.put(static_key, {:set, value})
    value
  end
  def use_cache() do
    __haxe_static_get__(:use_cache, false)
  end
  def use_cache(value) do
    __haxe_static_put__(:use_cache, value)
  end
  def use_enum_index() do
    __haxe_static_get__(:use_enum_index, false)
  end
  def use_enum_index(value) do
    __haxe_static_put__(:use_enum_index, value)
  end
  def new() do
    struct = %{:__reflaxe_class__ => Serializer, :use_cache => nil, :use_enum_index => nil, :serializer_id => nil}
    struct = %{struct | serializer_id: System.unique_integer([:positive])}
    Process.put({:haxe_serializer_parts, struct.serializer_id}, [])
    struct = %{struct | use_cache: Serializer.use_cache()}
    struct = %{struct | use_enum_index: Serializer.use_enum_index()}
    struct
  end
  def to_string(struct) do
    Process.get({:haxe_serializer_parts, struct.serializer_id}, []) |> Enum.join("")
  end
  def serialize(struct, value) do

    key = {:haxe_serializer_parts, struct.serializer_id}
    Process.put(key, Process.get(key, []) ++ [encode(value)])

  end
  def serialize_exception(struct, value) do

    key = {:haxe_serializer_parts, struct.serializer_id}
    Process.put(key, Process.get(key, []) ++ ["x" <> encode(value)])

  end
  def run(value) do
    encode(value)
  end
  defp encode(value) do

    encode = fn encode, value ->
      case value do
        {Reflaxe.Elixir.HaxeFloat, :nan} ->
          "k"

        {Reflaxe.Elixir.HaxeFloat, :positive_infinity} ->
          "p"

        {Reflaxe.Elixir.HaxeFloat, :negative_infinity} ->
          "m"

        value ->
          cond do
            value == nil ->
              "n"

            value == true ->
              "t"

            value == false ->
              "f"

            is_integer(value) ->
              if value == 0, do: "z", else: "i" <> Kernel.to_string(value)

            is_float(value) ->
              "d" <> Kernel.to_string(value)

            is_binary(value) ->
              encoded = URI.encode_www_form(value)
              "y" <> Kernel.to_string(byte_size(encoded)) <> ":" <> encoded

            is_list(value) ->
              "a" <> Enum.map_join(value, "", fn item -> encode.(encode, item) end) <> "h"

            is_map(value) ->
              body =
                value
                |> Map.drop([:__reflaxe_class__, :__struct__])
                |> Enum.map_join("", fn {key, item} ->
                  key_text =
                    case key do
                      atom when is_atom(atom) -> Atom.to_string(atom)
                      binary when is_binary(binary) -> binary
                      other -> Kernel.to_string(other)
                    end

                  encode.(encode, key_text) <> encode.(encode, item)
                end)

              "o" <> body <> "g"

            true ->
              raise Reflaxe.Elixir.HaxeThrow, [value: "Cannot serialize " <> Kernel.inspect(value)]
          end
      end
    end

    encode.(encode, value)

  end
end

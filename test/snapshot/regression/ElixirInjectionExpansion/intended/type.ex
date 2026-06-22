defmodule Type do
  def typeof(value) do

      case value do
        nil -> {:t_null}
        val when is_integer(val) -> {:t_int}
        val when is_float(val) -> {:t_float}
        val when is_tuple(val) and tuple_size(val) == 2 and elem(val, 0) == Reflaxe.Elixir.HaxeFloat and elem(val, 1) in [:nan, :positive_infinity, :negative_infinity] -> {:t_float}
        val when is_boolean(val) -> {:t_bool}
        val when is_function(val) -> {:t_function}
        val when is_binary(val) -> {:t_class, String}
        val when is_list(val) -> {:t_class, Array}
        %{__reflaxe_class__: mod} -> {:t_class, mod}
        %{__struct__: mod} -> {:t_class, mod}
        val when is_tuple(val) and tuple_size(val) > 0 and is_atom(elem(val, 0)) -> {:t_enum, nil}
        val when is_map(val) -> {:t_object}
        _ -> {:t_unknown}
      end

    item
  end
  def enum_index(enum_value) do

      case enum_value do
        tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> :erlang.phash2(elem(tuple, 0))
        atom when is_atom(atom) -> :erlang.phash2(atom)
        _ -> 0
      end

    item
  end
  def enum_parameters(enum_value) do

      case enum_value do
        tuple when is_tuple(tuple) and tuple_size(tuple) > 1 ->
          tuple |> Tuple.to_list() |> Enum.drop(1)
        _ -> []
      end

    item
  end
  def enum_constructor(enum_value) do

      case enum_value do
        tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0) |> Atom.to_string()
        atom when is_atom(atom) -> Atom.to_string(atom)
        _ -> ""
      end

    item
  end
  def enum_eq(a, b) do
    a == b
    item
  end
  def get_class(object) do
    case object do %{__reflaxe_class__: mod} -> mod; %{__struct__: mod} -> mod; _ -> nil end
    item
  end
  def get_super_class(c) do
    ignore = c
    ignore
  end
  def get_class_name(c) do
    case c do mod when is_atom(mod) -> mod |> Module.split() |> Enum.join("."); _ -> nil end
    item
  end
  def get_enum_name(e) do
    case e do mod when is_atom(mod) -> mod |> Module.split() |> Enum.join("."); _ -> nil end
    item
  end
  def resolve_class(name) do
    case name do
  nil -> nil
  "String" -> String
  "Array" -> Array
  binary when is_binary(binary) ->
    binary
    |> String.split(".")
    |> Module.concat()
  other ->
    other
end
    item
  end
  def resolve_enum(name) do
    case name do
  nil -> nil
  binary when is_binary(binary) ->
    binary
    |> String.split(".")
    |> Module.concat()
  other ->
    other
end
    item
  end
  def is_type(value, t) do
    case value do %{__struct__: mod} -> mod == t; _ -> false end
    item
  end
  def create_instance(cl, args) do
    apply(cl, :new, args)
    item
  end
  def create_empty_instance(cl) do
    struct(cl)
    item
  end
  def create_enum(enum, constructor, params) do
    ignore_enum = enum

      tag = String.to_atom(constructor)
      values = case params do
        nil -> []
        arr when is_list(arr) -> arr
        other -> List.wrap(other)
      end
      List.to_tuple([tag | values])

    ignore_enum
  end
  def create_enum_index(enum, index, params) do
    _ignore_enum = enum
    _ignore_i = index
    ignore_p = params
    raise Reflaxe.Elixir.HaxeThrow, [value: "Type.createEnumIndex not implemented for Elixir target"]
    ignore_p
  end
  def get_enum_constructs(enum) do
    ignore_enum = enum
    []
    ignore_enum
  end
  def all_enums(enum) do
    ignore_enum = enum
    []
    ignore_enum
  end
end

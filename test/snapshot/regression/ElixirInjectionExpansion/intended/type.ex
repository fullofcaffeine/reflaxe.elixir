defmodule Type do
  def typeof(value) do
    
      case value do
        nil -> {:TNull}
        val when is_integer(val) -> {:TInt}
        val when is_float(val) -> {:TFloat}
        val when is_boolean(val) -> {:TBool}
        %{__struct__: mod} -> {:TClass, mod}
        val when is_tuple(val) and tuple_size(val) > 0 and is_atom(elem(val, 0)) -> {:TEnum, nil}
        val when is_map(val) -> {:TObject}
        _ -> {:TUnknown}
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
    case object do %{__struct__: mod} -> mod; _ -> nil end
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

defmodule Elixir.Otp.ChildSpecFormat do
  def module_ref(arg0) do
    arg0
  end
  def module_with_args(arg0, arg1) do
    {arg0, arg1}
  end
  def module_with_config(arg0, arg1) do
    {arg0, arg1}
  end
  def full_spec(arg0) do
    arg0
  end
  def __haxe_enum_constructs__() do
    ["ModuleRef", "ModuleWithArgs", "ModuleWithConfig", "FullSpec"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :module_ref -> 0
        1 -> 1
        :module_with_args -> 1
        2 -> 2
        :module_with_config -> 2
        3 -> 3
        :full_spec -> 3
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.Otp.ChildSpecFormat"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "ModuleRef"
        :module_ref -> "ModuleRef"
        1 -> "ModuleWithArgs"
        :module_with_args -> "ModuleWithArgs"
        2 -> "ModuleWithConfig"
        :module_with_config -> "ModuleWithConfig"
        3 -> "FullSpec"
        :full_spec -> "FullSpec"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.Otp.ChildSpecFormat"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "ModuleRef" when length(values) == 1 -> List.to_tuple([:module_ref | values])
      "ModuleRef" -> raise "Enum constructor ModuleRef expects 1 params for Elixir.Otp.ChildSpecFormat"
      "ModuleWithArgs" when length(values) == 2 -> List.to_tuple([:module_with_args | values])
      "ModuleWithArgs" -> raise "Enum constructor ModuleWithArgs expects 2 params for Elixir.Otp.ChildSpecFormat"
      "ModuleWithConfig" when length(values) == 2 -> List.to_tuple([:module_with_config | values])
      "ModuleWithConfig" -> raise "Enum constructor ModuleWithConfig expects 2 params for Elixir.Otp.ChildSpecFormat"
      "FullSpec" when length(values) == 1 -> List.to_tuple([:full_spec | values])
      "FullSpec" -> raise "Enum constructor FullSpec expects 1 params for Elixir.Otp.ChildSpecFormat"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Elixir.Otp.ChildSpecFormat"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 1 -> List.to_tuple([:module_ref | values])
      0 -> raise "Enum constructor ModuleRef expects 1 params for Elixir.Otp.ChildSpecFormat"
      1 when length(values) == 2 -> List.to_tuple([:module_with_args | values])
      1 -> raise "Enum constructor ModuleWithArgs expects 2 params for Elixir.Otp.ChildSpecFormat"
      2 when length(values) == 2 -> List.to_tuple([:module_with_config | values])
      2 -> raise "Enum constructor ModuleWithConfig expects 2 params for Elixir.Otp.ChildSpecFormat"
      3 when length(values) == 1 -> List.to_tuple([:full_spec | values])
      3 -> raise "Enum constructor FullSpec expects 1 params for Elixir.Otp.ChildSpecFormat"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Elixir.Otp.ChildSpecFormat"
    end
  end
  def __haxe_enum_all__() do
    []
  end
  def __haxe_enum_eq__(left, right) do
    left_name = __haxe_enum_constructor__(left)
    right_name = __haxe_enum_constructor__(right)
    left_params = case left do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 1 -> tl(Tuple.to_list(tuple))
      _ -> []
    end
    right_params = case right do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 1 -> tl(Tuple.to_list(tuple))
      _ -> []
    end
    left_name == right_name and left_params == right_params
  end
end

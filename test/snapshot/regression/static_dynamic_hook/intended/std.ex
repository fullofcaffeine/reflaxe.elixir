defmodule Std do
  def string(value) do
    Reflaxe.Elixir.HaxeFloat.to_string(value)
  end
  def parse_int(str) do
    Reflaxe.Elixir.HaxeInt.parse(str)
  end
  def parse_float(str) do
    Reflaxe.Elixir.HaxeFloat.parse(str)
  end
  def is(value, type) do

                # Convert type to string for comparison
                type_str =
                    type
                    |> to_string()
                    |> String.split(".")
                    |> List.last()

                case type_str do
                    "String" -> is_binary(value)
                    "Float" -> Reflaxe.Elixir.HaxeFloat.is_haxe_float(value)
                    "Int" -> is_integer(value)
                    "Bool" -> is_boolean(value)
                    "Array" -> is_list(value)
                    "Map" -> is_map(value)
                    _ ->
                        # For user-defined types, check if it's a struct with matching __struct__ field
                        case value do
                            %{__struct__: struct_type} -> struct_type == type
                            %{__reflaxe_class__: class_type} -> class_type == type
                            # For enums (tagged tuples), check if first element matches the type atom
                            {tag, _} when is_atom(tag) -> tag == type
                            {tag, _, _} when is_atom(tag) -> tag == type
                            {tag, _, _, _} when is_atom(tag) -> tag == type
                            _ -> false
                        end
                end

  end
  def is_of_type(value, type) do
    is(value, type)
  end
  def downcast(value, target_class) do
    if (is(value, target_class)), do: value, else: nil
  end
  def instance(value, target_class) do
    downcast(value, target_class)
  end
  def random(max) do
    if max <= 0, do: 0, else: (:rand.uniform(max) - 1)
  end
  def int(value) do
    trunc(value)
  end
end

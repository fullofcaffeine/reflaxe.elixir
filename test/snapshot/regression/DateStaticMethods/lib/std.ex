defmodule Std do
  def string(value) do
    inspect(value)
  end
  def parse_int(str) do
    
            case Integer.parse(str) do
                {num, _} -> num
                :error -> nil
            end
        
  end
  def parse_float(str) do
    
            case Float.parse(str) do
                {num, _} -> num
                :error -> nil
            end
        
  end
  def is(value, type) do
    (

            # Convert type to string for comparison
            type_str = to_string(type)
            
            case type_str do
                "String" -> is_binary(value)
                "Float" -> is_float(value)
                "Int" -> is_integer(value)
                "Bool" -> is_boolean(value)
                "Array" -> is_list(value)
                "Map" -> is_map(value)
                _ ->
                    # For user-defined types, check if it's a struct with matching __struct__ field
                    case value do
                        %{__struct__: struct_type} -> struct_type == type
                        # For enums (tagged tuples), check if first element matches the type atom
                        {tag, _} when is_atom(tag) -> tag == type
                        {tag, _, _} when is_atom(tag) -> tag == type
                        {tag, _, _, _} when is_atom(tag) -> tag == type
                        _ -> false
                    end
            end
        
)
  end
  def is_of_type(value, type) do
    Std.is(value, type)
  end
  def random() do
    :rand.uniform()
  end
  def int(value) do
    trunc(value)
  end
end
defmodule Std do
  def string(value) do
    __elixir__.("inspect({0})", value)
  end
  def parse_int(str) do
    __elixir__.("\n            case Integer.parse({0}) do\n                {num, _} -> num\n                :error -> nil\n            end\n        ", str)
  end
  def parse_float(str) do
    __elixir__.("\n            case Float.parse({0}) do\n                {num, _} -> num\n                :error -> nil\n            end\n        ", str)
  end
  def is(value, type) do
    __elixir__.("\n            # Convert type to string for comparison\n            type_str = to_string({1})\n            \n            case type_str do\n                \"String\" -> is_binary({0})\n                \"Float\" -> is_float({0})\n                \"Int\" -> is_integer({0})\n                \"Bool\" -> is_boolean({0})\n                \"Array\" -> is_list({0})\n                \"Map\" -> is_map({0})\n                _ ->\n                    # For user-defined types, check if it's a struct with matching __struct__ field\n                    case {0} do\n                        %{__struct__: struct_type} -> struct_type == {1}\n                        # For enums (tagged tuples), check if first element matches the type atom\n                        {tag, _} when is_atom(tag) -> tag == {1}\n                        {tag, _, _} when is_atom(tag) -> tag == {1}\n                        {tag, _, _, _} when is_atom(tag) -> tag == {1}\n                        _ -> false\n                    end\n            end\n        ", value, type)
  end
  def is_of_type(value, type) do
    Std.is(value, type)
  end
  def random() do
    __elixir__.(":rand.uniform()")
  end
  def int(value) do
    __elixir__.("trunc({0})", value)
  end
end
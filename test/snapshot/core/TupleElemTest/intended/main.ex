defmodule Main do
  def main() do
    tuple_value = 42
    tuple_tag = "ok"
    _tag = tuple_tag
    _value = tuple_value
    result = ["ok", 42]
    _first_elem = Map.get(result, :elem).(0)
    _second_elem = Map.get(result, :elem).(1)
    nil
  end
end

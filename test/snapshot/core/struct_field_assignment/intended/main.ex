defmodule Main do
  def main() do
    test = TestStruct.new()
    apply(Map.get(test, :__reflaxe_class__) || Map.get(test, :__struct__), :write, [test, nil])
  end
end

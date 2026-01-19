defmodule Main do
  def main() do
    printer = %JsonPrinter{}
    arr = [1, 2, 3, 4, 5]
    _ = JsonPrinter.write_array(printer, arr)
    obj = %{:name => "test", :values => [1, 2, 3]}
    _ = JsonPrinter.write_object(printer, obj)
  end
end

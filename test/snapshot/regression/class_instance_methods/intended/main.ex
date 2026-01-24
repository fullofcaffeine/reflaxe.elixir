defmodule Main do
  def main() do
    printer = SimplePrinter.new("Hello")
    _result = apply(Map.get(printer, :__reflaxe_class__) || Map.get(printer, :__struct__), :print, [printer, " World"])
    nil
  end
end

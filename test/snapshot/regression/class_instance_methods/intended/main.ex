defmodule Main do
  def main() do
    printer = SimplePrinter.new("Hello")
    _result = SimplePrinter.print(printer, " World")
    nil
  end
end

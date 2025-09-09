defmodule Main do
  def main() do
    printer = SimplePrinter.new("Hello")
    result = printer.print(" World")
    Log.trace(result, %{:file_name => "Main.hx", :line_number => 11, :class_name => "Main", :method_name => "main"})
  end
end
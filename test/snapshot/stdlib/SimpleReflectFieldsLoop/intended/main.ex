defmodule Main do
  def main() do
    obj = %{:a => 1, :b => 2, :c => 3}
    g = 0
    g1 = Map.keys(obj)
    for key <- g1, do: Log.trace(key, %{:file_name => "Main.hx", :line_number => 11, :class_name => "Main", :method_name => "main"})
  end
end
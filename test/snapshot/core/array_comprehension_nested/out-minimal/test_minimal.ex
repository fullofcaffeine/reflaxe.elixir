defmodule TestMinimal do
  def main() do
    g = []
    g = g ++ [g = []
g ++ [0]
g ++ [1]
g]
    g = g ++ [g = []
g ++ [0]
g ++ [1]
g]
    simple = g
g
    Log.trace(simple, %{:file_name => "TestMinimal.hx", :line_number => 9, :class_name => "TestMinimal", :method_name => "main"})
  end
end
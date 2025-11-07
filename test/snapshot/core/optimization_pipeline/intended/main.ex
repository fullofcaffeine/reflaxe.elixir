defmodule Main do
  defp dead_code_example() do
    42
    dead_var = "never executed"
    _ = Log.trace(dead_var, %{:file_name => "Main.hx", :line_number => 54, :class_name => "Main", :method_name => "deadCodeExample"})
  end
end

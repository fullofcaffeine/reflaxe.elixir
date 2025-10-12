defmodule Main do
  @compile {:nowarn_unused_function, [main: 0]}

  defp main() do
    Log.trace("Ecto error validation test", %{:file_name => "Main.hx", :line_number => 27, :class_name => "Main", :method_name => "main"})
  end
end

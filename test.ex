defmodule Test do
  defp main() do
    Log.trace("test", %{:file_name => "Test.hx", :line_number => 1, :class_name => "Test", :method_name => "main"})
  end
end
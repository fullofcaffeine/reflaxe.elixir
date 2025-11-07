defmodule Main do
  def main() do
    result = to_int({:custom, 418})
    _ = Log.trace(result, %{:file_name => "Main.hx", :line_number => 12, :class_name => "Main", :method_name => "main"})
  end
  def to_int(status) do
    (case status do
      {:ok} -> 200
      {:error, _value} -> 500
      {:custom, code} -> code
    end)
  end
end

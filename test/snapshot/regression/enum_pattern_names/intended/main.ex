defmodule Main do
  def main() do
    status = {:success, "Hello World"}
    result1 = ((case status do
  {:loading} -> "Loading..."
  {:success, data} -> "Got data: #{(fn -> data end).()}"
  {:failure, code, error} -> "Error #{(fn -> code end).()}: #{(fn -> error end).()}"
end))
    _ = Log.trace(result1, %{:file_name => "Main.hx", :line_number => 35, :class_name => "Main", :method_name => "main"})
    nested = {:ok, {:success, "Nested"}}
    result2 = ((case nested do
  {:ok, _value} ->
    fn_ = _value
    data = _value
    error = _value
    code = _value
    (case data do
      {:loading} -> "Still loading"
      {:success, value} ->
        value = value
        "Nested success: #{(fn -> value end).()}"
      {:failure, code, error} -> "Nested failure #{(fn -> code end).()}: #{(fn -> error end).()}"
    end)
  {:error, _value} ->
    fn_ = _value
    message = _value
    "Top level error: #{(fn -> message end).()}"
end))
    _ = Log.trace(result2, %{:file_name => "Main.hx", :line_number => 50, :class_name => "Main", :method_name => "main"})
    mixed = {:failure, "Network error", 500}
    result3 = ((case mixed do
  {:loading} -> "Loading"
  {:success, value} -> "Success (data ignored)"
  {:failure, error, code} -> "Error occurred: #{(fn -> error end).()}"
end))
    _ = Log.trace(result3, %{:file_name => "Main.hx", :line_number => 63, :class_name => "Main", :method_name => "main"})
  end
end

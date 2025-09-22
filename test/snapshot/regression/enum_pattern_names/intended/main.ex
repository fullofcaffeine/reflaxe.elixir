defmodule Main do
  def main() do
    status = {:success, "Hello World"}
    result1 = case (status) do
  {:loading} ->
    "Loading..."
  {:success, data} ->
    "Got data: " <> data
  {:failure, error, code} ->
    "Error " <> code.to_string() <> ": " <> error
end
    Log.trace(result1, %{:file_name => "Main.hx", :line_number => 35, :class_name => "Main", :method_name => "main"})
    nested = {:ok, {:success, "Nested"}}
    result2 = case (nested) do
  {:ok, status} ->
    case (status) do
      {:loading} ->
        "Still loading"
      {:success, data} ->
        "Nested success: " <> data
      {:failure, error, code} ->
        "Nested failure " <> code.to_string() <> ": " <> error
    end
  {:error, message} ->
    "Top level error: " <> message
end
    Log.trace(result2, %{:file_name => "Main.hx", :line_number => 50, :class_name => "Main", :method_name => "main"})
    mixed = {:failure, "Network error", 500}
    result3 = case (mixed) do
  {:loading} ->
    "Loading"
  {:success, data} ->
    "Success (data ignored)"
  {:failure, error, code} ->
    "Error occurred: " <> error
end
    Log.trace(result3, %{:file_name => "Main.hx", :line_number => 63, :class_name => "Main", :method_name => "main"})
  end
end
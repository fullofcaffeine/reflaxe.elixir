defmodule Main do
  def main() do
    status = {:success, "Hello World"}
    result1 = case status do
      {:loading} -> "Loading..."
      {:success, _value} ->
        fn_ = _value
        data = _value
        "Got data: " <> data
      {:failure, code, error} -> "Error " <> Kernel.to_string(code) <> ": " <> error
    end
    Log.trace(result1, %{:file_name => "Main.hx", :line_number => 35, :class_name => "Main", :method_name => "main"})
    nested = {:ok, {:success, "Nested"}}
    result2 = case nested do
      {:ok, _value} ->
        fn_ = _value
        data = _value
        error = _value
        case data do
          {:loading} -> "Still loading"
          {:success, _value} ->
            fn_ = _value
            value = _value
            value = value
            "Nested success: " <> value
          {:failure, code, error} -> "Nested failure " <> Kernel.to_string(code) <> ": " <> error
        end
      {:error, _value} ->
        fn_ = _value
        message = _value
        "Top level error: " <> message
    end
    Log.trace(result2, %{:file_name => "Main.hx", :line_number => 50, :class_name => "Main", :method_name => "main"})
    mixed = {:failure, "Network error", 500}
    result3 = case mixed do
      {:loading} -> "Loading"
      {:success, _value} -> "Success (data ignored)"
      {:failure, error, code} -> "Error occurred: " <> error
    end
    Log.trace(result3, %{:file_name => "Main.hx", :line_number => 63, :class_name => "Main", :method_name => "main"})
  end
end

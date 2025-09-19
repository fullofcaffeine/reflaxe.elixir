defmodule Main do
  def main() do
    status = {:success, "Hello World"}
    temp_string = nil
    case (status) do
      {:loading} ->
        temp_string = "Loading..."
      {:success, data} ->
        temp_string = "Got data: " <> data
      {:failure, error, code} ->
        temp_string = "Error " <> Kernel.to_string(code) <> ": " <> error
    end
    Log.trace(temp_string, %{:file_name => "Main.hx", :line_number => 35, :class_name => "Main", :method_name => "main"})
    nested = {:ok, {:success, "Nested"}}
    temp_string1 = nil
    case (nested) do
      {:ok, status} ->
        case (status) do
          {:loading} ->
            temp_string1 = "Still loading"
          {:success, data} ->
            temp_string1 = "Nested success: " <> data
          {:failure, error, code} ->
            temp_string1 = "Nested failure " <> Kernel.to_string(code) <> ": " <> error
        end
      {:error, message} ->
        temp_string1 = "Top level error: " <> message
    end
    Log.trace(temp_string1, %{:file_name => "Main.hx", :line_number => 50, :class_name => "Main", :method_name => "main"})
    mixed = {:failure, "Network error", 500}
    temp_string2 = nil
    case (mixed) do
      {:loading} ->
        temp_string2 = "Loading"
      {:success, _data} ->
        temp_string2 = "Success (data ignored)"
      {:failure, error, _code} ->
        temp_string2 = "Error occurred: " <> error
    end
    Log.trace(temp_string2, %{:file_name => "Main.hx", :line_number => 63, :class_name => "Main", :method_name => "main"})
  end
end
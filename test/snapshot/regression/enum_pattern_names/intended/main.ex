defmodule Main do
  def main() do
    status = {:success, "Hello World"}
    _result1 = ((case status do
  {:loading} -> "Loading..."
  {:success, data} -> "Got data: #{data}"
  {:failure, error, code} ->
    g_value = code
    code = g_value
    "Error #{Kernel.to_string(code)}: #{error}"
end))
    nested = {:ok, {:success, "Nested"}}
    _result2 = ((case nested do
  {:ok, status} ->
    (case status do
      {:loading} -> "Still loading"
      {:success, data} -> "Nested success: #{data}"
      {:failure, error, code} ->
        g_value = error
        error = g_value
        code = error
        "Nested failure #{Kernel.to_string(code)}: #{error}"
    end)
  {:error, message} -> "Top level error: #{message}"
end))
    mixed = {:failure, "Network error", 500}
    _result3 = ((case mixed do
  {:loading} -> "Loading"
  {:success, _data} -> "Success (data ignored)"
  {:failure, error, _code} -> "Error occurred: #{error}"
end))
    nil
  end
end

defmodule Main do
  def main() do
    status = {:success, "Hello World"}
    result1 = ((case status do
  {:loading} -> "Loading..."
  {:success, data} -> "Got data: #{(fn -> data end).()}"
  {:failure, error, code} ->
    g_value = code
    code = g_value
    "Error #{(fn -> Kernel.to_string(code) end).()}: #{(fn -> error end).()}"
end))
    nested = {:ok, {:success, "Nested"}}
    result2 = ((case nested do
  {:ok, status} ->
    (case status do
      {:loading} -> "Still loading"
      {:success, data} -> "Nested success: #{(fn -> data end).()}"
      {:failure, error, code} ->
        g_value = error
        error = g_value
        code = error
        "Nested failure #{(fn -> Kernel.to_string(code) end).()}: #{(fn -> error end).()}"
    end)
  {:error, message} -> "Top level error: #{(fn -> message end).()}"
end))
    mixed = {:failure, "Network error", 500}
    result3 = ((case mixed do
  {:loading} -> "Loading"
  {:success, _data} -> "Success (data ignored)"
  {:failure, error, _code} -> "Error occurred: #{(fn -> error end).()}"
end))
    nil
  end
end

defmodule Main do
  def main() do
    status = {:success, "Hello World"}
    result1 = ((case status do
  {:loading} -> "Loading..."
  {:success, data} -> "Got data: #{(fn -> data end).()}"
  {:failure, error, code} ->
    error = _g
    code = _g1
    "Error #{(fn -> Kernel.to_string(code) end).()}: #{(fn -> error end).()}"
end))
    nested = {:ok, {:success, "Nested"}}
    result2 = ((case nested do
  {:ok, data} ->
    (case data do
      {:loading} -> "Still loading"
      {:success, value} ->
        value = value
        "Nested success: #{(fn -> value end).()}"
      {:failure, error, code} ->
        error = _g1
        code = _g
        "Nested failure #{(fn -> Kernel.to_string(code) end).()}: #{(fn -> error end).()}"
    end)
  {:error, reason} -> "Top level error: #{(fn -> message end).()}"
end))
    mixed = {:failure, "Network error", 500}
    result3 = ((case mixed do
  {:loading} -> "Loading"
  {:success, data} -> "Success (data ignored)"
  {:failure, error, code} ->
    error = _g
    "Error occurred: #{(fn -> error end).()}"
end))
    nil
  end
end

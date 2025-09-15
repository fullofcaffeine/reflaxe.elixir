defmodule Main do
  def main() do
    result = to_int({:custom, 418})
    Log.trace(result, nil)
  end
  
  def to_int(status) do
    case status do
      {:ok} ->
        200
      {:error, _msg} ->  # msg is unused, correctly prefixed
        500
      {:custom, code} ->  # code is USED, no underscore
        code
    end
  end
end
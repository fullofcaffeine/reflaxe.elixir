defmodule Main do
  def main() do
    result = to_int({:custom, 418})
    nil
  end
  def to_int(status) do
    (case status do
      {:ok} -> 200
      {:error, __reason} -> 500
      {:custom, code} -> code
    end)
  end
end

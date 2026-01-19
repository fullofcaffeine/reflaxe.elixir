defmodule Main do
  def main() do
    (case {:ok, "test"} do
      {:ok, _value} -> nil
      {:error, _msg} -> nil
    end)
  end
end

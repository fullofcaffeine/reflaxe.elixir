defmodule Main do
  def main() do
    _msg = (case {:created, "Hello world"} do
      {:created, _content} -> nil
      {:updated, _id, _content} -> nil
      {:deleted, _id} -> nil
    end)
    (case {:ok, "success"} do
      {:ok, _value} -> nil
      {:error, _msg} -> nil
    end)
  end
end

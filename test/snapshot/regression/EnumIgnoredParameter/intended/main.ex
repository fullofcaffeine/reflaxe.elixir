defmodule Main do
  defp subscribe() do
    {:ok, nil}
  end
  def main() do
    (case subscribe() do
      {:ok, _value} -> nil
      {:error, _msg} -> nil
    end)
    (case subscribe() do
      {:ok, value} ->
        cond do
          not Kernel.is_nil(value) -> nil
          true -> nil
        end
      {:error, _msg} -> nil
    end)
    (case process_data() do
      {:data, _id, _timestamp, _name, _metadata} -> nil
      {:no_data} -> nil
    end)
  end
  defp process_data() do
    {:data, 42, DateTime.to_unix(DateTime.utc_now(), :millisecond), "Test", nil}
  end
end

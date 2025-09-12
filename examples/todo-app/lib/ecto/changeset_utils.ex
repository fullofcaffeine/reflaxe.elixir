defmodule ChangesetUtils do
  def unwrap_or(_result, default_value) do
    case (_result) do
      {:ok, g} ->
        g = elem(_result, 1)
        value = g
        value
      {:error, g} ->
        _g = elem(_result, 1)
        default_value
    end
  end
  def to_option(_result) do
    case (_result) do
      {:ok, g} ->
        g = elem(_result, 1)
        value = g
        {:some, value}
      {:error, g} ->
        _g = elem(_result, 1)
        {:none}
    end
  end
end
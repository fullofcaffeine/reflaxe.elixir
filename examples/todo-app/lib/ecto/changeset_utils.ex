defmodule ChangesetUtils do
  def unwrap_or(result, default_value) do
    case (result) do
      {:ok, g} ->
        g = elem(result, 1)
        value = g
        value
      {:error, g} ->
        _g = elem(result, 1)
        default_value
    end
  end
  def to_option(result) do
    case (result) do
      {:ok, g} ->
        g = elem(result, 1)
        value = g
        {:some, value}
      {:error, g} ->
        _g = elem(result, 1)
        {:none}
    end
  end
end
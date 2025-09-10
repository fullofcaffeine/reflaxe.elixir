defmodule ChangesetUtils do
  def unwrap(result) do
    case (result) do
      {:ok, value} ->
        (g)
      {:error, g} ->
        throw("Changeset validation failed: " <> (if (errors == nil), do: "null", else: errors.to_string()))
    end
  end
  def unwrap_or(result, default_value) do
    case (result) do
      {:ok, value} ->
        (g)
      {:error, default_value} ->
        default_value
    end
  end
  def to_option(result) do
    case (result) do
      {:ok, value} ->
        {:Some, (g)}
      {:error, g} ->
        {:None}
    end
  end
end
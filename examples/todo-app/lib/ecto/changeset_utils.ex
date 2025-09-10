defmodule ChangesetUtils do
  def unwrap(result) do
    case (result) do
      {:ok, g} ->
        (g)
      {:error, g} ->
        throw("Changeset validation failed: " <> (if (errors == nil), do: "null", else: errors.to_string()))
    end
  end
  def unwrap_or(result, default_value) do
    case (result) do
      {:ok, g} ->
        (g)
      {:error, g} ->
        default_value
    end
  end
  def to_option(result) do
    case (result) do
      {:ok, g} ->
        {:Some, (g)}
      {:error, g} ->
        {:None}
    end
  end
end
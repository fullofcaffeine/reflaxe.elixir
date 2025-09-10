defmodule ChangesetUtils do
  def unwrap(result) do
    case (result) do
      {:ok, _} ->
        (g)
      {:error, _} ->
        throw("Changeset validation failed: " <> (if (errors == nil), do: "null", else: errors.to_string()))
    end
  end
  def unwrap_or(result, default_value) do
    case (result) do
      {:ok, _} ->
        (g)
      {:error, _} ->
        default_value
    end
  end
  def to_option(result) do
    case (result) do
      {:ok, _} ->
        {:Some, (g)}
      {:error, _} ->
        {:None}
    end
  end
end
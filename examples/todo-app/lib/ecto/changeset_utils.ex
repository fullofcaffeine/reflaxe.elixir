defmodule ChangesetUtils do
  def unwrap(result) do
    case (result) do
      {:ok, value} ->
        (value)
      {:error, reason} ->
        throw("Changeset validation failed: " <> (if (errors == nil), do: "null", else: errors.to_string()))
    end
  end
  def unwrap_or(result, default_value) do
    case (result) do
      {:ok, value} ->
        (value)
      {:error, reason} ->
        default_value
    end
  end
  def to_option(result) do
    case (result) do
      {:ok, value} ->
        {:Some, (value)}
      {:error, reason} ->
        {:None}
    end
  end
end
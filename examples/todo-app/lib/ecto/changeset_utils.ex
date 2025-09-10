defmodule ChangesetUtils do
  def unwrap(_result) do
    case (_result) do
      {:ok, _} ->
        (g)
      {:error, _} ->
        throw("Changeset validation failed: " <> (if (errors == nil), do: "null", else: errors.to_string()))
    end
  end
  def unwrap_or(_result, default_value) do
    case (_result) do
      {:ok, _} ->
        (g)
      {:error, _} ->
        default_value
    end
  end
  def to_option(_result) do
    case (_result) do
      {:ok, _} ->
        {:Some, (g)}
      {:error, _} ->
        {:None}
    end
  end
end
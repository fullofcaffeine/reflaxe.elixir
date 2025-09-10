defmodule ChangesetUtils do
  def unwrap(_result) do
    case (_result) do
      {:ok, _} ->
        g = elem(_result, 1)
        (g)
      {:error, _} ->
        g = elem(_result, 1)
        changeset = g
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} -> msg end)
        throw("Changeset validation failed: " <> (if (errors == nil), do: "null", else: errors.to_string()))
    end
  end
  def unwrap_or(_result, default_value) do
    case (_result) do
      {:ok, _} ->
        g = elem(_result, 1)
        (g)
      {:error, _} ->
        _g = elem(_result, 1)
        default_value
    end
  end
  def to_option(_result) do
    case (_result) do
      {:ok, _} ->
        g = elem(_result, 1)
        {:Some, (g)}
      {:error, _} ->
        _g = elem(_result, 1)
        {:None}
    end
  end
end
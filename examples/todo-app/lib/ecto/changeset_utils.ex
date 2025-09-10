defmodule ChangesetUtils do
  def unwrap(_result) do
    case (_result) do
      {:ok, value} ->
        g = elem(_result, 1)
        value = value
        value
      {:error, reason} ->
        g = elem(_result, 1)
        changeset = reason
        errors = Ecto.Changeset.traverse_errors(reason, fn {msg, opts} -> msg end)
        throw("Changeset validation failed: " <> (if (errors == nil), do: "null", else: errors.to_string()))
    end
  end
  def unwrap_or(_result, default_value) do
    case (_result) do
      {:ok, value} ->
        g = elem(_result, 1)
        value = value
        value
      {:error, reason} ->
        _g = elem(_result, 1)
        default_value
    end
  end
  def to_option(_result) do
    case (_result) do
      {:ok, value} ->
        g = elem(_result, 1)
        value = value
        {:Some, value}
      {:error, reason} ->
        _g = elem(_result, 1)
        {:None}
    end
  end
end
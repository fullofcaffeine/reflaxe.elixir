defmodule ChangesetUtils do
  def unwrap(_result) do
    case (_result) do
      {:ok, g} ->
        g = elem(_result, 1)
        value = g
        value
      {:error, g} ->
        g = elem(_result, 1)
        changeset = g
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} -> msg end)
        throw("Changeset validation failed: " <> (if (errors == nil), do: "null", else: errors.to_string()))
    end
  end
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
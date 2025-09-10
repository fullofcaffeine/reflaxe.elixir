defmodule ChangesetUtils do
  def unwrap(result) do
    case (result) do
      {:ok, value} ->
        g = elem(result, 1)
        value = value
        value
      {:error, reason} ->
        g = elem(result, 1)
        changeset = reason
        errors = Ecto.Changeset.traverse_errors(reason, fn {msg, opts} -> msg end)
        throw("Changeset validation failed: " <> (if (errors == nil), do: "null", else: errors.to_string()))
    end
  end
  def unwrap_or(result, default_value) do
    case (result) do
      {:ok, value} ->
        g = elem(result, 1)
        value = value
        value
      {:error, reason} ->
        _g = elem(result, 1)
        default_value
    end
  end
  def to_option(result) do
    case (result) do
      {:ok, value} ->
        g = elem(result, 1)
        value = value
        {:Some, value}
      {:error, reason} ->
        _g = elem(result, 1)
        {:None}
    end
  end
end
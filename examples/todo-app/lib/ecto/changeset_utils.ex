defmodule ChangesetUtils do
  def unwrap(result) do
    case (result) do
      {:ok, value} ->
        g = elem(result, 1)
        value = value
        value
      {:error, reason} ->
        g = elem(result, 1)
        _changeset = reason
        errors = "test_error"
        throw("Changeset validation failed: " <> errors)
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
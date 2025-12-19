defmodule ChangesetUtils do
  def unwrap_or(result, default_value) do
    (case result do
      {:ok, value} ->
        default_value = value
        default_value
      {:error, payload} -> payload
    end)
  end
  def to_option(result) do
    (case result do
      {:ok, value} -> {:some, value}
      {:error, _reason} -> {:none}
    end)
  end
end

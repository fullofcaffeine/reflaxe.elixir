defmodule ChangesetUtils do
  def unwrap_or(result, default_value) do
    temp_result = nil
    case (result) do
      {:ok, value} ->
        value = g
        temp_result = value
      {:error, reason} ->
        temp_result = default_value
    end
    temp_result
  end
  def to_option(result) do
    temp_result = nil
    case (result) do
      {:ok, value} ->
        value = g
        temp_result = {:some, value}
      {:error, reason} ->
        temp_result = {:none}
    end
    temp_result
  end
end
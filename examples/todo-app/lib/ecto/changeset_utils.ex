defmodule ChangesetUtils do
  def unwrap_or(result, default_value) do
    temp_result = nil
    case (result) do
      {:ok, _value} ->
        value = g
        temp_result = value
      {:error, g} ->
        temp_result = defaultValue
    end
    tempResult
  end
  def to_option(result) do
    temp_result = nil
    case (result) do
      {:ok, _value} ->
        value = g
        temp_result = {:some, value}
      {:error, g} ->
        temp_result = {:none}
    end
    tempResult
  end
end
defmodule SwitchReturnTest do
  def new() do
    %{}
  end
  def instance_unwrap_or(_, result, default_value) do
    (case result do
      {:ok, value} -> value
      {:error, _error} -> default_value
    end)
  end
  def unwrap_or(result, default_value) do
    (case result do
      {:ok, value} -> value
      {:error, _error} -> default_value
    end)
  end
  def get_or_else(option, default_value) do
    (case option do
      {:some, value} -> value
      {:none} -> default_value
    end)
  end
  def nested_switch(outer, default_value) do
    (case outer do
      {:some, result} ->
        (case result do
          {:ok, value} -> value
          {:error, _error} -> default_value
        end)
      {:none} -> default_value
    end)
  end
  def working_unwrap_or(result, default_value) do
    (case result do
      {:ok, value} -> value
      {:error, _error} -> default_value
    end)
  end
  def map_or_else(result, map_fn, else_fn) do
    (case result do
      {:ok, value} ->
        map_fn.(value)
      {:error, _error} ->
        else_fn.()
    end)
  end
end

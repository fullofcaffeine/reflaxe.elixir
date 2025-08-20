defmodule ConsoleLogger do
  @moduledoc """
    ConsoleLogger struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  # Instance functions
  @doc "Function log"
  @spec log(t(), String.t()) :: nil
  def log(%__MODULE__{} = struct, message) do
    Log.trace("[LOG] " <> message, %{"fileName" => "Storage.hx", "lineNumber" => 103, "className" => "ConsoleLogger", "methodName" => "log"})
  end

  @doc "Function debug"
  @spec debug(t(), String.t()) :: nil
  def debug(%__MODULE__{} = struct, message) do
    Log.trace("[DEBUG] " <> message, %{"fileName" => "Storage.hx", "lineNumber" => 108, "className" => "ConsoleLogger", "methodName" => "debug"})
  end

end

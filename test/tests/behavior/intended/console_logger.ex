defmodule ConsoleLogger do
  @moduledoc """
    ConsoleLogger struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  # Instance functions
  @doc "Generated from Haxe log"
  def log(%__MODULE__{} = struct, message) do
    Log.trace("[LOG] " <> message, %{"fileName" => "Storage.hx", "lineNumber" => 103, "className" => "ConsoleLogger", "methodName" => "log"})
  end

  @doc "Generated from Haxe debug"
  def debug(%__MODULE__{} = struct, message) do
    Log.trace("[DEBUG] " <> message, %{"fileName" => "Storage.hx", "lineNumber" => 108, "className" => "ConsoleLogger", "methodName" => "debug"})
  end

end

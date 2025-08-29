defmodule ApplicationResultTools do
  @moduledoc """
    ApplicationResultTools module generated from Haxe

     * Helper class for Application result construction
  """

  # Static functions
  @doc "Generated from Haxe ok"
  def ok(state) do
    {:Ok, state}
  end

  @doc "Generated from Haxe error"
  def error(reason) do
    {:Error, reason}
  end

  @doc "Generated from Haxe ignore"
  def ignore() do
    :Ignore
  end

end

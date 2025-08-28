defmodule FlashMapTools do
  @moduledoc """
    FlashMapTools module generated from Haxe

     * Utilities for working with Phoenix flash maps
  """

  # Static functions
  @doc "Generated from Haxe hasAny"
  def has_any(flash_map) do
    ((((flash_map.info != nil) || (flash_map.success != nil)) || (flash_map.warning != nil)) || (flash_map.error != nil))
  end

  @doc "Generated from Haxe getAll"
  def get_all(flash_map) do
    messages = []

    messages = if ((flash_map.info != nil)), do: messages ++ [Flash.info(flash_map.info)], else: messages

    messages = if ((flash_map.success != nil)), do: messages ++ [Flash.success(flash_map.success)], else: messages

    messages = if ((flash_map.warning != nil)), do: messages ++ [Flash.warning(flash_map.warning)], else: messages

    messages = if ((flash_map.error != nil)), do: messages ++ [Flash.error(flash_map.error)], else: messages

    messages
  end

  @doc "Generated from Haxe clear"
  def clear() do
    %{}
  end

end

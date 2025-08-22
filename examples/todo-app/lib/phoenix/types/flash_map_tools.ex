defmodule FlashMapTools do
  @moduledoc """
    FlashMapTools module generated from Haxe

     * Utilities for working with Phoenix flash maps
  """

  # Static functions
  @doc """
    Check if flash map has any messages

    @param flashMap Phoenix flash map
    @return Bool True if any flash messages exist
  """
  @spec has_any(FlashMap.t()) :: boolean()
  def has_any(flash_map) do
    ((((flash_map.info != nil) || (flash_map.success != nil)) || (flash_map.warning != nil)) || (flash_map.error != nil))
  end

  @doc """
    Get all flash messages as structured array

    @param flashMap Phoenix flash map
    @return Array<FlashMessage> Array of structured flash messages
  """
  @spec get_all(FlashMap.t()) :: Array.t()
  def get_all(flash_map) do
    (
          messages = []
          if ((flash_map.info != nil)) do
          messages ++ [Flash.info(flash_map.info)]
        end
          if ((flash_map.success != nil)) do
          messages ++ [Flash.success(flash_map.success)]
        end
          if ((flash_map.warning != nil)) do
          messages ++ [Flash.warning(flash_map.warning)]
        end
          if ((flash_map.error != nil)) do
          messages ++ [Flash.error(flash_map.error)]
        end
          messages
        )
  end

  @doc """
    Clear all flash messages

    @return FlashMap Empty flash map
  """
  @spec clear() :: FlashMap.t()
  def clear() do
    %{}
  end

end

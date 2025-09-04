defmodule FlashMapTools do
  def has_any(flash_map) do
    flash_map.info != nil || flash_map.success != nil || flash_map.warning != nil || flash_map.error != nil
  end
  def get_all(flash_map) do
    messages = []
    if (flash_map.info != nil) do
      messages = messages ++ [Phoenix.Flash.info(flash_map.info)]
    end
    if (flash_map.success != nil) do
      messages = messages ++ [Phoenix.Flash.success(flash_map.success)]
    end
    if (flash_map.warning != nil) do
      messages = messages ++ [Phoenix.Flash.warning(flash_map.warning)]
    end
    if (flash_map.error != nil) do
      messages = messages ++ [Phoenix.Flash.error(flash_map.error)]
    end
    messages
  end
  def clear() do
    %{}
  end
end
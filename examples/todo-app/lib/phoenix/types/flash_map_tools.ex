defmodule FlashMapTools do
  def has_any(flash_map) do
    flash_map.info != nil or flash_map.success != nil or flash_map.warning != nil or flash_map.error != nil
  end
  def get_all(flash_map) do
    messages = []
    if (flash_map.info != nil) do
      messages = messages ++ [Flash.info(flash_map.info, nil)]
    end
    if (flash_map.success != nil) do
      messages = messages ++ [Flash.success(flash_map.success, nil)]
    end
    if (flash_map.warning != nil) do
      messages = messages ++ [Flash.warning(flash_map.warning, nil)]
    end
    if (flash_map.error != nil) do
      messages = messages ++ [Flash.error(flash_map.error, nil, nil)]
    end
    messages
  end
  def clear() do
    %{}
  end
end
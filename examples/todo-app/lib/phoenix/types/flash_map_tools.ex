defmodule FlashMapTools do
  def hasAny(flashMap) do
    flash_map.info != nil || flash_map.success != nil || flash_map.warning != nil || flash_map.error != nil
  end
  def getAll(flashMap) do
    messages = []
    if (flash_map.info != nil) do
      messages.push(Flash.info(flash_map.info))
    end
    if (flash_map.success != nil) do
      messages.push(Flash.success(flash_map.success))
    end
    if (flash_map.warning != nil) do
      messages.push(Flash.warning(flash_map.warning))
    end
    if (flash_map.error != nil) do
      messages.push(Flash.error(flash_map.error))
    end
    messages
  end
  def clear() do
    %{}
  end
end
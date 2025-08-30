defmodule FlashMapTools do
  def hasAny(flash_map) do
    flash_map.info != nil || flash_map.success != nil || flash_map.warning != nil || flash_map.error != nil
  end
  def getAll(flash_map) do
    messages = []
    if (flash_map.info != nil), do: messages.push(Flash.info(flash_map.info))
    if (flash_map.success != nil), do: messages.push(Flash.success(flash_map.success))
    if (flash_map.warning != nil), do: messages.push(Flash.warning(flash_map.warning))
    if (flash_map.error != nil), do: messages.push(Flash.error(flash_map.error))
    messages
  end
  def clear() do
    %{}
  end
end
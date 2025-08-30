defmodule FlashMapTools do
  def hasAny(flashMap) do
    flashMap.info != nil || flashMap.success != nil || flashMap.warning != nil || flashMap.error != nil
  end
  def getAll(flashMap) do
    messages = []
    if (flashMap.info != nil), do: messages.push(Flash.info(flashMap.info))
    if (flashMap.success != nil), do: messages.push(Flash.success(flashMap.success))
    if (flashMap.warning != nil), do: messages.push(Flash.warning(flashMap.warning))
    if (flashMap.error != nil), do: messages.push(Flash.error(flashMap.error))
    messages
  end
  def clear() do
    %{}
  end
end
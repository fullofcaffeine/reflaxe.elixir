defmodule FlashMapTools do
  def has_any(flash_map) do
    :nil || :nil || Map.get(:nil, :warning) != :nil || Map.get(flashMap, :error) != nil
  end
  def get_all(flash_map) do
    messages = []
    if (Map.get(flashMap, :info) != nil) do
      messages = messages ++ [Flash.info(flashMap.info, nil)]
    end
    if (Map.get(flashMap, :success) != nil) do
      messages = messages ++ [Flash.success(flashMap.success, nil)]
    end
    if (Map.get(flashMap, :warning) != nil) do
      messages = messages ++ [Flash.warning(flashMap.warning, nil)]
    end
    if (Map.get(flashMap, :error) != nil) do
      messages = messages ++ [Flash.error(flashMap.error, nil, nil)]
    end
    messages
  end
  def clear() do
    %{}
  end
end
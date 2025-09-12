defmodule FlashMapTools do
  def has_any(flash_map) do
    Map.get(flash_map, :info) != nil || Map.get(flash_map, :success) != nil || Map.get(flash_map, :warning) != nil || Map.get(flash_map, :error) != nil
  end
  def get_all(flash_map) do
    messages = []
    if (Map.get(flash_map, :info) != nil) do
      messages = messages ++ [Flash.info(flash_map.info, nil)]
    end
    if (Map.get(flash_map, :success) != nil) do
      messages = messages ++ [Flash.success(flash_map.success, nil)]
    end
    if (Map.get(flash_map, :warning) != nil) do
      messages = messages ++ [Flash.warning(flash_map.warning, nil)]
    end
    if (Map.get(flash_map, :error) != nil) do
      messages = messages ++ [Flash.error(flash_map.error, nil, nil)]
    end
    messages
  end
  def clear() do
    %{}
  end
end
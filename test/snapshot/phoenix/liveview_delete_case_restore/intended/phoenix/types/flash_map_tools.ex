defmodule FlashMapTools do
  def has_any(flash_map) do
    not Kernel.is_nil(flash_map.info) or not Kernel.is_nil(flash_map.success) or not Kernel.is_nil(flash_map.warning) or not Kernel.is_nil(flash_map.error)
  end
  def get_all(flash_map) do
    info_messages = if (not Kernel.is_nil(flash_map.info)), do: [MyApp.Flash.info(flash_map.info, nil)], else: []
    success_messages = if (not Kernel.is_nil(flash_map.success)), do: [MyApp.Flash.success(flash_map.success, nil)], else: []
    warning_messages = if (not Kernel.is_nil(flash_map.warning)), do: [MyApp.Flash.warning(flash_map.warning, nil)], else: []
    error_messages = if (not Kernel.is_nil(flash_map.error)), do: [MyApp.Flash.error(flash_map.error, nil, nil)], else: []
    info_messages ++ success_messages ++ warning_messages ++ error_messages
  end
  def clear() do
    %{}
  end
end

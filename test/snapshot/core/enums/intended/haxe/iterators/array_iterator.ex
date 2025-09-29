defmodule ArrayIterator do
  def has_next(struct) do
    __instance_variable_not_available_in_this_context__.current < length(__instance_variable_not_available_in_this_context__.array)
  end
  def next(struct) do
    __instance_variable_not_available_in_this_context__.array[__instance_variable_not_available_in_this_context__.current + 1]
  end
end
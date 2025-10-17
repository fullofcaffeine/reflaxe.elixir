defmodule PresenceHelpers do
  def simple_list(presences) do
    Map.keys(presences)
  end
  def is_present(presences, key) do
    Map.has_key?(presences, key)
  end
  def count(presences) do
    map_size(presences)
  end
end

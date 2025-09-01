defmodule Phoenix.EmbedStrategy do
  def replace() do
    {:Replace}
  end
  def append() do
    {:Append}
  end
end
defmodule Phoenix.EmbedStrategy do
  def replace() do
    {:replace}
  end
  def append() do
    {:append}
  end
end

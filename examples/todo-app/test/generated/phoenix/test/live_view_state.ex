defmodule Phoenix.Test.LiveViewState do
  use Phoenix.Component
  def mounted() do
    {:mounted}
  end
  def disconnected() do
    {:disconnected}
  end
  def error(arg0) do
    {:error, arg0}
  end
  def redirecting(arg0) do
    {:redirecting, arg0}
  end
end

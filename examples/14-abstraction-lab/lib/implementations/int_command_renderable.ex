defmodule AbstractionLab.IntCommandRenderable do
  def render_command(_, value) do
    "retry:#{Kernel.to_string(value)}"
  end
  def render_summary(_, value) do
    "retry attempt ##{Kernel.to_string(value)}"
  end
end

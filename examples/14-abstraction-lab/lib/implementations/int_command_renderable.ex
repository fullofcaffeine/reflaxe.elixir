defmodule AbstractionLab.IntCommandRenderable do
  def render_command(_struct, value) do
    "retry:#{Kernel.to_string(value)}"
  end
  def render_summary(_struct, value) do
    "retry attempt ##{Kernel.to_string(value)}"
  end
end

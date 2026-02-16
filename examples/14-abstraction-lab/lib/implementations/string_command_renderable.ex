defmodule AbstractionLab.StringCommandRenderable do
  def render_command(_struct, value) do
    "run:#{value}"
  end
  def render_summary(_struct, value) do
    "command(#{Kernel.to_string(String.length(value))} chars)"
  end
end

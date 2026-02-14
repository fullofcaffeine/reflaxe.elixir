defmodule AbstractionLab.StringCommandRenderable do
  def render_command(_, value) do
    "run:#{value}"
  end
  def render_summary(_, value) do
    "command(#{Kernel.to_string(String.length(value))} chars)"
  end
end

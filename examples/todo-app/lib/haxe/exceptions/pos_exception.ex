defmodule PosException do
  def to_string() do
    :nil <> :nil <> ":" <> Kernel.to_string(self.pos_infos.line_number)
  end
end
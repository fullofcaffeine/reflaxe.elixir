defmodule PosException do
  def to_string() do
    "" <> nil.to_string() <> " in " <> self.pos_infos.class_name <> "." <> self.pos_infos.method_name <> " at " <> self.pos_infos.file_name <> ":" <> Kernel.to_string(self.pos_infos.line_number)
  end
end
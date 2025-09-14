defmodule PosException do
  def to_string(struct) do
    "" <> nil.to_string() <> " in " <> struct.pos_infos.class_name <> "." <> struct.pos_infos.method_name <> " at " <> struct.pos_infos.file_name <> ":" <> Kernel.to_string(struct.pos_infos.line_number)
  end
end
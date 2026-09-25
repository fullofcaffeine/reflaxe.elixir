defmodule PosException do
  defexception [:message, :previous, :native, :stack, :pos_infos]
  def new(message, previous, pos) do
    pos_infos =
      if Kernel.is_nil(pos) do
        %{:fileName => "(unknown)", :lineNumber => 0, :className => "(unknown)", :methodName => "(unknown)"}
      else
        pos
      end
    %__MODULE__{message: message, previous: previous, native: nil, stack: [], pos_infos: pos_infos}
  end
  defp pos_field(pos_infos, camel_key, snake_key) do
    Map.get(pos_infos, camel_key) || Map.get(pos_infos, snake_key)
  end
  def to_string(struct) do
    class_name = pos_field(struct.pos_infos, :className, :class_name)
    method_name = pos_field(struct.pos_infos, :methodName, :method_name)
    file_name = pos_field(struct.pos_infos, :fileName, :file_name)
    line_number = pos_field(struct.pos_infos, :lineNumber, :line_number)
    "#{Kernel.to_string(struct.message)} in #{class_name}.#{method_name} at #{file_name}:#{line_number}"
  end
end

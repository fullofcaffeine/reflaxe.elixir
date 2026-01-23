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
  def to_string(struct), do: "#{Kernel.to_string(struct.message)} in #{struct.pos_infos.className}.#{struct.pos_infos.methodName} at #{struct.pos_infos.fileName}:#{struct.pos_infos.lineNumber}"
end

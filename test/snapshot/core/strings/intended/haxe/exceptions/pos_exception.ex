defmodule PosException do
  defexception [:message, :pos_infos]
  def new(message, previous, pos) do
    pos_infos =
      if Kernel.is_nil(pos) do
        %{:fileName => "(unknown)", :lineNumber => 0, :className => "(unknown)", :methodName => "(unknown)"}
      else
        pos
      end
    %{:message => message, :previous => previous, :posInfos => pos_infos}
  end
  def to_string(struct), do: "#{Kernel.to_string(struct.message)} in #{struct.posInfos.className}.#{struct.posInfos.methodName} at #{struct.posInfos.fileName}:#{struct.posInfos.lineNumber}"
end

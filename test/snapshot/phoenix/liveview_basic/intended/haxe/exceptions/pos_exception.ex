defmodule PosException do
  def to_string(struct), do: "#{Kernel.to_string(struct.message)} in #{struct.posInfos.className}.#{struct.posInfos.methodName} at #{struct.posInfos.fileName}:#{struct.posInfos.lineNumber}"
end

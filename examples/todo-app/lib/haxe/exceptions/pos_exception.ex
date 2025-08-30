defmodule PosException do
  def new() do
    fn message, previous, pos -> nil.call(message, previous)
if (pos == nil) do
  posInfos = %{:fileName => "(unknown)", :lineNumber => 0, :className => "(unknown)", :methodName => "(unknown)"}
else
  posInfos = pos
end end
  end
  def toString() do
    fn -> "" + nil.toString() + " in " + struct.posInfos.className + "." + struct.posInfos.methodName + " at " + struct.posInfos.fileName + ":" + struct.posInfos.lineNumber end
  end
end
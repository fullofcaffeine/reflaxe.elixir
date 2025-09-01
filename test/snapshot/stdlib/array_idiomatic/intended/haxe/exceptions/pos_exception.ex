defmodule PosException do
  def new(message, previous, pos) do
    %{}
  end
  def to_string(struct) do
    "" + nil.toString() + " in " + struct.posInfos.className + "." + struct.posInfos.methodName + " at " + struct.posInfos.fileName + ":" + struct.posInfos.lineNumber
  end
end
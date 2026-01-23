defmodule Eof do
  import Kernel, except: [to_string: 1], warn: false
  def new() do
    %{}
  end
  def to_string(_) do
    "Eof"
  end
end

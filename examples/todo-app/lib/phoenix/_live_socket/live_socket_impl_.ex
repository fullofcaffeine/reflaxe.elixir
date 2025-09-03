defmodule LiveSocket_Impl_ do
  def _new(socket) do
    this1 = nil
    this1 = socket
    this1
  end
  def pipe(socket, fn) do
    fn.(socket)
  end
end
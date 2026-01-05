defmodule LiveSocket_Impl_ do
  use Phoenix.Component
  def _new(socket) do
    socket
  end
  def pipe(socket, func) do
    func.(socket)
  end
end

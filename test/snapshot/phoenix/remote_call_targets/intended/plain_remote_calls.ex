defmodule PlainRemoteCalls do
  def nested(socket, admission) do
    (case admission do
      {:denied} -> socket
      {:granted, reference} -> Phoenix.Socket.assign(socket, :erlang.binary_to_atom("fixed"), reference)
    end)
  end
end

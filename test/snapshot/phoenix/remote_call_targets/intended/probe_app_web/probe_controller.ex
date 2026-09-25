defmodule ProbeAppWeb.ProbeController do
  use ProbeAppWeb, :controller
  def halted(conn) do
    Conn_Impl_.is_halted(conn)
  end
  def helper(value) do
    OrdinaryHelper.assign(value, 4, 7)
  end
  def decode(value) do
    (case TermDecoder.fetch_atom_key(value, :erlang.binary_to_atom("fixed")) do
      {:ok, field} -> field
      {:error, _} -> nil
    end)
  end
end

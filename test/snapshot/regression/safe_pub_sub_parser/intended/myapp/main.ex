defmodule Main do
  alias Phoenix.SafePubSub, as: SafePubSub
  def main() do
    msg = %{:type => "ok"}
    _r1 = Phoenix.SafePubSub.parse_with_converter(msg, "todo_pub_sub.parse_msg")
    atom_ident = :"todo_pub_sub.parse_msg"
    _r2 = Phoenix.SafePubSub.parse_with_converter(msg, atom_ident)
    _ = Phoenix.SafePubSub.parse_with_converter(msg, &MyParser.parse/1)
  end
end

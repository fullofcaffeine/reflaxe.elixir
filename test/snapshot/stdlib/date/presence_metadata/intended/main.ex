defmodule Main do
  def main() do
    meta = %{online_at: DateTime.to_unix(DateTime.utc_now(), :millisecond), user_name: "alice", avatar: nil}
    _ = Log.trace(Reflaxe.Elixir.HaxeFloat.to_string(meta), nil)
  end
end

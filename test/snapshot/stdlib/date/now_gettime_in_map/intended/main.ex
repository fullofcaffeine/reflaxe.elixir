defmodule Main do
  def main() do
    meta = %{:online_at => DateTime.to_iso8601(DateTime.utc_now()), :user_name => "bob"}
    _ = Log.trace(inspect(meta), nil)
  end
end

defmodule Main do
  def main() do
    meta = %{:online_at => Date_Impl_.get_time(DateTime.utc_now()), :user_name => "bob"}
    Log.trace(Std.string(meta), nil)
  end
end
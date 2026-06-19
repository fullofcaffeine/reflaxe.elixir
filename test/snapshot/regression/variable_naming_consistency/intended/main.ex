defmodule Main do
  def main() do
    _changeset = get_changeset()
    user = get_user()
    if (Reflaxe.Elixir.HaxeFloat.eq(user, nil)), do: nil
    _result = compute()
    nil
  end
  defp get_changeset() do
    "changeset_data"
  end
  defp get_user() do
    "user_data"
  end
  defp compute() do
    "computed"
  end
end

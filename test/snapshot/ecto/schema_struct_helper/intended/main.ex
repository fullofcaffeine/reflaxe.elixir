defmodule Main do
  defp accept_user(_user) do

  end
  def main() do
    user = Kernel.struct(Example.User)
    _ = accept_user(user)
  end
end

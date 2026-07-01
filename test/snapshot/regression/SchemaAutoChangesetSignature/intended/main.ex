defmodule Main do
  def main() do
    params = %{name: "Ada", email: "ada@example.com"}
    _auto_changeset = MyApp.User.changeset(%MyApp.User{}, params)
    _explicit_changeset = MyApp.UserExplicit.changeset(%MyApp.UserExplicit{}, params)
    nil
  end
end

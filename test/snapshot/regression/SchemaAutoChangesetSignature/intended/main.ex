defmodule Main do
  def main() do
    params = %{:name => "Ada", :email => "ada@example.com"}
    _auto_changeset = User.changeset(%User{}, params)
    _explicit_changeset = UserExplicit.changeset(%UserExplicit{}, params)
    nil
  end
end

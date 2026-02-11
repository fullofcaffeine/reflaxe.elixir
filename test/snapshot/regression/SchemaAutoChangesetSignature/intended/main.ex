defmodule Main do
  def main() do
    params = %{:name => "Ada", :email => "ada@example.com"}
    _changeset = User.changeset(%User{}, params)
    nil
  end
end

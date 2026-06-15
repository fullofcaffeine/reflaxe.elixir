defmodule Main do
  def main() do
    fields = fields_for_changeset()
    email = email_field()
    last_login_at = last_login_at_field()
    IO.inspect(%{fields: fields, email: email, last_login_at: last_login_at})
  end
  defp fields_for_changeset() do
    [:name, :email, :age, :role, :last_login_at]
  end
  defp email_field() do
    :email
  end
  defp last_login_at_field() do
    :last_login_at
  end
end

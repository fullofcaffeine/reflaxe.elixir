defmodule UserManagementExampleTest do
  use ExUnit.Case, async: true

  test "generated Ecto user changeset accepts valid user attributes" do
    changeset =
      %User{}
      |> User.changeset(%{name: "Ada", email: "ada@example.com", age: 37, active: true})

    assert changeset.valid?
    assert Ecto.Changeset.get_change(changeset, :name) == "Ada"
    assert Ecto.Changeset.get_change(changeset, :email) == "ada@example.com"
  end

  test "generated Ecto changesets report required fields" do
    user_changeset = User.changeset(%User{}, %{})
    post_changeset = Post.changeset(%Post{}, %{})

    refute user_changeset.valid?
    refute post_changeset.valid?

    assert Keyword.has_key?(user_changeset.errors, :name)
    assert Keyword.has_key?(user_changeset.errors, :email)
    assert Keyword.has_key?(post_changeset.errors, :title)
    assert Keyword.has_key?(post_changeset.errors, :user_id)
  end

  test "compact Users context stubs return deterministic values" do
    assert Users.list_users(nil) == []
    assert Users.search_users("ada") == []
    assert Users.change_user(nil) == %{valid: true}
    assert Users.user_stats() == %{total: 0, active: 0, inactive: 0}

    assert Users.create_user(%{name: "Ada"}).status == "error"
  end
end

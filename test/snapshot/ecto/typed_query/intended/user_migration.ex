defmodule UserMigration do
  def up(struct) do
    struct.create_table("users").add_column("name", {:String}, %{:nullable => false}).add_column("email", {:String}, %{:nullable => false}).add_column("active", {7}, %{:default_value => true}).add_column("role", {:String}).add_column("age", {0}).add_timestamps().add_index(["email"], %{:unique => true}).add_index(["role", "active"])
    struct.create_table("posts").add_column("title", {:String}, %{:nullable => false}).add_column("content", {5}).add_column("user_id", {0}).add_column("published", {7}, %{:default_value => false}).add_timestamps().add_foreign_key("user_id", "users", %{:on_delete => {1}})
  end
  def down(struct) do
    struct.drop_table("posts")
    struct.drop_table("users")
  end
end
defmodule Main do
  def main() do
    _ = test_schema_constructor()
    _ = test_regular_class()
    _ = test_gen_server()
    _ = test_data_structures()
    _ = test_multiple_instances()
  end
  defp test_schema_constructor() do
    user = %ConstructorTest.User{}
    user = %{user | name: "Alice"}
    _ = %{user | email: "alice@example.com"}
    nil
  end
  defp test_regular_class() do
    _ = TodoFormatter.new("markdown", "TODO")
    _ = TodoFormatter.new("plain", nil)
    nil
  end
  defp test_gen_server() do
    _worker = TodoWorker.new(%{todos: []})
    nil
  end
  defp test_data_structures() do
    _ = DataStructureTest.test_collections()
    nil
  end
  defp test_multiple_instances() do
    users = []
    user = %ConstructorTest.User{}
    user = %{user | name: "User " <> Reflaxe.Elixir.HaxeFloat.to_string(0)}
    user = %{user | email: "user" <> Reflaxe.Elixir.HaxeFloat.to_string(0) <> "@example.com"}
    users = users ++ [user]
    user = %ConstructorTest.User{}
    user = %{user | name: "User " <> Reflaxe.Elixir.HaxeFloat.to_string(1)}
    user = %{user | email: "user" <> Reflaxe.Elixir.HaxeFloat.to_string(1) <> "@example.com"}
    users = users ++ [user]
    user = %ConstructorTest.User{}
    user = %{user | name: "User " <> Reflaxe.Elixir.HaxeFloat.to_string(2)}
    user = %{user | email: "user" <> Reflaxe.Elixir.HaxeFloat.to_string(2) <> "@example.com"}
    users = users ++ [user]
    user = %ConstructorTest.User{}
    user = %{user | name: "User " <> Reflaxe.Elixir.HaxeFloat.to_string(3)}
    user = %{user | email: "user" <> Reflaxe.Elixir.HaxeFloat.to_string(3) <> "@example.com"}
    users = users ++ [user]
    user = %ConstructorTest.User{}
    user = %{user | name: "User " <> Reflaxe.Elixir.HaxeFloat.to_string(4)}
    user = %{user | email: "user" <> Reflaxe.Elixir.HaxeFloat.to_string(4) <> "@example.com"}
    _ = users ++ [user]
    _ = TodoFormatter.new("markdown", "- [ ]")
    _ = TodoFormatter.new("org", "TODO")
    _ = TodoFormatter.new("plain", "*")
    nil
  end
end

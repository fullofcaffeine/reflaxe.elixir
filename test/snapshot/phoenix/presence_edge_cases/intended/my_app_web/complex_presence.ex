defmodule MyAppWeb.ComplexPresence do
  use Phoenix.Presence, otp_app: :my_app, pubsub_server: MyApp.PubSub
  def track_with_computation(socket, user) do
    MyApp.Presence.track(self(), socket, "#{(fn -> Reflaxe.Elixir.HaxeFloat.to_string(((case user do
  _dyn_obj ->
    (case Map.fetch(_dyn_obj, "id") do
      {:ok, _dyn_value} -> _dyn_value
      _ ->
        Map.get(_dyn_obj, :id)
    end)
end))) end).()}_#{Reflaxe.Elixir.HaxeFloat.to_string(DateTime.to_unix(DateTime.utc_now(), :millisecond))}", (fn ->
      v = Reflaxe.Elixir.HaxeFloat.divide(DateTime.to_unix(DateTime.utc_now(), :millisecond), 1000)
      %{name: Reflaxe.Elixir.HaxeFloat.to_string(((case user do
  dyn_obj ->
    (case Map.fetch(dyn_obj, "first_name") do
      {:ok, dyn_value} -> dyn_value
      _ ->
        Map.get(dyn_obj, :first_name)
    end)
end))) <> " " <> Reflaxe.Elixir.HaxeFloat.to_string(((case user do
  dyn_obj ->
    (case Map.fetch(dyn_obj, "last_name") do
      {:ok, dyn_value} -> dyn_value
      _ ->
        Map.get(dyn_obj, :last_name)
    end)
end))), timestamp: Reflaxe.Elixir.HaxeFloat.floor_int(v), computed: (if ((Reflaxe.Elixir.HaxeFloat.gt(((case user do
  dyn_obj ->
    (case Map.fetch(dyn_obj, "score") do
      {:ok, dyn_value} -> dyn_value
      _ ->
        Map.get(dyn_obj, :score)
    end)
end)), 100))), do: "expert", else: "novice")}
    end).())
  end
  def track_nested(socket, users) do
    Enum.map(users, fn user -> MyApp.Presence.track(self(), socket, user.id, %{status: "online"}) end)
  end
end

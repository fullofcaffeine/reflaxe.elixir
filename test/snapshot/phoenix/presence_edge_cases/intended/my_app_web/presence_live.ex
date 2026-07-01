defmodule MyAppWeb.PresenceLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {MyAppWeb.Layouts, :app}
  use Phoenix.Presence, otp_app: :my_app, pubsub_server: MyApp.PubSub
  def mount(_params, session, socket) do
    user_id = (case session do
      dyn_obj ->
        (case Map.fetch(dyn_obj, "user_id") do
          {:ok, dyn_value} -> dyn_value
          _ ->
            Map.get(dyn_obj, :user_id)
        end)
    end)
    socket = MyApp.Presence.track(self(), socket, user_id, %{joined_at: DateTime.to_iso8601(DateTime.utc_now())})
    %{ok: socket}
    {:ok, socket}
  end
  def handle_event(event, params, socket) do
    (case event do
      "user_stopped_typing" ->
        %{noreply: MyApp.Presence.update(self(), socket, ((case params do
  dyn_obj ->
    (case Map.fetch(dyn_obj, "user_id") do
      {:ok, dyn_value} -> dyn_value
      _ ->
        Map.get(dyn_obj, :user_id)
    end)
end)), %{typing: false})}
      "user_typing" ->
        %{noreply: MyApp.Presence.update(self(), socket, ((case params do
  dyn_obj ->
    (case Map.fetch(dyn_obj, "user_id") do
      {:ok, dyn_value} -> dyn_value
      _ ->
        Map.get(dyn_obj, :user_id)
    end)
end)), %{typing: true})}
      _ -> %{noreply: socket}
    end)
  end
end

defmodule UserLive do
  @compile {:nowarn_unused_function, [mount: 4, handle_event: 4]}

  use Phoenix.Component
  defp mount(struct, _params, _session, socket) do
    users = MyApp.Accounts.list_users()
    %{:ok => true, :socket => socket}
  end
  defp handle_event(struct, event, params, socket) do
    switch_result_1 = case event do
      "delete_user" ->
        MyApp.Accounts.delete_user(user)
        %{:noreply => true, :socket => socket}
      "save_user" ->
        result = MyApp.Accounts.create_user(params)
        %{:noreply => true, :socket => socket}
      _ ->
        %{:noreply => true, :socket => socket}
    end
    switch_result_1
  end
end

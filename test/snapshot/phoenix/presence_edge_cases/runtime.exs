[output] = System.argv()
{:ok, _, []} = Kernel.ParallelCompiler.compile(Path.wildcard(Path.join(output, "**/*.ex")), warnings_as_errors: true)
{:ok, _} = Application.ensure_all_started(:phoenix_pubsub)
{:ok, _} = Supervisor.start_link([{Phoenix.PubSub, name: MyApp.PubSub}, MyAppWeb.ConditionalPresence, MyAppWeb.ComplexPresence, MyAppWeb.MixedUsage], strategy: :one_for_one)
socket = %Phoenix.Socket{}
^socket = MyAppWeb.ConditionalPresence.track_conditionally(socket, "admin", true)
^socket = MyAppWeb.ConditionalPresence.track_conditionally(socket, "user", false)
%{"admin" => %{metas: [%{role: "admin"}]}, "user" => %{metas: [%{role: "user"}]}} = MyAppWeb.ConditionalPresence.list("conditional")
for {key, input, role} <- [{"one", "admin", "admin"}, {"two", "moderator", "mod"}, {"three", "other", "user"}] do
  ^socket = MyAppWeb.ConditionalPresence.track_in_switch(socket, key, input)
  %{metas: [%{role: ^role}]} = MyAppWeb.ConditionalPresence.get_by_key("switch", key)
end
user = %{id: "member", first_name: "Test", last_name: "User", score: 101}
^socket = MyAppWeb.ComplexPresence.track_with_computation(socket, user)
%{"member_key" => %{metas: [%{name: "Test User", computed: "expert"}]}} = MyAppWeb.ComplexPresence.list("computed")
[^socket, ^socket] = MyAppWeb.ComplexPresence.track_nested(socket, [user, %{user | id: "second"}])
%{"member" => %{metas: [%{status: "online"}]}, "second" => %{metas: [%{status: "online"}]}} = MyAppWeb.ComplexPresence.list("nested")
^socket = MyAppWeb.PresenceCaller.register(socket, "external")
%{metas: [%{role: "admin"}]} = MyAppWeb.ConditionalPresence.get_by_key("conditional", "external")
^socket = MyAppWeb.MixedUsage.local_and_remote(socket, "mixed")
%{metas: [%{local: true}]} = MyAppWeb.MixedUsage.get_by_key("local", "mixed")
%{metas: [%{role: "user"}]} = MyAppWeb.ConditionalPresence.get_by_key("conditional", "mixed")
IO.puts("declared Presence targets survive branches, expressions, callbacks and external calls")

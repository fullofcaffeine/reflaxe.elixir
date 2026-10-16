# Independent native observer: the full Phoenix profile must respect the
# endpoint setting even when Phoenix.CodeReloader is installed.
{output, reloading?} =
  case System.argv() do
    [output] -> {output, false}
    [output, "reload-enabled"] -> {output, true}
    _ -> raise("Expected generated output path and optional reload-enabled mode")
  end

for app <- [:phoenix, :jason], do: {:ok, _} = Application.ensure_all_started(app)

Application.put_env(:my_app, MyAppWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: String.duplicate("x", 64),
  pubsub_server: MyApp.PubSub,
  code_reloader: reloading?,
  server: false
)

{:ok, _, []} =
  Kernel.ParallelCompiler.compile(
    Path.wildcard(Path.join(output, "**/*.ex")),
    warnings_as_errors: true
  )

# The enabled branch proves strict compilation. Exercising development reload
# needs a Mix project; the disabled branch must serve requests without one.
if reloading? do
  IO.puts("full Phoenix endpoint: strict compile with reloading enabled")
else
  true = Code.ensure_loaded?(Phoenix.CodeReloader)
  nil = Process.whereis(Mix.ProjectStack)

  {:ok, owner} =
    Supervisor.start_link(
      [{Phoenix.PubSub, name: MyApp.PubSub}, MyAppWeb.Endpoint],
      strategy: :one_for_one
    )

  try do
    response = MyAppWeb.Endpoint.call(Plug.Test.conn(:get, "/api/status"), [])
    200 = response.status
    %{"status" => "ok"} = Jason.decode!(response.resp_body)
    nil = Process.whereis(Mix.ProjectStack)
    IO.puts("full Phoenix endpoint: disabled reloading serves JSON without Mix")
  after
    Supervisor.stop(owner)
  end
end

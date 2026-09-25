[output] = System.argv()
{:ok, _, []} = Kernel.ParallelCompiler.compile(Path.wildcard(Path.join(output, "**/*.ex")), warnings_as_errors: true)

# These modules are retained by annotations, without a Haxe call from Main.
# Exercise the actual helper emitted by the compiler, not a substitute module.
{:ok, %{}} = MyAppWeb.Telemetry.start_link([])
%{} = MyAppWeb.Telemetry.init([])
true = function_exported?(MyAppWeb.Telemetry, :child_spec, 1)
{:ok, supervisor} = MyApp.Application.start(:normal, [])
true = Process.alive?(supervisor)
:retained = MyApp.Application.prep_stop(:retained)
:ok = Supervisor.stop(supervisor)
IO.puts("annotation-retained callbacks call their declared helper and start a supervisor")

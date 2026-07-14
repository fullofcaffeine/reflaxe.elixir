# OTP Support Contract

OTP is the process and supervision toolkit built into Erlang and Elixir. Reflaxe.Elixir exposes many
typed Haxe names for OTP modules, but the presence of a name in `std/elixir` does not by itself mean
that every way of using it is covered by the 1.0 promise.

This page defines the small OTP subset that has direct runtime evidence. Anything not listed here is
experimental or outside the planned 1.0 support contract.

> [!IMPORTANT]
> Reflaxe.Elixir is still on the pre-1.0 release line. This is the OTP boundary proposed for the 1.0
> support inventory, not an announcement that 1.0 has been approved.

## Runtime-Proven Local Operations

The supported subset is deliberately local to one BEAM node. The Haxe calls compile to ordinary
Elixir functions; no Reflaxe-specific process runtime is added.

| Haxe operation | Generated Elixir | Behavior covered by the runtime test |
| --- | --- | --- |
| `Process.self()` | `Kernel.self()` | Returns the current live process ID. |
| `Process.spawn(fn)` | `Kernel.spawn(fn)` | Starts an unlinked local process from a Haxe closure. |
| `Process.alive(pid)` | `Process.alive?(pid)` | Reports the live/stopped state used by the lifecycle checks. |
| `Process.exit(pid, Atom.SHUTDOWN)` | `Process.exit(pid, :shutdown)` | Stops the unlinked local process created by the covered `spawn` form. |
| `Process.sleep(milliseconds)` | `Process.sleep(milliseconds)` | Pauses the current process for bounded test and task coordination. |
| `Task.async(fn)` + `Task.await(task)` | `Task.async(fn)` + `Task.await(task)` | Runs a local task and returns its successful result. |
| `Task.yieldWithTimeout(task, timeout)` | `Task.yield(task, timeout)` | Returns `null`/`nil` when a slow task has not finished by the timeout. |
| `Task.shutdown(task)` | `Task.shutdown(task)` | Stops the timed-out task before the test continues. |
| `Agent.start(fn)` | `Agent.start(fn)` | Starts an unlinked local agent and returns its reference in a typed `Result`. |
| `Agent.get` / `Agent.update` | `Agent.get` / `Agent.update` | Reads the initial state and applies a synchronous state change. |
| `Agent.sendCast` | `Agent.cast` | Applies an asynchronous update that is visible to a later call from the same sender. |
| `Agent.stop` | `Agent.stop` | Stops the agent process. |

“Covered” is intentionally narrower than “the matching Elixir module has more functions.” For
example, this contract covers closure-based local `Process.spawn`, not every spawn, link, monitor, or
message form declared by the extern.

## What The Code Looks Like

Here is the basic source-to-target mapping for a successful task:

```haxe
import elixir.Task;

final task = Task.async(() -> 21 * 2);
final answer:Int = Task.await(task);
```

```elixir
task = Task.async(fn -> 21 * 2 end)
answer = Task.await(task)
```

Agent state callbacks also remain ordinary Elixir functions:

```haxe
import elixir.Agent;
import elixir.types.AgentRef;

static function updateCounter(agent:AgentRef):Int {
  Agent.update(agent, (value:Int) -> value + 5);
  return Agent.get(agent, (value:Int) -> value);
}
```

```elixir
defp update_counter(agent) do
  Agent.update(agent, fn value -> value + 5 end)
  Agent.get(agent, fn value -> value end)
end
```

The Haxe surface adds type checking and editor completion. The code that runs is still Elixir's
`Process`, `Task`, and `Agent` implementation on the BEAM.

## Application And Child-Spec Wiring

The following application wiring is supported within the documented example shapes:

- `@:application` generates an ordinary OTP `Application` module;
- typed `TypeSafeChildSpec` helpers resolve Haxe module references at compile time and emit normal
  module, tuple, or child-spec map entries; and
- the todo and chat applications prove that the generated child list can boot inside Phoenix.

For example:

```haxe
import elixir.otp.Supervisor.ChildSpecFormat;
import elixir.otp.Supervisor.SupervisorExtern;
import elixir.otp.Supervisor.SupervisorOptions;
import elixir.otp.Supervisor.SupervisorStrategy;
import elixir.otp.TypeSafeChildSpec;
import my_app.infrastructure.Endpoint;
import my_app.infrastructure.PubSub;
import my_app.infrastructure.Repo;

var children:Array<ChildSpecFormat> = [
  TypeSafeChildSpec.moduleRef(Repo),
  TypeSafeChildSpec.pubSub(PubSub),
  TypeSafeChildSpec.endpoint(Endpoint)
];
final options:SupervisorOptions = {
  strategy: SupervisorStrategy.OneForOne,
  max_restarts: 3,
  max_seconds: 5
};
return SupervisorExtern.startLink(children, options);
```

becomes the normal target shape:

```elixir
children = [MyApp.Repo, {Phoenix.PubSub, [name: MyApp.PubSub]}, MyAppWeb.Endpoint]
options = [strategy: :one_for_one, max_restarts: 3, max_seconds: 5]
Supervisor.start_link(children, options)
```

This evidence covers typed composition and application boot. It does **not** extend the 1.0 promise
to arbitrary restart intensity, child crash propagation, dynamic children, shutdown ordering, or
custom supervisor callbacks. See [Type-Safe OTP Child Specs](TYPE_SAFE_CHILD_SPEC.md) for the exact
child-spec API.

## Outside The 1.0 OTP Promise

The following surfaces may compile or have shape-based snapshots, but they do not yet have enough
runtime evidence to be called stable:

- custom `@:genserver` callback generation and direct `elixir.GenServer` lifecycle APIs;
- `@:supervisor` callback generation and direct supervisor lifecycle, restart, or failure-policy APIs;
- `elixir.Registry`, registry-backed names, and registry failure behavior;
- `elixir.TaskSupervisor`, task streams, linked-task failure propagation, and task crash results;
- process linking, monitoring, `DOWN` messages, raw mailbox receive/order guarantees, registered
  names, and the process dictionary;
- abnormal exit reasons, trapped exits, exception propagation across process boundaries, and custom
  shutdown timing;
- distributed or multi-node OTP, remote spawn, node partitions, and global registration; and
- hot upgrades, `code_change`, release handling, and arbitrary callback combinations.

These are exclusions, not claims that the underlying Elixir features are broken. They mean the
compiler project is not promising those Haxe source shapes for 1.0 until focused runtime tests exist.

## Known Source-Shape Limitation

A callback lambda written directly inside a `Result` switch branch can currently bind the wrong
parameter. That compiler bug is tracked as `haxe.elixir.codex-3qh.26`; this source shape is not part
of the stable subset until the bug is fixed. The runtime contract exercises the Agent callbacks in a
separate typed function so the generated callback binders are checked directly.

## Executable Evidence

The canonical Haxe fixture is
[`test/snapshot/otp/otp_core_runtime_contract/Main.hx`](../../test/snapshot/otp/otp_core_runtime_contract/Main.hx).
It is checked in three ways:

```bash
# Compile Haxe, reject Elixir warnings, and run the lifecycle assertions.
npm run test:otp-runtime

# Check the reviewed generated Elixir snapshot.
npm run test:otp

# Run the broader runtime smoke suite, which includes the OTP contract.
npm run test:runtime-smoke
```

CI runs the focused contract on the minimum Elixir 1.14 / OTP 25 toolchain and includes it in the
primary runtime lane. Example QA and the todo-app sentinel separately cover the documented
application/child-spec boot path.

## Related References

- [Elixir Runtime API Reference](ELIXIR_RUNTIME_API_REFERENCE.md)
- [Type-Safe OTP Child Specs](TYPE_SAFE_CHILD_SPEC.md)
- [Feature Support Matrix](FEATURES.md)
- [Known Limitations](../06-guides/KNOWN_LIMITATIONS.md)
- [Support Matrix](../06-guides/SUPPORT_MATRIX.md)

fixture_root = System.fetch_env!("HAXE_SERVER_OWNER_FIXTURE_ROOT")
fake_haxe = System.fetch_env!("HAXE_SERVER_OWNER_FIXTURE_HAXE")
pid_file = System.fetch_env!("HAXE_SERVER_OWNER_FIXTURE_PID_FILE")

File.cd!(fixture_root)
{:ok, socket} = :gen_tcp.listen(0, [:binary, active: false])
{:ok, {_address, port}} = :inet.sockname(socket)
:ok = :gen_tcp.close(socket)

{:ok, _server} = HaxeServer.start_link(haxe_cmd: fake_haxe, port: port)

deadline = System.monotonic_time(:millisecond) + 5_000

wait_for_pid_file = fn wait_for_pid_file ->
  cond do
    File.exists?(pid_file) ->
      :ok

    System.monotonic_time(:millisecond) >= deadline ->
      raise "fake Haxe server did not publish its PID"

    true ->
      Process.sleep(25)
      wait_for_pid_file.(wait_for_pid_file)
  end
end

wait_for_pid_file.(wait_for_pid_file)

child_pid =
  pid_file
  |> File.read!()
  |> String.trim()

Process.sleep(250)

case System.cmd("kill", ["-0", child_pid], stderr_to_stdout: true) do
  {_output, 0} ->
    IO.puts("HAXE_SERVER_OWNER_CHILD_LIVE")

  {output, status} ->
    raise "fake Haxe server exited while its Mix VM was alive (#{status}): #{output}"
end

# Deliberately do not call HaxeServer.stop/0. The operating-system owner must
# reap the native child when this otherwise normal short-lived VM exits.

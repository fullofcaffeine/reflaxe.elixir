# Exercise the real ExUnit cleanup lifecycle in a disposable VM. The two test
# failures below are deliberate; success requires all three cleanup receipts.
Code.require_file("../../test/support/haxe_test_helper.ex", __DIR__)
ExUnit.start(autorun: false, formatters: [], seed: 0)
Process.register(self(), :cwd_recovery_observer)
original_directory = File.cwd!()

defmodule CwdRecoveryProbe do
  use ExUnit.Case, async: false

  @root Path.join(
          System.tmp_dir!(),
          "reflaxe-cwd-recovery-#{System.pid()}-#{System.unique_integer([:positive])}"
        )
  def root, do: @root

  defp change_directory(label) do
    original = File.cwd!()

    directory = Path.join(@root, Atom.to_string(label))

    File.mkdir!(directory)

    HaxeTestHelper.on_exit_in_original_directory(fn ->
      assert File.cwd!() == original
      File.rm_rf!(directory)
      send(:cwd_recovery_observer, {:restored, label})
    end)

    File.cd!(directory)
  end

  test "ordinary completion" do
    change_directory(:normal)
  end

  test "assertion failure" do
    change_directory(:failure)
    flunk("intentional failure for cleanup verification")
  end

  test "untrappable process death like an ExUnit timeout" do
    change_directory(:killed)
    Process.exit(self(), :kill)
  end
end

File.mkdir!(CwdRecoveryProbe.root())

try do
  result = ExUnit.run()

  unless result.total == 3 and result.failures == 2,
    do: raise("unexpected probe results: #{inspect(result)}")

  for label <- [:normal, :failure, :killed] do
    receive do
      {:restored, ^label} -> :ok
    after
      2_000 -> raise "missing cleanup receipt: #{label}"
    end
  end

  unless File.cwd!() == original_directory, do: raise("VM working directory was not restored")
after
  # The test harness must clean its own sandbox even when the helper regresses.
  File.cd!(original_directory)
  File.rm_rf!(CwdRecoveryProbe.root())
end

IO.puts(
  "cwd recovery: normal completion, assertion failure and process kill all restored before cleanup"
)

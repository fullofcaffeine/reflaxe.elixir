defmodule MixCompileHaxeErrorOutputTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Compile.Haxe, as: HaxeTask

  setup do
    previous_haxelib_path = System.get_env("HAXELIB_PATH")

    # Stop any running Haxe server to avoid port conflicts and cross-test coupling
    if Process.whereis(HaxeServer) do
      try do
        HaxeServer.stop()
        Process.sleep(100)
      catch
        _, _ -> :ok
      end
    end

    test_dir =
      Path.join([System.tmp_dir!(), "mix_compile_haxe_error_output_#{:rand.uniform(10000)}"])

    File.mkdir_p!(test_dir)
    File.mkdir_p!(Path.join(test_dir, "src_haxe"))
    File.mkdir_p!(Path.join(test_dir, "lib"))

    HaxeTestHelper.setup_haxe_libraries(test_dir)
    HaxeTestHelper.create_build_hxml(test_dir, main_class: "ErrorTest")
    HaxeTestHelper.create_error_haxe_file(test_dir, filename: "ErrorTest.hx", error_type: :undefined)

    on_exit(fn ->
      if Process.whereis(HaxeServer) do
        try do
          HaxeServer.stop()
        catch
          _, _ -> :ok
        end
      end

      case previous_haxelib_path do
        nil -> System.delete_env("HAXELIB_PATH")
        value -> System.put_env("HAXELIB_PATH", value)
      end

      File.rm_rf(test_dir)
    end)

    {:ok, test_dir: test_dir}
  end

  test "prints Haxe compiler output when compilation fails", %{test_dir: test_dir} do
    case HaxeTestHelper.ensure_haxe_available() do
      {:ok, _} -> :ok
      {:error, reason} -> flunk("Haxe not available in test environment: #{reason}")
    end

    output =
      capture_io(fn ->
        old_cwd = File.cwd!()

        try do
          File.cd!(test_dir)
          _ = HaxeTask.run(["--force", "--verbose", "--no-watch"])
        after
          File.cd!(old_cwd)
        end
      end)

    # Contract: surface the underlying Haxe compiler output so humans/LLMs can diagnose.
    assert output =~ "unknownFunction",
           "expected raw Haxe output to include the actual error; got:\n#{output}"
  end
end

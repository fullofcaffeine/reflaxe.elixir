defmodule HaxeWatcherErrorOutputTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  setup do
    # Ensure a clean singleton state (HaxeWatcher is registered by name)
    if Process.whereis(HaxeWatcher) do
      try do
        HaxeWatcher.stop()
        Process.sleep(100)
      catch
        _, _ -> :ok
      end
    end

    if Process.whereis(HaxeServer) do
      try do
        HaxeServer.stop()
        Process.sleep(100)
      catch
        _, _ -> :ok
      end
    end

    test_dir = Path.join([System.tmp_dir!(), "haxe_watcher_error_output_#{:rand.uniform(10000)}"])
    source_dir = Path.join(test_dir, "src_haxe")
    target_dir = Path.join(test_dir, "lib")

    File.mkdir_p!(source_dir)
    File.mkdir_p!(target_dir)

    HaxeTestHelper.setup_haxe_libraries(test_dir)
    HaxeTestHelper.create_build_hxml(test_dir, main_class: "ErrorTest")
    HaxeTestHelper.create_error_haxe_file(test_dir, filename: "ErrorTest.hx", error_type: :undefined)

    on_exit(fn ->
      if Process.whereis(HaxeWatcher) do
        try do
          HaxeWatcher.stop()
        catch
          _, _ -> :ok
        end
      end

      if Process.whereis(HaxeServer) do
        try do
          HaxeServer.stop()
        catch
          _, _ -> :ok
        end
      end

      File.rm_rf(test_dir)
    end)

    {:ok, test_dir: test_dir, source_dir: source_dir}
  end

  test "prints raw Haxe compiler output on compile failure", %{test_dir: test_dir, source_dir: source_dir} do
    case HaxeTestHelper.ensure_haxe_available() do
      {:ok, _} -> :ok
      {:error, reason} -> flunk("Haxe not available in test environment: #{reason}")
    end

    captured =
      capture_io(fn ->
        old_cwd = File.cwd!()

        try do
          File.cd!(test_dir)

          {:ok, _pid} =
            HaxeWatcher.start_link(
              dirs: [source_dir],
              debounce_ms: 0,
              auto_compile: false,
              build_file: "build.hxml"
            )

          HaxeWatcher.trigger_compilation()

          wait_until(fn ->
            status = HaxeWatcher.status()
            status[:compilation_count] >= 1
          end)
        after
          File.cd!(old_cwd)
        end
      end)

    assert captured =~ "Unknown identifier" and captured =~ "unknownFunction",
           "expected HaxeWatcher to surface compiler output; got:\n#{captured}"
  end

  defp wait_until(predicate, attempts_left \\ 100)

  defp wait_until(_predicate, 0) do
    flunk("timed out waiting for condition")
  end

  defp wait_until(predicate, attempts_left) do
    if predicate.() do
      :ok
    else
      Process.sleep(50)
      wait_until(predicate, attempts_left - 1)
    end
  end
end

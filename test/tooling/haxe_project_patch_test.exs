defmodule HaxeProjectPatchTest do
  use ExUnit.Case, async: true

  @transaction_directory ".reflaxe-elixir-project-patch"

  test "marker helpers require one ordered, non-overlapping marker pair" do
    content = """
    before
      # BEGIN managed
      old
      # END managed
    after
    """

    assert {:ok, updated} =
             HaxeProjectPatch.replace_marker_block_lines(
               content,
               "BEGIN managed",
               "END managed",
               ["new"]
             )

    assert updated == """
           before
             # BEGIN managed
             new
             # END managed
           after
           """

    assert {:ok, removed} =
             HaxeProjectPatch.remove_marker_block_lines(
               updated,
               "BEGIN managed",
               "END managed"
             )

    assert removed == "before\nafter\n"

    assert :missing =
             HaxeProjectPatch.remove_marker_block_lines(
               "plain\n",
               "BEGIN managed",
               "END managed"
             )

    assert {:error, {:marker_count, _, 2, _, 1}} =
             HaxeProjectPatch.replace_marker_block_lines(
               "# BEGIN managed\n# BEGIN managed\n# END managed\n",
               "BEGIN managed",
               "END managed",
               []
             )

    assert {:error, {:inverted_marker_pair, _, _, _, _}} =
             HaxeProjectPatch.remove_marker_block_lines(
               "# END managed\n# BEGIN managed\n",
               "BEGIN managed",
               "END managed"
             )

    nested = "# BEGIN outer\n# BEGIN inner\n# END inner\n# END outer\n"

    assert {:error, {:overlapping_marker_pairs, _, _, _, _}} =
             HaxeProjectPatch.validate_marker_pairs(nested, [
               {"BEGIN outer", "END outer"},
               {"BEGIN inner", "END inner"}
             ])

    prefixed = "# BEGIN hook_property\nvalue\n# END hook_property\n"

    assert :missing ==
             HaxeProjectPatch.replace_marker_block_lines(
               prefixed,
               "BEGIN hook",
               "END hook",
               ["other"]
             )
  end

  test "signature ownership is exact and duplicate signatures fail closed" do
    signature = "generated:widget:v1"

    assert :unowned == HaxeProjectPatch.signature_status("custom\n", signature)
    assert :owned == HaxeProjectPatch.signature_status("# #{signature}\n", signature)

    assert {:error, {:duplicate_signature, ^signature, 2}} =
             HaxeProjectPatch.signature_status(
               "# #{signature}\n# #{signature}\n",
               signature
             )

    assert {:ok, "replacement\n"} ==
             HaxeProjectPatch.managed_file_content(
               "# #{signature}\nold\n",
               signature,
               "replacement\n"
             )

    assert :unowned ==
             HaxeProjectPatch.managed_file_content("custom\n", signature, "replacement\n")
  end

  test "package-key checks distinguish missing, equal, and conflicting values" do
    package_json = """
    {
      "name": "demo",
      "dependencies": {
        "live_react": "file:../deps/live_react"
      }
    }
    """

    assert {:ok, :equal} ==
             HaxeProjectPatch.package_key_status(
               package_json,
               ["dependencies", "live_react"],
               "file:../deps/live_react"
             )

    assert {:ok, {:conflict, "file:../other"}} ==
             HaxeProjectPatch.package_key_status(
               String.replace(package_json, "../deps/live_react", "../other"),
               ["dependencies", "live_react"],
               "file:../deps/live_react"
             )

    assert {:ok, :missing} ==
             HaxeProjectPatch.package_key_status(
               package_json,
               ["scripts", "assets:build"],
               "vite build"
             )

    assert {:error, message} =
             HaxeProjectPatch.package_key_status(
               ~s({"dependencies":[]}),
               ["dependencies", "live_react"],
               "file:../deps/live_react"
             )

    assert message =~ "dependencies must contain an object"
  end

  test "package-key change validation rejects unrelated semantic changes" do
    before = ~s({"name":"demo","private":true}\n)

    after_content =
      ~s({"name":"demo","private":true,"dependencies":{"live_react":"file:../deps/live_react"}}\n)

    assert :ok ==
             HaxeProjectPatch.validate_package_key_change(
               before,
               after_content,
               ["dependencies", "live_react"],
               "file:../deps/live_react"
             )

    changed_unrelated =
      ~s({"name":"changed","private":true,"dependencies":{"live_react":"file:../deps/live_react"}}\n)

    assert {:error, message} =
             HaxeProjectPatch.validate_package_key_change(
               before,
               changed_unrelated,
               ["dependencies", "live_react"],
               "file:../deps/live_react"
             )

    assert message =~ "changed keys outside"
  end

  test "building a plan never mutates an earlier validated file" do
    root = tmp_root("planning")
    first = Path.join(root, "first.txt")
    File.write!(first, "before\n")

    plan = HaxeProjectPatch.new!(root)
    plan = HaxeProjectPatch.patch_file!(plan, first, fn _ -> "after\n" end)

    assert_raise RuntimeError, ~r/expected file/, fn ->
      HaxeProjectPatch.patch_file!(plan, Path.join(root, "missing.txt"), & &1)
    end

    assert File.read!(first) == "before\n"
    refute File.exists?(Path.join(root, @transaction_directory))
    assert HaxeProjectPatch.recovery_status!(root) == :clean
  end

  test "the recovery directory is reserved and cannot be a patch target" do
    root = tmp_root("reserved")
    plan = HaxeProjectPatch.new!(root)

    assert_raise RuntimeError, ~r/reserved transaction path/, fn ->
      HaxeProjectPatch.write_file!(
        plan,
        Path.join([root, @transaction_directory, "user.txt"]),
        "content\n"
      )
    end

    refute File.exists?(Path.join(root, @transaction_directory))
  end

  test "publication revalidates every input before its first write" do
    root = tmp_root("preflight")
    first = Path.join(root, "first.txt")
    second = Path.join(root, "second.txt")
    File.write!(first, "first-before\n")
    File.write!(second, "second-before\n")

    plan =
      HaxeProjectPatch.new!(root)
      |> HaxeProjectPatch.patch_file!(first, fn _ -> "first-after\n" end)
      |> HaxeProjectPatch.patch_file!(second, fn _ -> "second-after\n" end)

    File.write!(second, "external-change\n")

    assert_raise RuntimeError, ~r/input changed after discovery/, fn ->
      HaxeProjectPatch.publish!(plan)
    end

    assert File.read!(first) == "first-before\n"
    assert File.read!(second) == "external-change\n"
    refute File.exists?(Path.join(root, @transaction_directory))
  end

  test "a reported publication failure restores writes, creates, deletes, and directories" do
    root = tmp_root("rollback")
    existing = Path.join(root, "existing.txt")
    removed = Path.join(root, "removed.txt")
    created = Path.join([root, "nested", "created.txt"])
    File.write!(existing, "existing-before\n")
    File.write!(removed, "removed-before\n")

    plan =
      HaxeProjectPatch.new!(root)
      |> HaxeProjectPatch.patch_file!(existing, fn _ -> "existing-after\n" end)
      |> HaxeProjectPatch.write_file!(created, "created\n")
      |> HaxeProjectPatch.delete_file!(removed)

    fault = fn
      {:after_publish, 1}, _operation -> {:error, "stop after the second replacement"}
      _stage, _operation -> :ok
    end

    assert_raise RuntimeError, ~r/failed and was rolled back/, fn ->
      HaxeProjectPatch.publish!(plan, fault_injector: fault)
    end

    assert File.read!(existing) == "existing-before\n"
    assert File.read!(removed) == "removed-before\n"
    refute File.exists?(created)
    refute File.exists?(Path.join(root, "nested"))
    refute File.exists?(Path.join(root, @transaction_directory))
  end

  test "manifest operations publish after ordinary files" do
    root = tmp_root("manifest_last")
    ordinary = Path.join(root, "ordinary.txt")
    manifest = Path.join(root, "manifest.json")
    parent = self()

    plan =
      HaxeProjectPatch.new!(root)
      |> HaxeProjectPatch.write_file!(manifest, "manifest\n", manifest: true)
      |> HaxeProjectPatch.write_file!(ordinary, "ordinary\n")

    fault = fn
      {:before_publish, _index}, operation ->
        send(parent, {:publishing, operation.relative})
        :ok

      _stage, _operation ->
        :ok
    end

    assert :ok == HaxeProjectPatch.publish!(plan, fault_injector: fault)
    assert_receive {:publishing, "ordinary.txt"}
    assert_receive {:publishing, "manifest.json"}
  end

  test "a rerun recovers a process killed between per-file replacements" do
    root = tmp_root("interrupted")
    first = Path.join(root, "first.txt")
    second = Path.join(root, "second.txt")
    File.write!(first, "first-before\n")
    File.write!(second, "second-before\n")

    plan =
      HaxeProjectPatch.new!(root)
      |> HaxeProjectPatch.patch_file!(first, fn _ -> "first-after\n" end)
      |> HaxeProjectPatch.patch_file!(second, fn _ -> "second-after\n" end)

    parent = self()

    {_pid, monitor} =
      spawn_monitor(fn ->
        HaxeProjectPatch.publish!(plan,
          fault_injector: fn
            {:after_publish, 0}, _operation ->
              send(parent, :first_published)
              Process.exit(self(), :kill)

            _stage, _operation ->
              :ok
          end
        )
      end)

    assert_receive :first_published
    assert_receive {:DOWN, ^monitor, :process, _pid, :killed}
    assert File.read!(first) == "first-after\n"
    assert File.read!(second) == "second-before\n"
    assert File.dir?(Path.join(root, @transaction_directory))
    assert HaxeProjectPatch.recovery_status!(root) == {:pending, :rollback}

    assert File.read!(first) == "first-after\n"
    assert File.read!(second) == "second-before\n"

    assert :ok == HaxeProjectPatch.recover!(root)
    assert File.read!(first) == "first-before\n"
    assert File.read!(second) == "second-before\n"
    refute File.exists?(Path.join(root, @transaction_directory))
  end

  test "recovery treats an interrupted fully-published plan as committed" do
    root = tmp_root("committed")
    first = Path.join(root, "first.txt")
    manifest = Path.join(root, "manifest.json")
    File.write!(first, "before\n")
    File.write!(manifest, "old-manifest\n")

    plan =
      HaxeProjectPatch.new!(root)
      |> HaxeProjectPatch.patch_file!(first, fn _ -> "after\n" end)
      |> HaxeProjectPatch.patch_file!(manifest, fn _ -> "new-manifest\n" end, manifest: true)

    parent = self()

    {_pid, monitor} =
      spawn_monitor(fn ->
        HaxeProjectPatch.publish!(plan,
          fault_injector: fn
            {:after_publish, 1}, _operation ->
              send(parent, :manifest_published)
              Process.exit(self(), :kill)

            _stage, _operation ->
              :ok
          end
        )
      end)

    assert_receive :manifest_published
    assert_receive {:DOWN, ^monitor, :process, _pid, :killed}
    assert File.dir?(Path.join(root, @transaction_directory))
    assert HaxeProjectPatch.recovery_status!(root) == {:pending, :commit_cleanup}

    assert File.read!(first) == "after\n"
    assert File.read!(manifest) == "new-manifest\n"

    assert :ok == HaxeProjectPatch.recover!(root)
    assert File.read!(first) == "after\n"
    assert File.read!(manifest) == "new-manifest\n"
    refute File.exists?(Path.join(root, @transaction_directory))
  end

  test "recovery rejects a journal whose temporary path targets another project file" do
    root = tmp_root("corrupt_journal")
    first = Path.join(root, "first.txt")
    second = Path.join(root, "second.txt")
    victim = Path.join(root, "victim.txt")
    File.write!(first, "first-before\n")
    File.write!(second, "second-before\n")
    File.write!(victim, "leave-me-alone\n")

    plan =
      HaxeProjectPatch.new!(root)
      |> HaxeProjectPatch.patch_file!(first, fn _ -> "first-after\n" end)
      |> HaxeProjectPatch.patch_file!(second, fn _ -> "second-after\n" end)

    parent = self()

    {_pid, monitor} =
      spawn_monitor(fn ->
        HaxeProjectPatch.publish!(plan,
          fault_injector: fn
            {:after_publish, 0}, _operation ->
              send(parent, :first_published)
              Process.exit(self(), :kill)

            _stage, _operation ->
              :ok
          end
        )
      end)

    assert_receive :first_published
    assert_receive {:DOWN, ^monitor, :process, _pid, :killed}

    journal_path = Path.join([root, @transaction_directory, "journal.json"])
    journal = Jason.decode!(File.read!(journal_path))

    corrupted =
      Map.update!(journal, "operations", fn [first_operation | remaining] ->
        [Map.put(first_operation, "newPath", "victim.txt") | remaining]
      end)

    File.write!(journal_path, Jason.encode!(corrupted))

    assert_raise RuntimeError, ~r/invalid project patch temporary path/, fn ->
      HaxeProjectPatch.recovery_status!(root)
    end

    assert_raise RuntimeError, ~r/invalid project patch temporary path/, fn ->
      HaxeProjectPatch.recover!(root)
    end

    assert File.read!(first) == "first-after\n"
    assert File.read!(second) == "second-before\n"
    assert File.read!(victim) == "leave-me-alone\n"
    assert File.dir?(Path.join(root, @transaction_directory))
  end

  defp tmp_root(label) do
    root =
      Path.join(
        System.tmp_dir!(),
        "reflaxe_elixir_project_patch_#{label}_#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(root)
    on_exit(fn -> File.rm_rf!(root) end)
    root
  end
end

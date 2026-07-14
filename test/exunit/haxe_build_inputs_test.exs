defmodule HaxeBuildInputsTest do
  use ExUnit.Case, async: false

  @fixed_time {{2020, 1, 1}, {0, 0, 0}}
  @environment_variables ~w(
    HAXE_FAST_BOOT
    HAXE_NO_SERVER
    HAXE_PATH
    HAXE_SERVER_AUTOSTART
    HAXELIB_PATH
    HAXESHIM_SERVER_PORT
    HAXE_TEST_MUTATE_SOURCE
    HAXE_TEST_LOG
    HAXELIB_CMD
  )

  setup do
    previous_environment = Map.new(@environment_variables, &{&1, System.get_env(&1)})

    test_dir =
      Path.join(
        System.tmp_dir!(),
        "haxe_build_inputs_#{System.unique_integer([:positive, :monotonic])}"
      )

    on_exit(fn ->
      Enum.each(previous_environment, fn
        {name, nil} -> System.delete_env(name)
        {name, value} -> System.put_env(name, value)
      end)

      File.rm_rf(test_dir)
    end)

    File.mkdir_p!(test_dir)
    {:ok, test_dir: test_dir}
  end

  test "every effective build input triggers one rebuild and unchanged inputs remain fresh", %{
    test_dir: test_dir
  } do
    fixture = create_fixture(test_dir)
    opts = fixture.opts

    assert Enum.sort(HaxeCompiler.source_files(opts)) ==
             Enum.sort([fixture.main_source, fixture.shared_source])

    assert fixture.shared_dir in HaxeBuildInputs.watch_dirs(opts)
    assert Path.dirname(fixture.nested_hxml) in HaxeBuildInputs.watch_dirs(opts)
    assert fixture.macro_inputs_dir in HaxeBuildInputs.watch_dirs(opts)
    assert fixture.resource_dir in HaxeBuildInputs.watch_dirs(opts)

    assert_single_rebuild(opts, fixture.compile_log, 1)

    original_mtime = File.stat!(fixture.main_source, time: :posix).mtime
    File.write!(fixture.main_source, "class Main { static final value = 2; }\n")
    File.touch!(fixture.main_source, @fixed_time)
    assert File.stat!(fixture.main_source, time: :posix).mtime == original_mtime
    assert_single_rebuild(opts, fixture.compile_log, 2)

    File.touch!(fixture.main_source, {{2021, 1, 1}, {0, 0, 0}})
    refute HaxeCompiler.needs_recompilation?(opts)
    assert compile_count(fixture.compile_log) == 2

    rewrite_with_fixed_mtime(
      fixture.shared_source,
      "class SharedValue { static final value = 2; }\n"
    )

    assert_single_rebuild(opts, fixture.compile_log, 3)

    rewrite_with_fixed_mtime(
      fixture.nested_hxml,
      nested_hxml("feature_flag=changed")
    )

    assert_single_rebuild(opts, fixture.compile_log, 4)

    rewrite_with_fixed_mtime(fixture.resource_file, "template version 2\n")
    assert_single_rebuild(opts, fixture.compile_log, 5)

    rewrite_with_fixed_mtime(
      fixture.library_source,
      "class LibraryValue { public static final value = 2; }\n"
    )

    assert_single_rebuild(opts, fixture.compile_log, 6)

    rewrite_with_fixed_mtime(
      fixture.library_descriptor,
      fixture.library_descriptor |> File.read!() |> String.replace("sample=1.0.0", "sample=2.0.0")
    )

    assert_single_rebuild(opts, fixture.compile_log, 7)

    rewrite_with_fixed_mtime(fixture.haxelib_json, ~s({"name":"sample","version":"2.0.0"}\n))
    assert_single_rebuild(opts, fixture.compile_log, 8)

    rewrite_with_fixed_mtime(
      fixture.extra_params,
      "-D sample_generated_configuration=changed\n"
    )

    assert_single_rebuild(opts, fixture.compile_log, 9)

    rewrite_with_fixed_mtime(fixture.macro_input, ~s({"version":2}\n))
    assert_single_rebuild(opts, fixture.compile_log, 10)

    write_fake_haxe(fixture.fake_haxe, "compiler-build-b")
    File.touch!(fixture.fake_haxe, @fixed_time)
    assert_single_rebuild(opts, fixture.compile_log, 11)

    System.put_env("HAXE_FAST_BOOT", "1")
    assert_single_rebuild(opts, fixture.compile_log, 12)

    File.rm!(fixture.shared_source)
    assert_single_rebuild(opts, fixture.compile_log, 13)
    refute fixture.shared_source in HaxeCompiler.source_files(opts)

    File.rmdir!(fixture.shared_dir)
    assert_single_rebuild(opts, fixture.compile_log, 14)
  end

  test "legacy manifests fail closed", %{test_dir: test_dir} do
    fixture = create_fixture(test_dir)

    File.mkdir_p!(Path.dirname(fixture.manifest))

    File.write!(
      fixture.manifest,
      :erlang.term_to_binary(%{
        version: 1,
        timestamp: System.system_time(:second),
        config_hash: HaxeCompiler.config_hash(fixture.opts),
        files: [fixture.generated_file]
      })
    )

    assert HaxeCompiler.needs_recompilation?(fixture.opts)
  end

  test "an input changed during compilation cannot be recorded as fresh", %{test_dir: test_dir} do
    fixture = create_fixture(test_dir)
    System.put_env("HAXE_TEST_MUTATE_SOURCE", fixture.main_source)

    assert {:ok, _compiled_files} = HaxeCompiler.compile(fixture.opts)
    assert HaxeCompiler.needs_recompilation?(fixture.opts)

    System.delete_env("HAXE_TEST_MUTATE_SOURCE")
    assert_single_rebuild(fixture.opts, fixture.compile_log, 2)
  end

  test "todo app Mix inputs include its shared server and browser contracts" do
    repository_root = Path.expand("../..", __DIR__)
    todo_root = Path.join(repository_root, "examples/todo-app")

    opts = [
      hxml_file: Path.join(todo_root, "build-server.hxml"),
      source_dir: Path.join(todo_root, "src_haxe"),
      target_dir: Path.join(todo_root, "lib")
    ]

    shared_root = Path.join(todo_root, "src_shared")
    source_files = HaxeCompiler.source_files(opts)

    assert shared_root in HaxeBuildInputs.watch_dirs(opts)
    assert Enum.any?(source_files, &String.starts_with?(&1, shared_root <> "/"))
  end

  defp create_fixture(test_dir) do
    source_dir = Path.join(test_dir, "src_haxe")
    shared_dir = Path.join(test_dir, "src_shared")
    target_dir = Path.join(test_dir, "lib")
    nested_dir = Path.join(test_dir, "config")
    libraries_dir = Path.join(test_dir, "haxe_libraries")
    library_root = Path.join(test_dir, "sample_lib")
    library_source_dir = Path.join(library_root, "src")
    macro_inputs_dir = Path.join(test_dir, "macro_inputs")
    resource_dir = Path.join(test_dir, "resources")

    Enum.each(
      [
        source_dir,
        shared_dir,
        target_dir,
        nested_dir,
        libraries_dir,
        library_source_dir,
        macro_inputs_dir,
        resource_dir
      ],
      &File.mkdir_p!/1
    )

    main_source = Path.join(source_dir, "Main.hx")
    shared_source = Path.join(shared_dir, "SharedValue.hx")
    library_source = Path.join(library_source_dir, "LibraryValue.hx")
    top_hxml = Path.join(test_dir, "build.hxml")
    nested_hxml = Path.join(nested_dir, "server.hxml")
    library_descriptor = Path.join(libraries_dir, "sample.hxml")
    extra_params = Path.join(library_root, "extraParams.hxml")
    haxelib_json = Path.join(library_root, "haxelib.json")
    macro_input = Path.join(macro_inputs_dir, "schema.json")
    resource_file = Path.join(resource_dir, "template.txt")
    fake_haxe = Path.join(test_dir, "fake_haxe")
    fake_haxelib = Path.join(test_dir, "haxelib")
    compile_log = Path.join(test_dir, "compile.log")
    generated_file = Path.join(target_dir, "generated.ex")
    manifest = Path.join([test_dir, "_build", ".mix", "compile.haxe"])

    File.write!(main_source, "class Main { static final value = 1; }\n")
    File.write!(shared_source, "class SharedValue { static final value = 1; }\n")
    File.write!(library_source, "class LibraryValue { public static final value = 1; }\n")
    File.write!(top_hxml, "-C config\n--next server.hxml\n")
    File.write!(nested_hxml, nested_hxml("feature_flag=initial"))
    File.write!(library_descriptor, "-cp #{library_source_dir}\n-D sample=1.0.0\n")

    File.write!(
      haxelib_json,
      ~s({"name":"sample","version":"1.0.0"}\n)
    )

    File.write!(extra_params, "-D sample_generated_configuration=initial\n")
    File.write!(macro_input, ~s({"version":1}\n))
    File.write!(resource_file, "template version 1\n")
    File.write!(generated_file, "defmodule Generated do\nend\n")
    File.write!(compile_log, "")
    write_fake_haxe(fake_haxe, "compiler-build-a")
    write_fake_haxelib(fake_haxelib)

    Enum.each(
      [
        main_source,
        shared_source,
        library_source,
        top_hxml,
        nested_hxml,
        library_descriptor,
        extra_params,
        haxelib_json,
        macro_input,
        resource_file,
        fake_haxe,
        fake_haxelib
      ],
      &File.touch!(&1, @fixed_time)
    )

    System.put_env("HAXE_PATH", fake_haxe)
    System.put_env("HAXE_NO_SERVER", "1")
    System.put_env("HAXE_SERVER_AUTOSTART", "never")
    System.put_env("HAXELIB_PATH", libraries_dir)
    System.put_env("HAXELIB_CMD", fake_haxelib)
    System.put_env("HAXE_TEST_LOG", compile_log)
    System.delete_env("HAXE_FAST_BOOT")

    opts = [
      hxml_file: top_hxml,
      source_dir: source_dir,
      target_dir: target_dir,
      extra_inputs: ["macro_inputs/**/*.json"],
      manifest_path: manifest
    ]

    %{
      compile_log: compile_log,
      extra_params: extra_params,
      fake_haxe: fake_haxe,
      generated_file: generated_file,
      haxelib_json: haxelib_json,
      library_descriptor: library_descriptor,
      library_source: library_source,
      macro_input: macro_input,
      macro_inputs_dir: macro_inputs_dir,
      main_source: main_source,
      manifest: manifest,
      nested_hxml: nested_hxml,
      opts: opts,
      resource_dir: resource_dir,
      resource_file: resource_file,
      shared_dir: shared_dir,
      shared_source: shared_source
    }
  end

  defp nested_hxml(define) do
    """
    -C ..
    -p src_haxe
    -p src_shared
    -L sample
    -r resources/template.txt@template
    -D #{define}
    -D elixir_output=lib
    Main
    """
  end

  defp write_fake_haxe(path, compiler_identity) do
    File.write!(path, """
    #!/bin/sh
    # #{compiler_identity}
    if [ "${1:-}" = "--version" ]; then
      printf 'fake-haxe 1.0\\n'
      exit 0
    fi
    if [ -n "${HAXE_TEST_MUTATE_SOURCE:-}" ]; then
      printf 'class Main { static final value = 99; }\\n' > "$HAXE_TEST_MUTATE_SOURCE"
    fi
    printf 'compile\\n' >> "$HAXE_TEST_LOG"
    exit 0
    """)

    File.chmod!(path, 0o755)
  end

  defp write_fake_haxelib(path) do
    File.write!(path, """
    #!/bin/sh
    descriptor="$HAXELIB_PATH/$2.hxml"
    if [ "${1:-}" != "path" ] || [ ! -f "$descriptor" ]; then
      exit 1
    fi
    while IFS= read -r line; do
      case "$line" in
        "-cp "*) printf '%s\\n' "${line#-cp }" ;;
        "-D "*) printf '%s\\n' "$line" ;;
      esac
    done < "$descriptor"
    """)

    File.chmod!(path, 0o755)
  end

  defp rewrite_with_fixed_mtime(path, contents) do
    File.write!(path, contents)
    File.touch!(path, @fixed_time)
  end

  defp assert_single_rebuild(opts, compile_log, expected_count) do
    assert HaxeCompiler.needs_recompilation?(opts)
    assert {:ok, _compiled_files} = HaxeCompiler.compile(opts)
    refute HaxeCompiler.needs_recompilation?(opts)
    assert compile_count(compile_log) == expected_count
  end

  defp compile_count(path) do
    path
    |> File.read!()
    |> String.split("\n", trim: true)
    |> length()
  end
end

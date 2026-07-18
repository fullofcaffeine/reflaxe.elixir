defmodule HaxePhoenixLiveReact do
  def apply!(project_root, opts \\ nil) do
    execute!(project_root, :apply, opts)
  end

  def check!(project_root, opts \\ nil) do
    execute!(project_root, :check, opts)
  end

  def remove!(project_root, opts \\ nil) do
    execute!(project_root, :remove, opts)
  end

  def execute!(project_root, mode, opts \\ nil) do
    options = normalize_options(opts)
    root = canonical_project_root(project_root)
    recovery_status = HaxeProjectPatch.recovery_status!(root)

    if mode == :check and recovery_status != :clean do
      Kernel.raise(
        "LiveReact integration check found an interrupted project patch transaction (#{Kernel.inspect(recovery_status)}). No writes occurred. Re-run `mix haxe.phoenix.live_react` to recover it, then run `--check` again."
      )
    else
      if mode != :check do
        HaxeProjectPatch.recover!(root)
      end

      existing_manifest = read_manifest(root, mode)

      result =
        if mode == :remove do
          build_remove_plan(root, existing_manifest, options)
        else
          build_apply_plan(root, existing_manifest, options, mode == :apply)
        end

      finish_execution(result, mode, options)
    end
  end

  def default_live_react_dependency() do
    HaxePhoenixLiveReact.Dependency.default_dependency()
  end

  def compatibility() do
    HaxePhoenixLiveReact.Core.compatibility()
  end

  defp finish_execution(result, mode, opts) do
    changes = HaxeProjectPatch.changes(result.plan)

    if mode == :check do
      if length(changes) == 0, do: drop_plan(result), else: raise_drift(changes)
    else
      report = Keyword.get(opts, :report, fn message -> IO.puts(message) end)

      Enum.each(changes, fn change ->
        action = Map.fetch!(change, :action)
        relative = Map.fetch!(change, :relative)
        report.("[live-react] " <> Kernel.to_string(action) <> " " <> relative)
      end)

      if length(changes) == 0 do
        drop_plan(result)
      else
        if Keyword.get(opts, :yes, false) do
          HaxeProjectPatch.publish!(result.plan, nil)
          drop_plan(result)
        else
          confirm = Keyword.get(opts, :confirm, fn _prompt -> false end)

          if not confirm.(HaxePhoenixLiveReact.Core.confirmation_prompt(mode, length(changes))) do
            :cancelled
          else
            HaxeProjectPatch.publish!(result.plan, nil)
            drop_plan(result)
          end
        end
      end
    end
  end

  defp drop_plan(result) do
    Map.drop(result, [:plan])
  end

  defp raise_drift(changes) do
    paths = Enum.map_join(changes, "\n", fn change -> "  - " <> Map.fetch!(change, :relative) end)

    Kernel.raise(
      Enum.join(
        [
          "LiveReact integration drift detected:",
          paths,
          "No writes occurred. Run `mix haxe.phoenix.live_react` to reconcile owned state, or `--remove` to remove it."
        ],
        "\n"
      )
    )
  end

  defp canonical_project_root(project_root) do
    expanded = Path.expand(project_root)
    physical = HaxePhoenixLiveReact.Host.physical_directory(expanded)
    physical_tag = tag(physical)

    if physical_tag != :ok do
      Kernel.raise(
        "cannot resolve Phoenix project root #{expanded}: #{HaxePhoenixLiveReact.Host.format_path_error(Kernel.elem(physical, 1))}"
      )
    else
      root = Kernel.elem(physical, 1)
      HaxePhoenixLiveReact.Host.require_regular_file(Path.join(root, "mix.exs"), "Mix project")
      root
    end
  end

  defp read_manifest(root, mode) do
    path = Path.join(root, "phoenixhx-live-react.json")
    read = File.read(path)
    read_tag = tag(read)

    if read_tag == :ok do
      manifest = decode_manifest(Kernel.elem(read, 1))
      validate_manifest(manifest, path)
    else
      reason = Kernel.elem(read, 1)

      if reason == :enoent and mode == :remove do
        Kernel.raise(
          "cannot remove PhoenixHx LiveReact integration: phoenixhx-live-react.json is missing. No writes occurred. Restore the owned manifest or remove the integration manually after reviewing every marker."
        )
      else
        if reason == :enoent and mode == :check do
          Kernel.raise(
            "LiveReact integration drift detected: phoenixhx-live-react.json is missing. No writes occurred. Run `mix haxe.phoenix.live_react` to install it."
          )
        else
          if reason == :enoent do
            nil
          else
            Kernel.raise("cannot read #{path}: #{:file.format_error(reason)}")
          end
        end
      end
    end
  end

  defp decode_manifest(content) do
    try do
      Jason.decode!(content)
    rescue
      error ->
        Kernel.raise(
          "invalid phoenixhx-live-react.json: " <>
            Exception.message(error) <> ". No writes occurred."
        )
    end
  end

  defp validate_manifest(manifest, path) do
    if not Kernel.is_map(manifest) do
      Kernel.raise("#{path} must contain a JSON object. No writes occurred.")
    else
      if Map.get(manifest, "schema") != "phoenixhx.live-react@1" or
           Map.get(manifest, "generatedBy") != "mix haxe.phoenix.live_react" do
        Kernel.raise(
          "unsupported or unowned LiveReact integration manifest at #{path}. No writes occurred."
        )
      else
        required = [
          "schema",
          "generatedBy",
          "assetMode",
          "packageRoot",
          "clientMode",
          "mixDependency",
          "npmReference",
          "runtimePolicy",
          "components",
          "managed"
        ]

        keys = Map.keys(manifest)

        if Enum.sort(keys) != Enum.sort(required) do
          Kernel.raise(
            "#{path} has an unsupported key set. No writes occurred. Upgrade the integration tool or restore its generated manifest."
          )
        else
          managed = Map.get(manifest, "managed")

          if not Kernel.is_map(managed) or not Kernel.is_list(Map.get(managed, "files")) or
               not Kernel.is_list(Map.get(managed, "markers")) or
               not Kernel.is_list(Map.get(managed, "packageKeys")) or
               not Kernel.is_map(Map.get(managed, "restores")) or
               not Kernel.is_boolean(Map.get(managed, "dependencyOwned")) or
               not Kernel.is_boolean(Map.get(managed, "lockOwned")) do
            Kernel.raise("#{path} has invalid managed ownership metadata. No writes occurred.")
          else
            client_mode = Map.get(manifest, "clientMode")

            if Map.get(manifest, "assetMode") != "vite" or
                 (client_mode != "genes" and client_mode != "plain-js") or
                 not Kernel.is_binary(Map.get(manifest, "packageRoot")) or
                 not Kernel.is_map(Map.get(manifest, "mixDependency")) or
                 not Kernel.is_binary(Map.get(manifest, "npmReference")) or
                 not Kernel.is_map(Map.get(manifest, "runtimePolicy")) or
                 not Kernel.is_list(Map.get(manifest, "components")) do
              Kernel.raise("#{path} has invalid integration metadata. No writes occurred.")
            else
              manifest
            end
          end
        end
      end
    end
  end

  defp build_apply_plan(root, existing_manifest, opts, allow_resolution) do
    topology = discover_topology(root, existing_manifest, opts)
    validate_owned_topology(existing_manifest, topology)

    dependency =
      HaxePhoenixLiveReact.Dependency.resolve(
        root,
        topology,
        existing_manifest,
        opts,
        allow_resolution
      )

    package_plan = HaxePhoenixLiveReact.Package.plan(topology, dependency, existing_manifest)
    source = read_required_sources(topology)
    restores = existing_restores(existing_manifest)

    mix_patched =
      HaxePhoenixLiveReact.SourcePatcher.patch_mix_exs(
        source.mix_exs,
        topology,
        dependency,
        restores
      )

    restores =
      HaxePhoenixLiveReact.SourcePatcher.put_restore(
        elem(mix_patched, 1),
        "mix.lockOriginalState",
        dependency.original_lock_state
      )

    config_patched =
      HaxePhoenixLiveReact.SourcePatcher.patch_config_exs(source.config_exs, restores)

    dev_patched =
      HaxePhoenixLiveReact.SourcePatcher.patch_dev_exs(
        source.dev_exs,
        topology,
        elem(config_patched, 1)
      )

    app_patched =
      HaxePhoenixLiveReact.SourcePatcher.patch_app_js(source.app_js, elem(dev_patched, 1))

    layout_patched =
      HaxePhoenixLiveReact.SourcePatcher.patch_root_layout(
        source.root_layout,
        elem(app_patched, 1)
      )

    managed_files = managed_files_for(topology)

    manifest_data = %{
      topology: topology,
      dependency: dependency,
      managed_files: managed_files,
      package_keys: package_plan.owned_keys,
      restores: elem(layout_patched, 1),
      dependency_owned: dependency.owned,
      lock_owned: dependency.lock_owned
    }

    manifest = render_manifest(manifest_data)
    plan = HaxeProjectPatch.new!(root, [{:recover, false}])

    plan =
      plan
      |> HaxeProjectPatch.write_file!(Path.join(root, "mix.exs"), elem(mix_patched, 0), nil)
      |> HaxePhoenixLiveReact.Dependency.write_lock_if_changed(root, dependency)
      |> HaxeProjectPatch.write_file!(
        Path.join([root, "config", "config.exs"]),
        elem(config_patched, 0),
        nil
      )
      |> HaxeProjectPatch.write_file!(
        Path.join([root, "config", "dev.exs"]),
        elem(dev_patched, 0),
        nil
      )
      |> HaxeProjectPatch.write_file!(
        Path.join([root, "assets", "js", "app.js"]),
        elem(app_patched, 0),
        nil
      )
      |> HaxeProjectPatch.write_file!(topology.root_layout, elem(layout_patched, 0), nil)
      |> HaxeProjectPatch.write_file!(topology.package_json, package_plan.content, nil)
      |> plan_managed_file(
        topology.vite_config,
        HaxePhoenixLiveReact.Core.render_vite_config(topology.package_root_relative)
      )
      |> plan_managed_file(topology.hooks_file, HaxePhoenixLiveReact.Core.render_hooks_file())
      |> plan_managed_file(
        topology.registry_file,
        HaxePhoenixLiveReact.Core.render_registry_file()
      )
      |> HaxeProjectPatch.write_file!(Path.join(root, "phoenixhx-live-react.json"), manifest, [
        {:manifest?, true}
      ])

    %{
      plan: plan,
      mode: if(allow_resolution, do: :apply, else: :check),
      package_root: topology.package_root_relative,
      client_mode: topology.client_mode,
      dependency: dependency.identity,
      npm_reference: dependency.npm_reference,
      changes: HaxeProjectPatch.changes(plan)
    }
  end

  defp build_remove_plan(root, manifest, opts) do
    topology = discover_topology(root, manifest, opts)
    validate_owned_topology(manifest, topology)
    restores = existing_restores(manifest)
    source = read_required_sources(topology)
    package_plan = HaxePhoenixLiveReact.Package.remove(topology, manifest)
    retain_live_react = Enum.member?(package_plan.retained_keys, "dependencies.live_react")

    mix_exs =
      HaxePhoenixLiveReact.SourcePatcher.remove_mix_wiring(
        source.mix_exs,
        manifest,
        topology,
        restores,
        retain_live_react
      )

    config_exs =
      HaxePhoenixLiveReact.SourcePatcher.remove_config_wiring(source.config_exs, restores)

    dev_exs =
      HaxePhoenixLiveReact.SourcePatcher.remove_dev_wiring(source.dev_exs, topology, restores)

    app_js = HaxePhoenixLiveReact.SourcePatcher.remove_app_js_wiring(source.app_js, restores)

    root_layout =
      HaxePhoenixLiveReact.SourcePatcher.remove_root_layout_wiring(source.root_layout, restores)

    plan = HaxeProjectPatch.new!(root, [{:recover, false}])

    plan =
      plan
      |> HaxeProjectPatch.write_file!(Path.join(root, "mix.exs"), mix_exs, nil)
      |> HaxePhoenixLiveReact.Dependency.remove_owned_lock(root, manifest, retain_live_react)
      |> HaxeProjectPatch.write_file!(Path.join([root, "config", "config.exs"]), config_exs, nil)
      |> HaxeProjectPatch.write_file!(Path.join([root, "config", "dev.exs"]), dev_exs, nil)
      |> HaxeProjectPatch.write_file!(Path.join([root, "assets", "js", "app.js"]), app_js, nil)
      |> HaxeProjectPatch.write_file!(topology.root_layout, root_layout, nil)
      |> HaxeProjectPatch.write_file!(topology.package_json, package_plan.content, nil)

    managed = Map.fetch!(manifest, "managed")
    owned_files = Map.fetch!(managed, "files")

    plan =
      Enum.reduce(owned_files, plan, fn relative, current ->
        plan_generated_removal(current, root, relative)
      end)

    manifest_path = Path.join(root, "phoenixhx-live-react.json")

    plan =
      HaxeProjectPatch.update_file!(
        plan,
        manifest_path,
        fn state ->
          if state.state == :regular do
            :delete
          else
            Kernel.raise("phoenixhx-live-react.json disappeared during removal planning")
          end
        end,
        [{:manifest?, true}]
      )

    dependency_owned = Map.fetch!(managed, "dependencyOwned")

    %{
      plan: plan,
      mode: :remove,
      package_root: topology.package_root_relative,
      client_mode: topology.client_mode,
      retained_package_keys: package_plan.retained_keys,
      retained_live_react_dependency: retain_live_react and dependency_owned,
      changes: HaxeProjectPatch.changes(plan)
    }
  end

  defp discover_topology(root, existing_manifest, opts) do
    HaxePhoenixLiveReact.Host.require_regular_file(
      Path.join([root, "config", "config.exs"]),
      "Phoenix config"
    )

    HaxePhoenixLiveReact.Host.require_regular_file(
      Path.join([root, "config", "dev.exs"]),
      "Phoenix development config"
    )

    HaxePhoenixLiveReact.Host.require_regular_file(
      Path.join([root, "assets", "js", "app.js"]),
      "Phoenix JavaScript entry"
    )

    package_root = discover_package_root(root, Keyword.get(opts, :package_root, nil))
    root_layout = discover_root_layout(root)
    detected_mode = detect_client_mode(root)
    requested_mode = Keyword.get(opts, :client_mode, nil)
    client_mode = nil

    client_mode =
      cond do
        Kernel.is_nil(requested_mode) ->
          client_mode = detected_mode
          client_mode

        (requested_mode == :genes or requested_mode == :plain_js) and
            requested_mode == detected_mode ->
          client_mode = requested_mode
          client_mode

        requested_mode == :genes or requested_mode == :plain_js ->
          Kernel.raise(
            "requested client mode " <>
              HaxePhoenixLiveReact.Core.client_mode_label(requested_mode) <>
              " does not match the project topology (detected " <>
              HaxePhoenixLiveReact.Core.client_mode_label(detected_mode) <>
              "). No writes occurred. Run the Phoenix scaffold first."
          )

          client_mode

        true ->
          Kernel.raise(
            "invalid LiveReact client mode " <>
              Kernel.inspect(requested_mode) <> " (expected genes or plain-js)"
          )

          client_mode
      end

    if not Kernel.is_nil(existing_manifest) do
      expected_package = Map.get(existing_manifest, "packageRoot")
      expected_mode = Map.get(existing_manifest, "clientMode")

      if expected_package != package_root.relative do
        Kernel.raise(
          "LiveReact package-root drift: the manifest owns #{Kernel.inspect(expected_package)}, but discovery selected #{Kernel.inspect(package_root.relative)}. No writes occurred. Use the original --package-root or remove the integration first."
        )
      else
        if expected_mode != HaxePhoenixLiveReact.Core.client_mode_label(client_mode) do
          Kernel.raise(
            "LiveReact client-mode drift: the manifest owns #{Kernel.to_string(expected_mode)}, but the project now looks like #{HaxePhoenixLiveReact.Core.client_mode_label(client_mode)}. No writes occurred. Remove and re-apply the integration after converging the Phoenix scaffold."
          )
        end
      end

      %{
        root: root,
        package_root: package_root.absolute,
        package_root_relative: package_root.relative,
        package_json: Path.join(package_root.absolute, "package.json"),
        vite_config: Path.join(package_root.absolute, "vite.config.mjs"),
        hooks_file: Path.join([root, "assets", "js", "live-react-hooks.js"]),
        registry_file: Path.join([root, "assets", "react-components", "registry.generated.js"]),
        root_layout: root_layout,
        client_mode: client_mode
      }
    else
      %{
        root: root,
        package_root: package_root.absolute,
        package_root_relative: package_root.relative,
        package_json: Path.join(package_root.absolute, "package.json"),
        vite_config: Path.join(package_root.absolute, "vite.config.mjs"),
        hooks_file: Path.join([root, "assets", "js", "live-react-hooks.js"]),
        registry_file: Path.join([root, "assets", "react-components", "registry.generated.js"]),
        root_layout: root_layout,
        client_mode: client_mode
      }
    end
  end

  defp discover_package_root(root, explicit) do
    candidates = nil

    candidates =
      cond do
        Kernel.is_nil(explicit) ->
          candidates =
            Enum.filter([".", "assets"], fn relative ->
              File.regular?(Path.join([root, relative, "package.json"]))
            end)

          candidates

        Kernel.is_binary(explicit) ->
          candidates = [validate_package_root_argument(Kernel.to_string(explicit))]
          candidates

        true ->
          Kernel.raise("invalid --package-root " <> Kernel.inspect(explicit))
          candidates
      end

    relative = nil

    relative =
      cond do
        length(candidates) == 1 ->
          relative = Enum.at(candidates, 0)
          relative

        length(candidates) == 0 ->
          Kernel.raise(
            "could not find package.json at the project root or assets/package.json. No writes occurred. Create one package root or pass a project-relative --package-root."
          )

          relative

        true ->
          Kernel.raise(
            "multiple npm package roots found: " <>
              Enum.join(candidates, ", ") <>
              ". No writes occurred. Pass --package-root explicitly."
          )

          relative
      end

    normalized = normalize_relative_root(relative)

    if normalized != "." and normalized != "assets" do
      Kernel.raise(
        "unsupported npm package root #{Kernel.inspect(relative)}. No writes occurred. The initial integration supports only package.json or assets/package.json."
      )
    else
      absolute = Path.expand(relative, root)
      physical = HaxePhoenixLiveReact.Host.physical_directory(absolute)
      physical_tag = tag(physical)

      if physical_tag != :ok do
        Kernel.raise(
          "cannot resolve package root #{relative}: #{HaxePhoenixLiveReact.Host.format_path_error(Kernel.elem(physical, 1))}"
        )
      else
        real = Kernel.elem(physical, 1)

        if not inside_root(root, real) do
          Kernel.raise(
            "package root #{Kernel.inspect(relative)} resolves outside the Phoenix project. No writes occurred."
          )
        else
          HaxePhoenixLiveReact.Host.require_regular_file(
            Path.join(real, "package.json"),
            "npm package"
          )

          %{relative: normalized, absolute: real}
        end
      end
    end
  end

  defp validate_package_root_argument(value) do
    if value == "" do
      Kernel.raise("--package-root may not be empty")
    else
      value_type = Path.type(value)

      if value_type == :absolute do
        Kernel.raise("--package-root must be project-relative")
      else
        if Enum.any?(Path.split(value), fn part -> part == ".." or part == "" end) do
          Kernel.raise("--package-root may not contain parent traversal")
        else
          value
        end
      end
    end
  end

  defp normalize_relative_root(value) do
    if value == "." do
      "."
    else
      Path.join(Path.split(value))
    end
  end

  defp inside_root(root, path) do
    relative = Path.relative_to(path, root)
    relative_type = Path.type(relative)
    relative == "." or (relative_type == :relative and not String.starts_with?(relative, ".."))
  end

  defp discover_root_layout(root) do
    patterns = [
      Path.join([root, "lib", "*_web", "components", "layouts", "root.html.heex"]),
      Path.join([root, "lib", "*_web", "templates", "layout", "root.html.heex"]),
      Path.join([root, "lib", "*_web", "templates", "layout", "root.html.leex"])
    ]

    matches = Enum.uniq(Enum.flat_map(patterns, fn pattern -> Path.wildcard(pattern) end))

    if length(matches) == 1 do
      Enum.at(matches, 0)
    else
      if length(matches) == 0 do
        Kernel.raise(
          "could not find one canonical Phoenix root layout. No writes occurred. Expected lib/*_web/components/layouts/root.html.heex or the legacy template path."
        )
      else
        Kernel.raise(
          "multiple Phoenix root layouts found: #{Enum.map_join(matches, ", ", fn path -> Path.relative_to(path, root) end)}. No writes occurred."
        )
      end
    end
  end

  defp detect_client_mode(root) do
    indicators = [
      Path.join(root, "build-client.hxml"),
      Path.join([root, "src_haxe", "client", "Boot.hx"]),
      Path.join([root, "haxe_libraries", "genes.hxml"])
    ]

    if Enum.all?(indicators, fn path -> File.regular?(path) end), do: :genes, else: :plain_js
  end

  defp read_required_sources(topology) do
    %{
      mix_exs: File.read!(Path.join(topology.root, "mix.exs")),
      config_exs: File.read!(Path.join([topology.root, "config", "config.exs"])),
      dev_exs: File.read!(Path.join([topology.root, "config", "dev.exs"])),
      app_js: File.read!(Path.join([topology.root, "assets", "js", "app.js"])),
      root_layout: File.read!(topology.root_layout)
    }
  end

  defp existing_restores(manifest) do
    if Kernel.is_nil(manifest) do
      Map.new()
    else
      managed = Map.fetch!(manifest, "managed")
      Map.fetch!(managed, "restores")
    end
  end

  defp managed_files_for(topology) do
    Enum.sort(
      Enum.map([topology.vite_config, topology.hooks_file, topology.registry_file], fn path ->
        Path.relative_to(path, topology.root)
      end)
    )
  end

  defp render_manifest(data) do
    managed =
      json_object([
        {"files", data.managed_files},
        {"markers", HaxePhoenixLiveReact.SourcePatcher.managed_markers(data.topology)},
        {"packageKeys", data.package_keys},
        {"dependencyOwned", data.dependency_owned},
        {"lockOwned", data.lock_owned},
        {"restores", data.restores}
      ])

    manifest =
      json_object([
        {"schema", "phoenixhx.live-react@1"},
        {"generatedBy", "mix haxe.phoenix.live_react"},
        {"assetMode", "vite"},
        {"packageRoot", data.topology.package_root_relative},
        {"clientMode", HaxePhoenixLiveReact.Core.client_mode_label(data.topology.client_mode)},
        {"mixDependency", data.dependency.identity},
        {"npmReference", data.dependency.npm_reference},
        {"runtimePolicy", HaxePhoenixLiveReact.Core.runtime_policy()},
        {"components", []},
        {"managed", managed}
      ])

    options = [{:pretty, true}]
    Enum.join([Jason.encode!(manifest, options), ""], "\n")
  end

  defp validate_owned_topology(manifest, topology) do
    if Kernel.is_nil(manifest) do
      nil
    else
      managed = Map.fetch!(manifest, "managed")
      files = Map.fetch!(managed, "files")
      markers = Map.fetch!(managed, "markers")

      if Enum.sort(files) != managed_files_for(topology) or
           markers != HaxePhoenixLiveReact.SourcePatcher.managed_markers(topology) or
           Map.get(manifest, "runtimePolicy") != HaxePhoenixLiveReact.Core.runtime_policy() do
        Kernel.raise(
          "phoenixhx-live-react.json ownership or client-only policy does not match this integration version. No writes occurred. Upgrade the tool or restore the generated manifest."
        )
      end
    end
  end

  defp plan_managed_file(plan, path, desired) do
    HaxeProjectPatch.write_file!(plan, path, managed_file_content(path, desired), nil)
  end

  defp managed_file_content(path, desired) do
    read = File.read(path)
    read_tag = tag(read)

    if read_tag == :ok do
      managed =
        HaxeProjectPatch.managed_file_content(
          Kernel.elem(read, 1),
          "@generated by mix haxe.phoenix.live_react; do not edit",
          desired
        )

      managed_tag = tag(managed)

      if managed_tag == :ok do
        Kernel.elem(managed, 1)
      else
        if managed_tag == :unowned do
          Kernel.raise(
            "cannot write #{path}: the generated path exists without the PhoenixHx LiveReact ownership signature. No writes occurred. Move the file or integrate it manually."
          )
        else
          Kernel.raise(
            "cannot write #{path}: invalid generated ownership signature #{Kernel.inspect(Kernel.elem(managed, 1))}. No writes occurred."
          )
        end
      end
    else
      reason = Kernel.elem(read, 1)

      if reason != :enoent do
        Kernel.raise("cannot read #{path}: #{:file.format_error(reason)}")
      else
        desired
      end
    end
  end

  defp plan_generated_removal(plan, root, relative) do
    path = Path.join(root, relative)
    read = File.read(path)
    read_tag = tag(read)

    if read_tag == :ok do
      status =
        HaxeProjectPatch.signature_status(
          Kernel.elem(read, 1),
          "@generated by mix haxe.phoenix.live_react; do not edit"
        )

      status_tag = tag(status)

      if status_tag == :owned do
        HaxeProjectPatch.delete_file!(plan, path, nil)
      else
        if status_tag == :unowned do
          Kernel.raise(
            "cannot remove #{relative}: the generated ownership signature is missing. No writes occurred. Preserve the file and remove it manually after review."
          )
        else
          Kernel.raise(
            "cannot remove #{relative}: duplicate ownership signature #{Kernel.inspect(Kernel.elem(status, 1))}. No writes occurred."
          )
        end
      end
    else
      reason = Kernel.elem(read, 1)

      if reason == :enoent do
        plan
      else
        Kernel.raise("cannot read #{path}: #{:file.format_error(reason)}")
      end
    end
  end

  defp json_object(entries) do
    Enum.reduce(entries, Map.new(), fn entry, value ->
      Map.put(value, elem(entry, 0), elem(entry, 1))
    end)
  end

  defp normalize_options(opts) do
    if Kernel.is_nil(opts), do: [], else: opts
  end

  defp tag(value) do
    if Kernel.is_tuple(value) do
      Kernel.elem(value, 0)
    else
      value
    end
  end
end

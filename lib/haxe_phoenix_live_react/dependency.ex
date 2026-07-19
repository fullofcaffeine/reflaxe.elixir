defmodule HaxePhoenixLiveReact.Dependency do
  def default_dependency() do
    options = [
      {:git, "https://github.com/mrdotb/live_react.git"},
      {:ref, "055e80e6a4e6d009df5e229eb39e7f85f03fea22"}
    ]

    {:live_react, options}
  end

  def resolve(root, topology, existing_manifest, opts, allow_resolution) do
    dependencies = Keyword.get(opts, :mix_dependencies, [])

    declaration =
      Enum.find(dependencies, fn candidate ->
        name = dependency_name(candidate)
        name == :live_react
      end)

    mix_exs = File.read!(Path.join(root, "mix.exs"))
    marker_owned = String.contains?(mix_exs, "BEGIN reflaxe_elixir live_react_dependency")
    textual_declaration = Regex.match?(rx("\\{\\s*:live_react\\b"), mix_exs)

    if textual_declaration and Kernel.is_nil(declaration) and not marker_owned do
      Kernel.raise(
        "mix.exs declares :live_react, but the loaded Mix project did not expose that dependency. No writes occurred. Re-run the task in the project root after reloading Mix."
      )
    else
      dependency_owned = nil

      dependency_owned =
        cond do
          not Kernel.is_nil(existing_manifest) ->
            dependency_owned = manifest_managed_bool(existing_manifest, "dependencyOwned")
            dependency_owned

          marker_owned ->
            Kernel.raise(
              "mix.exs contains a PhoenixHx LiveReact dependency marker but phoenixhx-live-react.json is missing. No writes occurred. Restore the manifest or remove the stale marker manually."
            )

            dependency_owned

          true ->
            dependency_owned = not textual_declaration
            dependency_owned
        end

      expected_source = dependency_source(declaration, dependency_owned)
      lock_path = Path.join(root, "mix.lock")
      lock_source = read_lock_source(lock_path)
      initial_lock_content = Kernel.elem(lock_source, 0)
      lock_existed = Kernel.elem(lock_source, 1)
      initial_lock = read_lock_content(initial_lock_content, lock_path)

      original_lock_state =
        if not Kernel.is_nil(existing_manifest) do
          restores = manifest_restores(existing_manifest)

          HaxePhoenixLiveReact.SourcePatcher.require_restore_key(
            restores,
            "mix.lockOriginalState"
          )

          validate_original_lock_state(Map.fetch!(restores, "mix.lockOriginalState"))
        else
          original_lock_state_for(initial_lock_content, initial_lock, lock_existed)
        end

      if dependency_owned and Kernel.is_nil(existing_manifest) and
           Map.has_key?(initial_lock, :live_react) do
        Kernel.raise(
          "mix.lock already contains an unowned :live_react entry while mix.exs has no matching dependency. No writes occurred. Remove the stale lock entry or declare the dependency explicitly before retrying."
        )
      else
        checkout = dependency_checkout(root, expected_source)

        current =
          validate_resolved_dependency(expected_source, initial_lock, checkout, topology, opts)

        resolved = nil
        lock_content = nil
        lock_changed = nil
        current_tag = tag(current)

        {lock_changed, lock_content, resolved} =
          cond do
            current_tag == :ok ->
              resolved = Kernel.elem(current, 1)
              lock_content = initial_lock_content
              lock_changed = false
              {lock_changed, lock_content, resolved}

            not allow_resolution ->
              Kernel.raise(
                "LiveReact dependency drift: " <>
                  Kernel.to_string(Kernel.elem(current, 1)) <>
                  ". No writes occurred and --check did not access the network. Run `mix haxe.phoenix.live_react` to resolve the checked dependency."
              )

              {lock_changed, lock_content, resolved}

            true ->
              resolver =
                Keyword.get(opts, :dependency_resolver, fn context ->
                  resolve_with_loaded_mix(context)
                end)

              context = %{
                root: root,
                current_lock_content: initial_lock_content,
                dependencies: dependencies,
                dependency:
                  if(Kernel.is_nil(declaration), do: default_dependency(), else: declaration),
                dependency_owned: dependency_owned,
                dependency_path: checkout
              }

              resolution = resolver.(context)
              resolved_lock_content = Map.fetch!(resolution, :lock_content)
              resolved_checkout = Map.get(resolution, :dependency_path, checkout)
              resolved_lock = read_lock_content(resolved_lock_content, "temporary LiveReact lock")

              {lock_changed, lock_content, resolved} =
                if Map.delete(resolved_lock, :live_react) != Map.delete(initial_lock, :live_react) do
                  Kernel.raise(
                    "Mix changed lock entries unrelated to :live_react while resolving the integration. No tracked files were written. Converge the existing dependencies first, then retry."
                  )

                  {lock_changed, lock_content, resolved}
                else
                  validated =
                    validate_resolved_dependency(
                      expected_source,
                      resolved_lock,
                      resolved_checkout,
                      topology,
                      opts
                    )

                  validated_tag = tag(validated)

                  {lock_changed, lock_content, resolved} =
                    if validated_tag != :ok do
                      Kernel.raise(
                        "Mix resolved :live_react, but its identity is not usable: " <>
                          Kernel.to_string(Kernel.elem(validated, 1)) <>
                          ". No tracked integration files were written."
                      )

                      {lock_changed, lock_content, resolved}
                    else
                      resolved = Kernel.elem(validated, 1)

                      owned_lock =
                        insert_lock_entry(
                          initial_lock_content,
                          initial_lock,
                          Map.fetch!(resolved_lock, :live_react)
                        )

                      lock_content = owned_lock
                      lock_changed = owned_lock != initial_lock_content
                      {lock_changed, lock_content, resolved}
                    end

                  {lock_changed, lock_content, resolved}
                end

              {lock_changed, lock_content, resolved}
          end

        if not Kernel.is_nil(existing_manifest) do
          if Map.get(existing_manifest, "mixDependency") != resolved.identity or
               Map.get(existing_manifest, "npmReference") != resolved.npm_reference do
            Kernel.raise(
              "LiveReact dependency identity changed from the owned manifest. No writes occurred. Remove and re-apply the integration after reviewing the upstream change."
            )
          else
            %{
              identity: resolved.identity,
              npm_reference: resolved.npm_reference,
              checkout: resolved.checkout,
              source: resolved.source,
              owned: dependency_owned,
              lock_owned:
                if(Kernel.is_nil(existing_manifest),
                  do: dependency_owned,
                  else: manifest_managed_bool(existing_manifest, "lockOwned")
                ),
              lock_content: lock_content,
              lock_changed: lock_changed,
              original_lock_state: original_lock_state
            }
          end
        else
          %{
            identity: resolved.identity,
            npm_reference: resolved.npm_reference,
            checkout: resolved.checkout,
            source: resolved.source,
            owned: dependency_owned,
            lock_owned:
              if(Kernel.is_nil(existing_manifest),
                do: dependency_owned,
                else: manifest_managed_bool(existing_manifest, "lockOwned")
              ),
            lock_content: lock_content,
            lock_changed: lock_changed,
            original_lock_state: original_lock_state
          }
        end
      end
    end
  end

  def write_lock_if_changed(plan, root, dependency) do
    if dependency.lock_changed do
      HaxeProjectPatch.write_file!(
        plan,
        Path.join(root, "mix.lock"),
        dependency.lock_content,
        nil
      )
    else
      plan
    end
  end

  def remove_owned_lock(plan, root, manifest, retain_live_react) do
    if retain_live_react or not manifest_managed_bool(manifest, "lockOwned") do
      plan
    else
      path = Path.join(root, "mix.lock")
      restores = manifest_restores(manifest)
      HaxePhoenixLiveReact.SourcePatcher.require_restore_key(restores, "mix.lockOriginalState")
      original_state = validate_original_lock_state(Map.fetch!(restores, "mix.lockOriginalState"))
      current_content = File.read!(path)
      current_lock = read_lock_content(current_content, path)

      if not Map.has_key?(current_lock, :live_react) do
        Kernel.raise(
          "the task-owned :live_react lock entry is missing. No writes occurred. Restore the lock entry or retain LiveReact as hand-owned before retrying."
        )
      else
        retained_lock = Map.delete(current_lock, :live_react)
        retained_content = remove_lock_entry_line(current_content, :live_react)
        kind = Map.fetch!(original_state, "kind")

        if Kernel.map_size(retained_lock) == 0 and kind == "missing" do
          HaxeProjectPatch.delete_file!(plan, path, nil)
        else
          if Kernel.map_size(retained_lock) == 0 and kind == "empty" do
            HaxeProjectPatch.write_file!(plan, path, Map.fetch!(original_state, "content"), nil)
          else
            HaxeProjectPatch.write_file!(plan, path, retained_content, nil)
          end
        end
      end
    end
  end

  def validate_original_lock_state(state) do
    if not Kernel.is_map(state) do
      invalid_original_lock_state()
    else
      kind = Map.get(state, "kind")

      if kind == "missing" do
        state
      else
        if kind == "empty" do
          content = Map.get(state, "content")

          if not Kernel.is_nil(content) and supported_empty_lock(content) do
            state
          else
            if kind == "populated" do
              digest = Map.get(state, "sha256")

              if not Kernel.is_nil(digest) and Kernel.byte_size(digest) == 64,
                do: state,
                else: invalid_original_lock_state()
            else
              invalid_original_lock_state()
            end
          end
        else
          if kind == "populated" do
            digest = Map.get(state, "sha256")

            if not Kernel.is_nil(digest) and Kernel.byte_size(digest) == 64,
              do: state,
              else: invalid_original_lock_state()
          else
            invalid_original_lock_state()
          end
        end
      end
    end
  end

  defp invalid_original_lock_state() do
    Kernel.raise(
      "phoenixhx-live-react.json has invalid original mix.lock ownership metadata. No writes occurred."
    )
  end

  defp dependency_name(declaration) do
    if not Kernel.is_tuple(declaration) do
      nil
    else
      size = Kernel.tuple_size(declaration)

      if (size == 2 or size == 3) and Kernel.is_atom(Kernel.elem(declaration, 0)) do
        Kernel.elem(declaration, 0)
      else
        nil
      end
    end
  end

  defp dependency_source(declaration, owned) do
    if owned do
      expected = %{
        kind: :git,
        repository: normalize_git_repository("https://github.com/mrdotb/live_react.git"),
        ref: "055e80e6a4e6d009df5e229eb39e7f85f03fea22"
      }

      if Kernel.is_nil(declaration) do
        expected
      else
        actual = declared_dependency_source(declaration)

        if same_source(actual, expected) do
          expected
        else
          Kernel.raise(
            "the task-owned :live_react declaration changed from #{Kernel.inspect(default_dependency())} to #{Kernel.inspect(declaration)}. No writes occurred."
          )
        end
      end
    else
      if Kernel.is_nil(declaration) do
        Kernel.raise(
          "the LiveReact manifest says the Mix dependency is hand-owned, but the loaded project has no :live_react dependency. No writes occurred."
        )
      else
        declared_dependency_source(declaration)
      end
    end
  end

  defp declared_dependency_source(declaration) do
    name = dependency_name(declaration)

    if not Kernel.is_tuple(declaration) or name != :live_react do
      unsupported_declaration(declaration)
    else
      size = Kernel.tuple_size(declaration)

      cond do
        size == 2 -> dependency_source_from_two_tuple(declaration)
        size == 3 -> dependency_source_from_three_tuple(declaration)
        true -> unsupported_declaration(declaration)
      end
    end
  end

  defp dependency_source_from_two_tuple(declaration) do
    second = Kernel.elem(declaration, 1)

    cond do
      Kernel.is_binary(second) ->
        %{kind: :hex, package_name: "live_react", requirement: Kernel.to_string(second)}

      Kernel.is_list(second) ->
        dependency_source_from_options(nil, Kernel.elem(declaration, 1))

      true ->
        unsupported_declaration(declaration)
    end
  end

  defp dependency_source_from_three_tuple(declaration) do
    requirement = Kernel.elem(declaration, 1)
    options = Kernel.elem(declaration, 2)

    if Kernel.is_binary(requirement) and Kernel.is_list(options),
      do:
        dependency_source_from_options(Kernel.to_string(requirement), Kernel.elem(declaration, 2)),
      else: unsupported_declaration(declaration)
  end

  defp unsupported_declaration(declaration) do
    Kernel.raise(
      "unsupported :live_react dependency declaration #{Kernel.inspect(declaration)}. No writes occurred. Use a Git, Hex, or project-relative path dependency."
    )
  end

  defp dependency_source_from_options(requirement, options) do
    git = Keyword.get(options, :git, nil)

    if not Kernel.is_nil(git) do
      %{
        kind: :git,
        repository: normalize_git_repository(Kernel.to_string(git)),
        ref: Keyword.get(options, :ref, nil)
      }
    else
      path = Keyword.get(options, :path, nil)

      if not Kernel.is_nil(path) do
        %{kind: :path, path: Kernel.to_string(path)}
      else
        if not Kernel.is_nil(requirement) do
          package_value = Keyword.get(options, :hex, :live_react)
          %{kind: :hex, package_name: Kernel.to_string(package_value), requirement: requirement}
        else
          Kernel.raise(
            "unsupported :live_react dependency options #{Kernel.inspect(options)}. No writes occurred."
          )
        end
      end
    end
  end

  defp same_source(left, right) do
    if left.kind != right.kind do
      false
    else
      if left.kind == :git do
        left.repository == right.repository and left.ref == right.ref
      else
        if left.kind == :hex,
          do: left.package_name == right.package_name and left.requirement == right.requirement,
          else: left.path == right.path
      end
    end
  end

  defp dependency_checkout(root, source) do
    if source.kind == :path do
      Path.expand(source.path, root)
    else
      Path.join([root, "deps", "live_react"])
    end
  end

  defp validate_resolved_dependency(source, lock, checkout, topology, opts) do
    directory_result = validate_checkout_directory(checkout)

    if directory_result != :ok do
      directory_result
    else
      identity_result = identity_from_lock(source, lock, checkout, topology.root)
      identity_tag = tag(identity_result)

      if identity_tag != :ok do
        identity_result
      else
        identity = Kernel.elem(identity_result, 1)
        checkout_result = validate_checkout_identity(identity, checkout, opts)

        if checkout_result != :ok do
          checkout_result
        else
          npm_result = npm_reference(topology, checkout)
          npm_tag = tag(npm_result)

          if npm_tag != :ok do
            npm_result
          else
            resolved = %{
              identity: identity,
              npm_reference: Kernel.elem(npm_result, 1),
              checkout: checkout,
              source: source
            }

            {:ok, resolved}
          end
        end
      end
    end
  end

  defp validate_checkout_directory(checkout) do
    if not File.dir?(checkout) do
      {:error, "dependency checkout is missing at " <> checkout}
    else
      if not File.regular?(Path.join(checkout, "package.json")) do
        {:error, checkout <> " is missing stock LiveReact package.json"}
      else
        if not File.regular?(Path.join(checkout, "mix.exs")),
          do: {:error, checkout <> " is missing stock LiveReact mix.exs"},
          else: :ok
      end
    end
  end

  defp identity_from_lock(source, lock, checkout, root) do
    if source.kind == :git do
      git_identity(source, Map.get(lock, :live_react))
    else
      if source.kind == :hex do
        hex_identity(source, Map.get(lock, :live_react))
      else
        path_identity(source, checkout, root)
      end
    end
  end

  defp git_identity(source, entry) do
    if Kernel.is_nil(entry) do
      {:error, "mix.lock has no :live_react entry"}
    else
      if not Kernel.is_tuple(entry) or Kernel.tuple_size(entry) != 4 or
           Kernel.elem(entry, 0) != :git or not Kernel.is_binary(Kernel.elem(entry, 1)) or
           not Kernel.is_binary(Kernel.elem(entry, 2)) do
        {:error,
         "mix.lock contains " <> Kernel.inspect(entry) <> " instead of a Git LiveReact lock"}
      else
        normalized = normalize_git_repository(Kernel.elem(entry, 1))
        revision = Kernel.elem(entry, 2)

        if normalized != source.repository do
          {:error,
           "Mix lock repository " <>
             Kernel.inspect(normalized) <> " does not match " <> Kernel.inspect(source.repository)}
        else
          if not Regex.match?(rx_with_options("^[0-9a-f]{40}$", "i"), revision) do
            {:error, "Mix lock revision is not a full Git commit"}
          else
            if not Kernel.is_nil(source.ref) and
                 Regex.match?(rx_with_options("^[0-9a-f]{40}$", "i"), source.ref) and
                 String.downcase(source.ref) != String.downcase(revision) do
              {:error, "Mix lock revision does not match the declared Git ref"}
            else
              identity =
                json_object([
                  {"name", "live_react"},
                  {"sourceKind", "git"},
                  {"repository", normalized},
                  {"resolvedRevision", String.downcase(revision)}
                ])

              {:ok, identity}
            end
          end
        end
      end
    end
  end

  defp hex_identity(source, entry) do
    if Kernel.is_nil(entry) do
      {:error, "mix.lock has no :live_react entry"}
    else
      if not Kernel.is_tuple(entry) or Kernel.tuple_size(entry) != 8 or
           Kernel.elem(entry, 0) != :hex or not Kernel.is_binary(Kernel.elem(entry, 2)) or
           not Kernel.is_binary(Kernel.elem(entry, 3)) do
        {:error,
         "mix.lock contains " <> Kernel.inspect(entry) <> " instead of a Hex LiveReact lock"}
      else
        package_name = Kernel.to_string(Kernel.elem(entry, 1))
        version = Kernel.elem(entry, 2)

        if package_name != source.package_name do
          {:error, "Hex package " <> package_name <> " does not match " <> source.package_name}
        else
          requirement_result = validate_hex_requirement(version, source.requirement)

          if requirement_result != :ok do
            requirement_result
          else
            identity =
              json_object([
                {"name", "live_react"},
                {"sourceKind", "hex"},
                {"package", package_name},
                {"repository", Kernel.to_string(Kernel.elem(entry, 6))},
                {"resolvedVersion", version},
                {"checksum", normalize_lock_checksum(Kernel.elem(entry, 3))},
                {"outerChecksum", normalize_lock_checksum(Kernel.elem(entry, 7))}
              ])

            {:ok, identity}
          end
        end
      end
    end
  end

  defp validate_hex_requirement(version, requirement) do
    try do
      if Version.match?(version, requirement),
        do: :ok,
        else: {:error, "Hex version " <> version <> " does not satisfy " <> requirement}
    rescue
      error ->
        {:error, Exception.message(error)}
    end
  end

  defp path_identity(source, checkout, root) do
    declared = source.path
    expanded = Path.expand(declared, root)
    declared_type = Path.type(declared)

    if declared_type == :absolute do
      {:error, "path dependencies must be project-relative"}
    else
      if not inside_root(root, expanded) do
        {:error, "path dependency escapes the Phoenix project"}
      else
        if Path.expand(checkout) != expanded do
          {:error, "resolved checkout does not match the declared path dependency"}
        else
          package_value = Jason.decode!(File.read!(Path.join(checkout, "package.json")))
          version = Map.get(package_value, "version")

          if not Kernel.is_binary(version) do
            {:error, "path dependency package.json has no string version"}
          else
            identity =
              json_object([
                {"name", "live_react"},
                {"sourceKind", "path"},
                {"path", Path.relative_to(expanded, root)},
                {"packageVersion", version}
              ])

            {:ok, identity}
          end
        end
      end
    end
  end

  defp validate_checkout_identity(identity, checkout, opts) do
    if Map.get(identity, "sourceKind") != "git" do
      :ok
    else
      expected = Map.fetch!(identity, "resolvedRevision")
      revision_reader = Keyword.get(opts, :git_revision, fn path -> git_revision(path) end)

      try do
        if String.downcase(revision_reader.(checkout)) == expected,
          do: :ok,
          else: {:error, "dependency checkout HEAD does not match mix.lock"}
      rescue
        error ->
          {:error, "cannot verify dependency checkout: " <> Exception.message(error)}
      end
    end
  end

  defp git_revision(checkout) do
    options = [{:stderr_to_stdout, true}]
    command = System.cmd("git", ["-C", checkout, "rev-parse", "HEAD"], options)

    if elem(command, 1) == 0 do
      String.trim(elem(command, 0))
    else
      Kernel.raise("git rev-parse failed: #{String.trim(elem(command, 0))}")
    end
  end

  defp npm_reference(topology, checkout) do
    physical = HaxePhoenixLiveReact.Host.physical_directory(Path.expand(checkout))
    physical_tag = tag(physical)

    if physical_tag != :ok,
      do:
        {:error,
         "cannot resolve npm LiveReact checkout: " <>
           HaxePhoenixLiveReact.Host.format_path_error(Kernel.elem(physical, 1))},
      else: build_npm_reference(topology, Kernel.elem(physical, 1))
  end

  defp build_npm_reference(topology, absolute_checkout) do
    from_root = Path.relative_to(absolute_checkout, topology.root)

    if not inside_root(topology.root, absolute_checkout) do
      {:error, "npm LiveReact checkout escapes the Phoenix project"}
    else
      from_root_type = Path.type(from_root)

      if from_root_type != :relative do
        {:error, "npm LiveReact path is not project-relative"}
      else
        if from_root == "." do
          {:error, "npm LiveReact checkout cannot be the package root"}
        else
          prefix = if topology.package_root_relative == ".", do: "", else: "../"
          {:ok, "file:" <> prefix <> from_root}
        end
      end
    end
  end

  defp inside_root(root, path) do
    relative = Path.relative_to(path, root)
    relative_type = Path.type(relative)
    relative == "." or (relative_type == :relative and not String.starts_with?(relative, ".."))
  end

  defp normalize_git_repository(repository) do
    normalized = String.trim(repository)
    normalized = Regex.replace(rx("^git://"), normalized, "https://")
    normalized = Regex.replace(rx("^git@github\\.com:"), normalized, "https://github.com/")
    normalized = String.trim_trailing(normalized, "/")
    Regex.replace(rx("\\.git$"), normalized, "")
  end

  defp normalize_lock_checksum(checksum) do
    if Kernel.is_nil(checksum) do
      nil
    else
      if Kernel.is_binary(checksum) do
        value = Kernel.to_string(checksum)

        if Regex.match?(rx_with_options("^[0-9a-f]+$", "i"), value) and
             Kernel.rem(Kernel.byte_size(value), 2) == 0 do
          String.downcase(value)
        else
          options = [{:case, :lower}]
          Base.encode16(checksum, options)
        end
      else
        options = [{:case, :lower}]
        Base.encode16(checksum, options)
      end
    end
  end

  defp read_lock_source(path) do
    result = File.read(path)
    result_tag = tag(result)

    if result_tag == :ok do
      {Kernel.elem(result, 1), true}
    else
      reason = Kernel.elem(result, 1)

      if reason == :enoent do
        {"%{}\n", false}
      else
        Kernel.raise("cannot read #{path}: #{:file.format_error(reason)}")
      end
    end
  end

  defp original_lock_state_for(content, lock, existed) do
    if not existed do
      json_object([{"kind", "missing"}])
    else
      if Kernel.map_size(lock) == 0 do
        if not supported_empty_lock(content) do
          Kernel.raise(
            "mix.lock uses an unsupported empty-map layout. No writes occurred. Run `mix deps.get` to normalize it before enabling LiveReact."
          )
        else
          json_object([{"kind", "empty"}, {"content", content}])
        end
      else
        json_object([{"kind", "populated"}, {"sha256", sha256(content)}])
      end
    end
  end

  defp supported_empty_lock(content) do
    content == "%{}" or content == "%{}\n" or content == "%{\n}" or content == "%{\n}\n"
  end

  defp insert_lock_entry(content, lock, entry) do
    if Map.has_key?(lock, :live_react) do
      Kernel.raise(
        "cannot insert an owned :live_react lock entry over an existing entry. No writes occurred."
      )
    else
      updated =
        if Kernel.map_size(lock) == 0 do
          render_lock(Map.put(lock, :live_react, entry))
        else
          lines = split_lines(content)
          closing = canonical_lock_closing_index(lines)
          insertion = lock_entry_insertion_index(lines, closing, "live_react")
          Enum.join(List.insert_at(lines, insertion, lock_entry_line(:live_react, entry)), "\n")
        end

      expected = Map.put(lock, :live_react, entry)

      if read_lock_content(updated, "planned LiveReact lock") != expected do
        Kernel.raise(
          "could not preserve mix.lock while inserting the LiveReact entry. No writes occurred."
        )
      else
        updated
      end
    end
  end

  defp canonical_lock_closing_index(lines) do
    indexed = Enum.reverse(Enum.with_index(lines))

    index =
      Enum.find_value(indexed, -1, fn entry ->
        line = Kernel.elem(entry, 0)

        if String.trim(line) == "" do
          nil
        else
          Kernel.elem(entry, 1)
        end
      end)

    if index >= 0 and String.trim(Enum.at(lines, index)) == "}" do
      index
    else
      Kernel.raise(
        "mix.lock is not in the canonical multiline map shape. No writes occurred. Run `mix deps.get` to normalize it before enabling LiveReact."
      )
    end
  end

  defp lock_entry_insertion_index(lines, closing, name) do
    entries = []
    pattern = rx("^\\s*\"([^\"]+)\":\\s+")
    _g = 0
    g_value = closing

    entries =
      Enum.reduce(0..(g_value - 1)//1, entries, fn index, entries_acc ->
        match = Regex.run(pattern, Enum.at(lines, index))

        if not Kernel.is_nil(match) and length(match) == 2 do
          Enum.concat(entries_acc, [{Enum.at(match, 1), index}])
        else
          entries_acc
        end
      end)

    if length(entries) == 0 do
      Kernel.raise(
        "mix.lock contains dependencies but not canonical one-entry-per-line lock entries. No writes occurred. Run `mix deps.get` to normalize it before enabling LiveReact."
      )
    else
      _g = 0

      case Enum.reduce_while(entries, :__reflaxe_no_return__, fn entry, _ ->
             if Kernel.>(elem(entry, 0), name),
               do: {:halt, {:__reflaxe_return__, elem(entry, 1)}},
               else: {:cont, :__reflaxe_no_return__}
           end) do
        {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
        _ -> closing
      end
    end
  end

  defp lock_entry_line(name, entry) do
    options = [{:limit, :infinity}]
    "  \"#{Kernel.to_string(name)}\": #{Kernel.inspect(entry, options)},"
  end

  defp remove_lock_entry_line(content, name) do
    lines = split_lines(content)
    pattern = rx("^\\s*\"#{Regex.escape(Kernel.to_string(name))}\":\\s+.*,$")
    indices = []
    _g = 0
    lines_length = length(lines)

    indices =
      Enum.reduce(0..(lines_length - 1)//1, indices, fn index, indices_acc ->
        if Regex.match?(pattern, Enum.at(lines, index)) do
          indices_acc = Enum.concat(indices_acc, [index])
          indices_acc
        else
          indices_acc
        end
      end)

    if length(indices) != 1 do
      Kernel.raise(
        "mix.lock must contain exactly one canonical #{Kernel.to_string(name)} entry line. No writes occurred."
      )
    else
      Enum.join(List.delete_at(lines, Enum.at(indices, 0)), "\n")
    end
  end

  defp sha256(content) do
    options = [{:case, :lower}]
    Base.encode16(:crypto.hash(:sha256, content), options)
  end

  defp read_lock_content(content, label) do
    directory = Path.join(System.tmp_dir!(), "reflaxe_live_react_lock_read")
    File.mkdir_p!(directory)
    id = System.unique_integer([:positive, :monotonic])
    path = Path.join(directory, "#{Kernel.to_string(id)}.lock")

    try do
      File.write!(path, content, [:write, :exclusive])
      result = Mix.Dep.Lock.read(path)
      File.rm(path)
      result
    rescue
      error ->
        File.rm(path)
        Kernel.raise("cannot parse " <> label <> ": " <> Exception.message(error))
    end
  end

  defp render_lock(lock) do
    entries = Map.to_list(lock)
    entries = Enum.sort_by(entries, fn entry -> Kernel.to_string(elem(entry, 0)) end)

    body =
      Enum.map_join(entries, "\n", fn entry -> lock_entry_line(elem(entry, 0), elem(entry, 1)) end)

    Enum.join(["%{", body, "}", ""], "\n")
  end

  defp resolve_with_loaded_mix(context) do
    project_file = Mix.Project.project_file()

    if Kernel.is_nil(project_file) or Path.dirname(Path.expand(project_file)) != context.root do
      Kernel.raise("dependency resolution must run from the target Mix project root")
    else
      project_config = Mix.Project.config()
      app_value = Keyword.get(project_config, :app, nil)

      if not Kernel.is_atom(app_value) do
        Kernel.raise(
          "dependency resolution requires the loaded Mix project to declare one :app atom"
        )
      else
        app = app_value

        directory =
          Path.join(
            System.tmp_dir!(),
            "reflaxe_live_react_resolve_#{Kernel.to_string(System.unique_integer([:positive, :monotonic]))}"
          )

        File.mkdir!(directory)
        lockfile = Path.join(directory, "mix.lock")
        input_file = Path.join(directory, "input.etf")
        output_file = Path.join(directory, "output.etf")
        File.write!(lockfile, context.current_lock_content)
        dependencies = context.dependencies

        found =
          Enum.any?(dependencies, fn dependency ->
            name = dependency_name(dependency)
            name == :live_react
          end)

        dependencies =
          if not found do
            Enum.concat([context.dependency], dependencies)
          else
            dependencies
          end

        input = Map.new()

        input =
          input
          |> Map.put("app", app)
          |> Map.put("root", context.root)
          |> Map.put("dependencies", dependencies)
          |> Map.put("lockfile", lockfile)
          |> Map.put("depsPath", Path.join(context.root, "deps"))
          |> Map.put("dependencyPath", context.dependency_path)

        File.write!(input_file, :erlang.term_to_binary(input), [:write, :exclusive])
        ebin = Application.app_dir(:reflaxe_elixir, "ebin")

        options = [
          {:env,
           [
             {"REFLAXE_LIVE_REACT_RESOLVER_INPUT", input_file},
             {"REFLAXE_LIVE_REACT_RESOLVER_OUTPUT", output_file}
           ]},
          {:stderr_to_stdout, true}
        ]

        worker_entry = "HaxePhoenixLiveReact.DependencyWorker.run()"

        command =
          try do
            System.cmd("elixir", ["-pa", ebin, "-e", worker_entry], options)
          rescue
            error ->
              cleanup_resolution(lockfile, input_file, output_file, directory)

              Kernel.raise(
                "could not start the isolated stock LiveReact dependency resolver: " <>
                  Exception.message(error) <>
                  ". No tracked integration files were written; ignored dependency downloads may remain in deps/."
              )
          end

        if elem(command, 1) != 0 do
          cleanup_resolution(lockfile, input_file, output_file, directory)

          Kernel.raise(
            "could not resolve the checked stock LiveReact dependency in an isolated Mix project (exit #{Kernel.to_string(elem(command, 1))}):\n#{elem(command, 0)}\nNo tracked integration files were written; ignored dependency downloads may remain in deps/."
          )
        else
          if not File.regular?(output_file) do
            cleanup_resolution(lockfile, input_file, output_file, directory)

            Kernel.raise(
              "the isolated stock LiveReact dependency resolver exited without a result. No tracked integration files were written."
            )
          else
            result = :erlang.binary_to_term(File.read!(output_file))
            cleanup_resolution(lockfile, input_file, output_file, directory)
            result
          end
        end
      end
    end
  end

  defp cleanup_resolution(lockfile, input_file, output_file, directory) do
    Enum.each([lockfile, input_file, output_file], fn path -> File.rm(path) end)
    File.rmdir(directory)
  end

  defp manifest_managed_bool(manifest, key) do
    managed = Map.fetch!(manifest, "managed")
    Map.fetch!(managed, key)
  end

  defp manifest_restores(manifest) do
    managed = Map.fetch!(manifest, "managed")
    Map.fetch!(managed, "restores")
  end

  defp split_lines(content) do
    options = [{:trim, false}]
    String.split(content, "\n", options)
  end

  defp json_object(entries) do
    value = Map.new()
    _g = 0

    value =
      Enum.reduce(entries, value, fn entry, value_acc ->
        Map.put(value_acc, elem(entry, 0), elem(entry, 1))
      end)

    value
  end

  defp tag(value) do
    if Kernel.is_tuple(value) do
      Kernel.elem(value, 0)
    else
      value
    end
  end

  defp rx(pattern) do
    Regex.compile!(pattern)
  end

  defp rx_with_options(pattern, options) do
    Regex.compile!(pattern, options)
  end
end

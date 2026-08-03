defmodule HaxePhoenixLiveReact.Package do
  def plan(topology, dependency, existing_manifest, mix_dependency_paths) do
    content = File.read!(topology.package_json)
    decoded = Jason.decode(content)
    decoded_tag = tag(decoded)

    if decoded_tag != :ok do
      Kernel.raise(
        "cannot parse #{topology.package_json}: #{Exception.message(Kernel.elem(decoded, 1))}"
      )
    else
      value = Kernel.elem(decoded, 1)

      if not Kernel.is_map(value) do
        Kernel.raise("#{topology.package_json} must contain a JSON object. No writes occurred.")
      else
        browser_dependencies = resolved_browser_dependencies(topology, mix_dependency_paths)
        validate_browser_dependencies(topology, value, browser_dependencies)

        existing_owned =
          if Kernel.is_nil(existing_manifest) do
            MapSet.new()
          else
            MapSet.new(manifest_package_keys(existing_manifest))
          end

        initial = %{json: value, owned: existing_owned}
        specs = managed_values(dependency.npm_reference, browser_dependencies)

        accumulated =
          Enum.reduce(specs, initial, fn spec, state ->
            dotted = Enum.join(spec.path, ".")
            fetched = fetch_json_path(state.json, spec.path, 0)
            fetched_tag = tag(fetched)

            if fetched_tag == :error do
              %{
                json: put_json_path(state.json, spec.path, 0, spec.expected),
                owned: MapSet.put(state.owned, dotted)
              }
            else
              actual = Kernel.elem(fetched, 1)

              if actual == spec.expected do
                state
              else
                if not MapSet.member?(state.owned, dotted) and
                     Enum.member?(spec.accepted_existing, actual) do
                  state
                else
                  Kernel.raise(
                    topology.package_json <>
                      " " <>
                      dotted <>
                      " conflicts with the managed value. Found " <>
                      Kernel.inspect(actual) <>
                      ", expected " <>
                      Kernel.inspect(spec.expected) <>
                      ". No writes occurred. Preserve the existing value and use manual integration, or remove it before retrying."
                  )
                end
              end
            end
          end)

        options = [{:pretty, true}]

        %{
          content: Enum.join([Jason.encode!(accumulated.json, options), ""], "\n"),
          owned_keys: Enum.sort(MapSet.to_list(accumulated.owned)),
          owned_values: owned_package_values(accumulated.json, accumulated.owned, specs)
        }
      end
    end
  end

  def remove(topology, manifest) do
    value = Jason.decode!(File.read!(topology.package_json))

    if not Kernel.is_map(value) do
      Kernel.raise("#{topology.package_json} must contain a JSON object. No writes occurred.")
    else
      owned = MapSet.new(manifest_package_keys(manifest))
      hand_usage = hand_owned_browser_packages(topology)
      npm_reference = Map.fetch!(manifest, "npmReference")
      package_values = manifest_package_values(manifest)
      initial = %{json: value, retained: []}

      accumulated =
        Enum.reduce(legacy_managed_values(npm_reference), initial, fn spec, state ->
          dotted = Enum.join(spec.path, ".")

          if not MapSet.member?(owned, dotted) do
            state
          else
            fetched = fetch_json_path(state.json, spec.path, 0)
            fetched_tag = tag(fetched)

            if fetched_tag == :error do
              state
            else
              actual = Kernel.elem(fetched, 1)
              expected = Map.get(package_values, dotted, spec.expected)

              if actual != expected do
                Kernel.raise(
                  "cannot remove package.json " <>
                    dotted <>
                    ": owned value drifted to " <>
                    Kernel.inspect(actual) <> ". No writes occurred."
                )
              else
                package_name = Enum.at(spec.path, length(spec.path) - 1)

                if MapSet.member?(hand_usage, package_name),
                  do: %{json: state.json, retained: Enum.concat([dotted], state.retained)},
                  else: %{
                    json: delete_json_path(state.json, spec.path, 0),
                    retained: state.retained
                  }
              end
            end
          end
        end)

      options = [{:pretty, true}]

      %{
        content: Enum.join([Jason.encode!(accumulated.json, options), ""], "\n"),
        retained_keys: Enum.sort(accumulated.retained)
      }
    end
  end

  defp legacy_managed_values(npm_reference) do
    managed_values(npm_reference, [
      %{name: "phoenix", version: "1.7.24", file_reference: nil},
      %{name: "phoenix_html", version: "4.3.0", file_reference: nil},
      %{name: "phoenix_live_view", version: "0.20.17", file_reference: nil}
    ])
  end

  defp owned_package_values(json, owned, specs) do
    Enum.reduce(specs, Map.new(), fn spec, values ->
      dotted = Enum.join(spec.path, ".")

      if not MapSet.member?(owned, dotted) do
        values
      else
        fetched = fetch_json_path(json, spec.path, 0)

        if (
             this1 = tag(fetched)
             this1 == :error
           ) do
          values
        else
          Map.put(values, dotted, Kernel.elem(fetched, 1))
        end
      end
    end)
  end

  defp managed_values(npm_reference, browser_dependencies) do
    phoenix = Enum.at(browser_dependencies, 0)
    phoenix_html = Enum.at(browser_dependencies, 1)
    live_view = Enum.at(browser_dependencies, 2)

    [
      %{path: ["private"], expected: true, accepted_existing: []},
      %{path: ["type"], expected: "module", accepted_existing: []},
      %{
        path: ["scripts", "assets:dev"],
        expected: "vite --host 127.0.0.1 --port 5173 --strictPort --logLevel warn",
        accepted_existing: []
      },
      %{path: ["scripts", "assets:build"], expected: "vite build", accepted_existing: []},
      %{path: ["dependencies", "live_react"], expected: npm_reference, accepted_existing: []},
      %{
        path: ["dependencies", "phoenix"],
        expected: phoenix.version,
        accepted_existing: accepted_file_reference(phoenix)
      },
      %{
        path: ["dependencies", "phoenix_html"],
        expected: phoenix_html.version,
        accepted_existing: accepted_file_reference(phoenix_html)
      },
      %{
        path: ["dependencies", "phoenix_live_view"],
        expected: live_view.version,
        accepted_existing: accepted_file_reference(live_view)
      },
      %{path: ["dependencies", "react"], expected: "19.1.0", accepted_existing: []},
      %{path: ["dependencies", "react-dom"], expected: "19.1.0", accepted_existing: []},
      %{
        path: ["devDependencies", "@vitejs/plugin-react"],
        expected: "4.5.2",
        accepted_existing: []
      },
      %{path: ["devDependencies", "vite"], expected: "7.2.7", accepted_existing: []}
    ]
  end

  defp resolved_browser_dependencies(topology, paths) do
    Enum.map(["phoenix", "phoenix_html", "phoenix_live_view"], fn name ->
      checkout = dependency_path(paths, name)
      package_path = Path.join(checkout, "package.json")

      if not File.regular?(package_path) do
        Kernel.raise(
          "cannot verify the resolved Mix checkout for " <>
            name <>
            ": " <>
            package_path <> " is missing. Run `mix deps.get`, then retry. No writes occurred."
        )
      else
        package_json = Jason.decode!(File.read!(package_path))
        package_name = Map.get(package_json, "name")
        version = Map.get(package_json, "version")

        if package_name != name or not Kernel.is_binary(version) do
          Kernel.raise(
            package_path <>
              " must identify npm package " <>
              name <> " with a string version. No writes occurred."
          )
        else
          %{
            name: name,
            version: version,
            file_reference: project_local_file_reference(topology, checkout)
          }
        end
      end
    end)
  end

  defp dependency_path(paths, name) do
    fetched = Map.fetch(paths, name)

    fetched =
      if (
           this1 = tag(fetched)
           this1 == :error
         ) do
        app =
          case name do
            "phoenix" -> :phoenix
            "phoenix_html" -> :phoenix_html
            _ -> :phoenix_live_view
          end

        Map.fetch(paths, app)
      else
        fetched
      end

    if (
         this1 = tag(fetched)
         this1 == :error
       ) do
      Kernel.raise(
        "cannot find the resolved Mix checkout for #{name}. Run `mix deps.get`, then retry. No writes occurred."
      )
    else
      Path.expand(Kernel.elem(fetched, 1))
    end
  end

  defp project_local_file_reference(topology, checkout) do
    relative_to_root = Path.relative_to(checkout, topology.root)

    if (fn ->
          this1 = Path.type(relative_to_root)
          this1 == :absolute
        end).() or relative_to_root == ".." or String.starts_with?(relative_to_root, "../") do
      nil
    else
      parents =
        if topology.package_root_relative == "." do
          []
        else
          Enum.map(Path.split(topology.package_root_relative), fn _ -> ".." end)
        end

      relative = Path.join(Enum.concat(parents, Path.split(relative_to_root)))
      "file:#{String.replace(relative, "\\", "/")}"
    end
  end

  defp accepted_file_reference(dependency) do
    if Kernel.is_nil(dependency.file_reference), do: [], else: [dependency.file_reference]
  end

  defp validate_browser_dependencies(topology, package_json, dependencies) do
    Enum.each(dependencies, fn dependency ->
      fetched = fetch_json_path(package_json, ["dependencies", dependency.name], 0)

      if (
           this1 = tag(fetched)
           this1 != :error
         ) do
        actual = Kernel.elem(fetched, 1)

        matches_file_reference =
          not Kernel.is_nil(dependency.file_reference) and actual == dependency.file_reference

        if actual != dependency.version and not matches_file_reference do
          repair = "Use " <> Kernel.inspect(dependency.version)

          repair =
            if not Kernel.is_nil(dependency.file_reference) do
              repair <> " or " <> Kernel.inspect(dependency.file_reference)
            else
              repair
            end

          Kernel.raise(
            dependency.name <>
              " browser package is " <>
              Kernel.to_string(actual) <>
              ", but the resolved Mix checkout is " <>
              dependency.version <>
              ". " <>
              repair <>
              " in " <>
              topology.package_json <> ", run npm install, then retry. No writes occurred."
          )
        end
      end
    end)
  end

  defp fetch_json_path(json, path, index) do
    if not Kernel.is_map(json) do
      Kernel.raise(
        "package.json #{Enum.at(path, index - 1)} must be an object, found #{Kernel.inspect(json)}. No writes occurred."
      )
    else
      fetched = Map.fetch(json, Enum.at(path, index))
      fetched_tag = tag(fetched)

      if fetched_tag == :error do
        :error
      else
        value = Kernel.elem(fetched, 1)

        if index == length(path) - 1 do
          {:ok, value}
        else
          fetch_json_path(value, path, index + 1)
        end
      end
    end
  end

  defp put_json_path(json, path, index, value) do
    key = Enum.at(path, index)

    if index == length(path) - 1 do
      Map.put(json, key, value)
    else
      child = Map.get(json, key, Map.new())

      if not Kernel.is_map(child) do
        Kernel.raise(
          "package.json #{key} must be an object, found #{Kernel.inspect(child)}. No writes occurred."
        )
      else
        Map.put(json, key, put_json_path(child, path, index + 1, value))
      end
    end
  end

  defp delete_json_path(json, path, index) do
    key = Enum.at(path, index)

    if index == length(path) - 1 do
      Map.delete(json, key)
    else
      fetched = Map.fetch(json, key)
      fetched_tag = tag(fetched)

      if fetched_tag == :error do
        json
      else
        child = Kernel.elem(fetched, 1)

        if not Kernel.is_map(child) do
          json
        else
          updated = delete_json_path(child, path, index + 1)

          if Kernel.map_size(updated) == 0 do
            Map.delete(json, key)
          else
            Map.put(json, key, updated)
          end
        end
      end
    end
  end

  defp hand_owned_browser_packages(topology) do
    managed = MapSet.new([topology.vite_config, topology.hooks_file, topology.registry_file])

    globs = [
      Path.join(topology.root, "assets/**/*.{js,jsx,ts,tsx,mjs,cjs}"),
      Path.join(topology.package_root, "*.{js,jsx,ts,tsx,mjs,cjs}")
    ]

    files = Enum.uniq(Enum.flat_map(globs, fn pattern -> Path.wildcard(pattern) end))

    files =
      Enum.filter(files, fn path ->
        not MapSet.member?(managed, path) and not String.contains?(path, "/node_modules/")
      end)

    imported =
      Enum.reduce(files, MapSet.new(), fn path, packages ->
        source = File.read!(path)
        updated = maybe_mark_package(packages, source, "live_react")

        updated =
          updated
          |> maybe_mark_package(source, "react")
          |> maybe_mark_package(source, "react-dom")
          |> maybe_mark_package(source, "vite")

        maybe_mark_package(updated, source, "@vitejs/plugin-react")
      end)

    retain_runtime_peers(imported)
  end

  defp retain_runtime_peers(packages) do
    if not MapSet.member?(packages, "live_react") do
      packages
    else
      MapSet.put(MapSet.put(packages, "react"), "react-dom")
    end
  end

  defp maybe_mark_package(packages, source, package_name) do
    pattern =
      Regex.compile!(
        "(?:from\\s+|import\\s*\\(?\\s*)[\"']#{Regex.escape(package_name)}(?:[\\/\"'])"
      )

    if Regex.match?(pattern, source) do
      MapSet.put(packages, package_name)
    else
      packages
    end
  end

  defp manifest_package_keys(manifest) do
    managed = Map.fetch!(manifest, "managed")
    Map.fetch!(managed, "packageKeys")
  end

  defp manifest_package_values(manifest) do
    managed = Map.fetch!(manifest, "managed")
    Map.get(managed, "packageValues", Map.new())
  end

  defp tag(value) do
    if Kernel.is_tuple(value) do
      Kernel.elem(value, 0)
    else
      value
    end
  end
end

defmodule HaxePhoenixLiveReact.Package do
  def plan(topology, dependency, existing_manifest) do
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
        existing_owned =
          if Kernel.is_nil(existing_manifest) do
            MapSet.new()
          else
            MapSet.new(manifest_package_keys(existing_manifest))
          end

        initial = %{json: value, owned: existing_owned}

        accumulated =
          Enum.reduce(managed_values(topology, dependency.npm_reference), initial, fn spec,
                                                                                      state ->
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
          owned_keys: Enum.sort(MapSet.to_list(accumulated.owned))
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
      initial = %{json: value, retained: []}

      accumulated =
        Enum.reduce(managed_values(topology, npm_reference), initial, fn spec, state ->
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

              if actual != spec.expected do
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

  defp managed_values(topology, npm_reference) do
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
        expected: "1.7.24",
        accepted_existing: [mix_checkout_reference(topology, "phoenix")]
      },
      %{
        path: ["dependencies", "phoenix_html"],
        expected: "4.3.0",
        accepted_existing: [mix_checkout_reference(topology, "phoenix_html")]
      },
      %{
        path: ["dependencies", "phoenix_live_view"],
        expected: "0.20.17",
        accepted_existing: [mix_checkout_reference(topology, "phoenix_live_view")]
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

  defp mix_checkout_reference(topology, package_name) do
    parents =
      if topology.package_root_relative == "." do
        []
      else
        Enum.map(Path.split(topology.package_root_relative), fn _ -> ".." end)
      end

    relative = Path.join(Enum.concat(parents, ["deps", package_name]))
    "file:#{String.replace(relative, "\\", "/")}"
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

  defp tag(value) do
    if Kernel.is_tuple(value) do
      Kernel.elem(value, 0)
    else
      value
    end
  end
end

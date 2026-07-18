defmodule HaxePhoenixLiveReact.SourcePatcher do
  def marker_specs() do
    [
      {"mix.exs", "BEGIN reflaxe_elixir live_react_dependency",
       "END reflaxe_elixir live_react_dependency"},
      {"mix.exs", "BEGIN reflaxe_elixir live_react_assets_setup",
       "END reflaxe_elixir live_react_assets_setup"},
      {"mix.exs", "BEGIN reflaxe_elixir live_react_assets_build",
       "END reflaxe_elixir live_react_assets_build"},
      {"mix.exs", "BEGIN reflaxe_elixir live_react_assets_deploy",
       "END reflaxe_elixir live_react_assets_deploy"},
      {"config/config.exs", "BEGIN reflaxe_elixir live_react_config",
       "END reflaxe_elixir live_react_config"},
      {"config/dev.exs", "BEGIN reflaxe_elixir live_react_vite_watcher",
       "END reflaxe_elixir live_react_vite_watcher"},
      {"config/dev.exs", "BEGIN reflaxe_elixir live_react_vite_host",
       "END reflaxe_elixir live_react_vite_host"},
      {"assets/js/app.js", "BEGIN reflaxe_elixir live_react_import",
       "END reflaxe_elixir live_react_import"},
      {"assets/js/app.js", "BEGIN reflaxe_elixir live_react_hooks",
       "END reflaxe_elixir live_react_hooks"},
      {"assets/js/app.js", "BEGIN reflaxe_elixir live_react_window_hooks",
       "END reflaxe_elixir live_react_window_hooks"},
      {"assets/js/app.js", "BEGIN reflaxe_elixir live_react_hooks_property",
       "END reflaxe_elixir live_react_hooks_property"},
      {"root_layout", "BEGIN reflaxe_elixir live_react_vite_assets",
       "END reflaxe_elixir live_react_vite_assets"}
    ]
  end

  def managed_markers(topology) do
    markers =
      Enum.map(marker_specs(), fn spec ->
        source_path = Kernel.elem(spec, 0)

        path =
          if source_path == "root_layout" do
            Path.relative_to(topology.root_layout, topology.root)
          else
            source_path
          end

        marker = Map.new()
        marker = marker |> Map.put("path", path) |> Map.put("begin", Kernel.elem(spec, 1))
        Map.put(marker, "end", Kernel.elem(spec, 2))
      end)

    Enum.sort_by(markers, fn marker ->
      Map.get(marker, "path") <> "\n" <> Map.get(marker, "begin")
    end)
  end

  def patch_mix_exs(content, topology, dependency, restores) do
    validate_file_markers(content, "mix.exs", "mix.exs")
    updated = patch_live_react_dependency(content, dependency)

    setup =
      patch_asset_alias(
        updated,
        "assets.setup",
        HaxePhoenixLiveReact.Core.package_command(
          topology.package_root_relative,
          "npm install --no-audit --no-fund"
        ),
        "BEGIN reflaxe_elixir live_react_assets_setup",
        "END reflaxe_elixir live_react_assets_setup",
        "mix.assets.setup",
        restores
      )

    build =
      patch_asset_alias(
        elem(setup, 0),
        "assets.build",
        HaxePhoenixLiveReact.Core.package_command(
          topology.package_root_relative,
          "npm run assets:build"
        ),
        "BEGIN reflaxe_elixir live_react_assets_build",
        "END reflaxe_elixir live_react_assets_build",
        "mix.assets.build",
        elem(setup, 1)
      )

    patch_asset_alias(
      elem(build, 0),
      "assets.deploy",
      HaxePhoenixLiveReact.Core.package_command(
        topology.package_root_relative,
        "npm run assets:build"
      ),
      "BEGIN reflaxe_elixir live_react_assets_deploy",
      "END reflaxe_elixir live_react_assets_deploy",
      "mix.assets.deploy",
      elem(build, 1)
    )
  end

  def patch_config_exs(content, restores) do
    begin_token = "BEGIN reflaxe_elixir live_react_config"
    end_token = "END reflaxe_elixir live_react_config"
    desired = HaxePhoenixLiveReact.Core.live_react_config_lines()
    validate_marker_pairs(content, [{begin_token, end_token}], "config/config.exs")

    replaced =
      HaxeProjectPatch.replace_marker_block_lines(content, begin_token, end_token, desired)

    replaced_tag = tag(replaced)

    if replaced_tag == :ok do
      require_restore_key(restores, "config.trailingWhitespace")
      {Kernel.elem(replaced, 1), restores}
    else
      if replaced_tag == :error do
        Kernel.raise(
          "config/config.exs has a malformed LiveReact marker (#{Kernel.inspect(Kernel.elem(replaced, 1))}). No writes occurred."
        )
      else
        if Regex.match?(rx_with_options("^\\s*config\\s+:live_react\\b", "m"), content) do
          Kernel.raise(
            "config/config.exs already contains unowned LiveReact configuration. No writes occurred. Manual integration is required."
          )
        else
          {append_marker_block(content, begin_token, end_token, desired, "", "#"),
           put_restore(restores, "config.trailingWhitespace", trailing_whitespace(content))}
        end
      end
    end
  end

  def patch_dev_exs(content, topology, restores) do
    validate_file_markers(content, "config/dev.exs", "config/dev.exs")
    begin_watcher = "BEGIN reflaxe_elixir live_react_vite_watcher"
    end_watcher = "END reflaxe_elixir live_react_vite_watcher"
    watcher_line = HaxePhoenixLiveReact.Core.vite_watcher_line(topology.package_root_relative)

    watcher =
      HaxeProjectPatch.replace_marker_block_lines(content, begin_watcher, end_watcher, [
        watcher_line
      ])

    watcher_tag = tag(watcher)
    watcher_result = nil

    watcher_result =
      cond do
        watcher_tag == :ok ->
          watcher_result = {Kernel.elem(watcher, 1), restores}
          watcher_result

        watcher_tag == :error ->
          Kernel.raise(
            "config/dev.exs has a malformed LiveReact Vite watcher marker (" <>
              Kernel.inspect(Kernel.elem(watcher, 1)) <> "). No writes occurred."
          )

          watcher_result

        true ->
          watcher_result = insert_vite_watcher(content, watcher_line, restores)
          watcher_result
      end

    begin_host = "BEGIN reflaxe_elixir live_react_vite_host"
    end_host = "END reflaxe_elixir live_react_vite_host"
    host_lines = HaxePhoenixLiveReact.Core.live_react_dev_config_lines()

    host =
      HaxeProjectPatch.replace_marker_block_lines(
        elem(watcher_result, 0),
        begin_host,
        end_host,
        host_lines
      )

    host_tag = tag(host)

    if host_tag == :ok do
      require_restore_key(elem(watcher_result, 1), "dev.trailingWhitespace")
      {Kernel.elem(host, 1), elem(watcher_result, 1)}
    else
      if host_tag == :error do
        Kernel.raise(
          "config/dev.exs has a malformed LiveReact host marker (#{Kernel.inspect(Kernel.elem(host, 1))}). No writes occurred."
        )
      else
        if Regex.match?(
             rx_with_options("^\\s*config\\s+:live_react\\b", "m"),
             elem(watcher_result, 0)
           ) do
          Kernel.raise(
            "config/dev.exs already contains unowned LiveReact configuration. No writes occurred. Manual integration is required."
          )
        else
          {append_marker_block(
             elem(watcher_result, 0),
             begin_host,
             end_host,
             host_lines,
             "",
             "#"
           ),
           put_restore(
             elem(watcher_result, 1),
             "dev.trailingWhitespace",
             trailing_whitespace(elem(watcher_result, 0))
           )}
        end
      end
    end
  end

  def patch_app_js(content, restores) do
    validate_file_markers(content, "assets/js/app.js", "assets/js/app.js")
    patch_app_js_hooks(patch_app_js_import(content), restores)
  end

  def patch_root_layout(content, restores) do
    begin_token = "BEGIN reflaxe_elixir live_react_vite_assets"
    end_token = "END reflaxe_elixir live_react_vite_assets"
    restore_key = "layout.appScript"
    validate_marker_pairs(content, [{begin_token, end_token}], "Phoenix root layout")
    existing_original = Map.get(restores, restore_key)

    desired =
      if Kernel.is_nil(existing_original), do: [], else: root_asset_inner_lines(existing_original)

    replaced =
      HaxeProjectPatch.replace_marker_block_lines(content, begin_token, end_token, desired)

    replaced_tag = tag(replaced)

    if replaced_tag == :ok do
      if Kernel.is_nil(existing_original) do
        Kernel.raise(
          "phoenixhx-live-react.json is missing the original root-layout app script needed for recovery. No writes occurred."
        )
      else
        {Kernel.elem(replaced, 1), restores}
      end
    else
      if replaced_tag == :error do
        Kernel.raise(
          "Phoenix root layout has a malformed LiveReact assets marker (#{Kernel.inspect(Kernel.elem(replaced, 1))}). No writes occurred."
        )
      else
        if String.contains?(content, "LiveReact.Reload.vite_assets") do
          Kernel.raise(
            "Phoenix root layout already contains an unowned LiveReact Vite asset wrapper. No writes occurred. Manual integration is required."
          )
        else
          script = find_root_app_script(content)
          next_restores = put_restore(restores, restore_key, script.original)
          lines = split_lines(content)

          block =
            marker_lines_with_suffix(
              begin_token,
              end_token,
              root_asset_inner_lines(script.original),
              script.indent,
              "<%!--",
              "--%>"
            )

          updated =
            replace_line_range(
              lines,
              script.start_index,
              script.end_index,
              Enum.join(block, "\n")
            )

          {Enum.join(updated, "\n"), next_restores}
        end
      end
    end
  end

  def remove_mix_wiring(content, manifest, topology, restores, retain_live_react) do
    managed = map_get_term(manifest, "managed")
    dependency_owned = map_get(managed, "dependencyOwned")

    updated =
      cond do
        dependency_owned and retain_live_react ->
          unwrap_owned_marker(
            content,
            "BEGIN reflaxe_elixir live_react_dependency",
            "END reflaxe_elixir live_react_dependency",
            HaxePhoenixLiveReact.Core.live_react_dependency_lines(),
            "mix.exs LiveReact dependency"
          )

        dependency_owned ->
          remove_inserted_dependency_marker(
            content,
            "BEGIN reflaxe_elixir live_react_dependency",
            "END reflaxe_elixir live_react_dependency",
            HaxePhoenixLiveReact.Core.live_react_dependency_lines(),
            "mix.exs LiveReact dependency"
          )

        true ->
          content
      end

    updated =
      updated
      |> restore_owned_marker(
        "BEGIN reflaxe_elixir live_react_assets_setup",
        "END reflaxe_elixir live_react_assets_setup",
        desired_asset_alias_lines(
          "assets.setup",
          HaxePhoenixLiveReact.Core.package_command(
            topology.package_root_relative,
            "npm install --no-audit --no-fund"
          ),
          map_get_nullable_string(restores, "mix.assets.setup")
        ),
        map_get_term(restores, "mix.assets.setup"),
        "mix.exs assets.setup"
      )
      |> restore_owned_marker(
        "BEGIN reflaxe_elixir live_react_assets_build",
        "END reflaxe_elixir live_react_assets_build",
        desired_asset_alias_lines(
          "assets.build",
          HaxePhoenixLiveReact.Core.package_command(
            topology.package_root_relative,
            "npm run assets:build"
          ),
          map_get_nullable_string(restores, "mix.assets.build")
        ),
        map_get_term(restores, "mix.assets.build"),
        "mix.exs assets.build"
      )

    restore_owned_marker(
      updated,
      "BEGIN reflaxe_elixir live_react_assets_deploy",
      "END reflaxe_elixir live_react_assets_deploy",
      desired_asset_alias_lines(
        "assets.deploy",
        HaxePhoenixLiveReact.Core.package_command(
          topology.package_root_relative,
          "npm run assets:build"
        ),
        map_get_nullable_string(restores, "mix.assets.deploy")
      ),
      map_get_term(restores, "mix.assets.deploy"),
      "mix.exs assets.deploy"
    )
  end

  def remove_config_wiring(content, restores) do
    remove_appended_owned_marker(
      content,
      "BEGIN reflaxe_elixir live_react_config",
      "END reflaxe_elixir live_react_config",
      HaxePhoenixLiveReact.Core.live_react_config_lines(),
      map_get_term(restores, "config.trailingWhitespace"),
      "config/config.exs LiveReact config"
    )
  end

  def remove_dev_wiring(content, topology, restores) do
    watcher =
      marker_inner_lines(
        content,
        "BEGIN reflaxe_elixir live_react_vite_watcher",
        "END reflaxe_elixir live_react_vite_watcher",
        "config/dev.exs Vite watcher"
      )

    if not same_array(watcher, [
         HaxePhoenixLiveReact.Core.vite_watcher_line(topology.package_root_relative)
       ]) do
      Kernel.raise("config/dev.exs LiveReact Vite watcher drifted. No writes occurred.")
    else
      updated =
        restore_owned_marker(
          content,
          "BEGIN reflaxe_elixir live_react_vite_watcher",
          "END reflaxe_elixir live_react_vite_watcher",
          watcher,
          map_get_term(restores, "dev.esbuildWatcher"),
          "config/dev.exs Vite watcher"
        )

      remove_appended_owned_marker(
        updated,
        "BEGIN reflaxe_elixir live_react_vite_host",
        "END reflaxe_elixir live_react_vite_host",
        HaxePhoenixLiveReact.Core.live_react_dev_config_lines(),
        map_get_term(restores, "dev.trailingWhitespace"),
        "config/dev.exs LiveReact host"
      )
    end
  end

  def remove_app_js_wiring(content, restores) do
    updated =
      restore_owned_marker(
        content,
        "BEGIN reflaxe_elixir live_react_import",
        "END reflaxe_elixir live_react_import",
        HaxePhoenixLiveReact.Core.live_react_import_lines(),
        nil,
        "assets/js/app.js LiveReact import"
      )

    declared =
      marker_presence(
        updated,
        "BEGIN reflaxe_elixir live_react_hooks",
        "END reflaxe_elixir live_react_hooks"
      )

    window =
      marker_presence(
        updated,
        "BEGIN reflaxe_elixir live_react_window_hooks",
        "END reflaxe_elixir live_react_window_hooks"
      )

    if declared == :present and window == :missing do
      restore_owned_marker(
        updated,
        "BEGIN reflaxe_elixir live_react_hooks",
        "END reflaxe_elixir live_react_hooks",
        HaxePhoenixLiveReact.Core.declared_hooks_lines(),
        nil,
        "assets/js/app.js declared hooks"
      )
    else
      if declared == :missing and window == :present do
        updated =
          restore_owned_marker(
            updated,
            "BEGIN reflaxe_elixir live_react_window_hooks",
            "END reflaxe_elixir live_react_window_hooks",
            HaxePhoenixLiveReact.Core.window_hooks_lines(),
            nil,
            "assets/js/app.js window hooks"
          )

        remove_hooks_property(updated, restores)
      else
        Kernel.raise(
          "assets/js/app.js must contain exactly one owned LiveReact hook strategy. No writes occurred."
        )
      end
    end
  end

  def remove_root_layout_wiring(content, restores) do
    original = Map.get(restores, "layout.appScript")

    if Kernel.is_nil(original) do
      Kernel.raise(
        "phoenixhx-live-react.json is missing the original root-layout script. No writes occurred."
      )
    else
      restore_owned_marker(
        content,
        "BEGIN reflaxe_elixir live_react_vite_assets",
        "END reflaxe_elixir live_react_vite_assets",
        root_asset_inner_lines(original),
        original,
        "Phoenix root layout LiveReact assets"
      )
    end
  end

  def put_restore(restores, key, value) do
    fetched = Map.fetch(restores, key)
    fetched_tag = tag(fetched)

    if fetched_tag == :error do
      Map.put(restores, key, value)
    else
      existing = Kernel.elem(fetched, 1)

      if existing == value do
        restores
      else
        Kernel.raise(
          "phoenixhx-live-react.json restore metadata for #{key} changed from #{Kernel.inspect(existing)} to #{Kernel.inspect(value)}. No writes occurred."
        )
      end
    end
  end

  def require_restore_key(restores, key) do
    if not Map.has_key?(restores, key) do
      Kernel.raise(
        "phoenixhx-live-react.json is missing #{key} restore metadata. No writes occurred."
      )
    end
  end

  defp patch_live_react_dependency(content, dependency) do
    pattern = rx("\\{\\s*:live_react\\b")

    if not dependency.owned do
      occurrences = length(Regex.scan(pattern, content))

      if occurrences != 1 do
        Kernel.raise(
          "mix.exs must contain exactly one hand-owned :live_react dependency; found #{Kernel.to_string(occurrences)}. No writes occurred."
        )
      else
        content
      end
    else
      begin_token = "BEGIN reflaxe_elixir live_react_dependency"
      end_token = "END reflaxe_elixir live_react_dependency"
      desired = HaxePhoenixLiveReact.Core.live_react_dependency_lines()

      replaced =
        HaxeProjectPatch.replace_marker_block_lines(content, begin_token, end_token, desired)

      replaced_tag = tag(replaced)

      if replaced_tag == :ok do
        Kernel.elem(replaced, 1)
      else
        if replaced_tag == :error do
          Kernel.raise(
            "mix.exs has a malformed LiveReact dependency marker (#{Kernel.inspect(Kernel.elem(replaced, 1))}). No writes occurred."
          )
        else
          if Regex.match?(pattern, content) do
            Kernel.raise(
              "mix.exs contains an unowned :live_react dependency while the integration manifest says PhoenixHx owns it. No writes occurred."
            )
          else
            insert_into_function_list(
              content,
              rx("\\bdefp?\\s+deps\\b"),
              marker_lines(begin_token, end_token, desired, "      ", "#"),
              "mix.exs deps()"
            )
          end
        end
      end
    end
  end

  defp patch_asset_alias(
         content,
         alias_name,
         desired_line,
         begin_token,
         end_token,
         restore_key,
         restores
       ) do
    desired =
      desired_asset_alias_lines(
        alias_name,
        desired_line,
        map_get_nullable_string(restores, restore_key)
      )

    replaced =
      HaxeProjectPatch.replace_marker_block_lines(content, begin_token, end_token, desired)

    replaced_tag = tag(replaced)

    if replaced_tag == :ok do
      {Kernel.elem(replaced, 1), restores}
    else
      if replaced_tag == :error do
        Kernel.raise(
          "mix.exs has a malformed #{alias_name} LiveReact marker (#{Kernel.inspect(Kernel.elem(replaced, 1))}). No writes occurred."
        )
      else
        lines = split_lines(content)
        span = find_alias_span(lines, alias_name)

        if elem(span, 0) == elem(span, 1) do
          patch_single_line_asset_alias(
            lines,
            elem(span, 0),
            alias_name,
            desired_line,
            begin_token,
            end_token,
            restore_key,
            restores
          )
        else
          patch_multiline_asset_alias(
            lines,
            elem(span, 0),
            elem(span, 1),
            alias_name,
            desired,
            begin_token,
            end_token,
            restore_key,
            restores
          )
        end
      end
    end
  end

  defp patch_single_line_asset_alias(
         lines,
         index,
         alias_name,
         desired_line,
         begin_token,
         end_token,
         restore_key,
         restores
       ) do
    original = at(lines, index)

    if find_unowned_vite_task(lines, index, index) do
      Kernel.raise(
        "mix.exs #{alias_name} already contains an unowned Vite task. No writes occurred. Adopt the exact PhoenixHx marker block or use manual integration."
      )
    else
      desired = render_single_line_asset_alias(original, alias_name, desired_line)
      block = marker_lines(begin_token, end_token, desired, leading_indent(original), "#")
      updated = List.replace_at(lines, index, Enum.join(block, "\n"))
      {Enum.join(updated, "\n"), put_restore(restores, restore_key, original)}
    end
  end

  defp patch_multiline_asset_alias(
         lines,
         start_index,
         end_index,
         alias_name,
         desired,
         begin_token,
         end_token,
         restore_key,
         restores
       ) do
    esbuild_indices =
      indices(start_index, end_index + 1, fn index ->
        Regex.match?(
          rx("^\\s*\"?esbuild(?:\\.install|\\s)"),
          String.trim_leading(at(lines, index))
        )
      end)

    if length(esbuild_indices) > 1 do
      Kernel.raise(
        "mix.exs #{alias_name} contains multiple esbuild tasks. No writes occurred. Manual integration is required."
      )
    else
      if length(esbuild_indices) == 1 do
        index = Enum.at(esbuild_indices, 0)
        original = at(lines, index)
        block = marker_lines(begin_token, end_token, desired, leading_indent(original), "#")

        {Enum.join(List.replace_at(lines, index, Enum.join(block, "\n")), "\n"),
         put_restore(restores, restore_key, original)}
      else
        if find_unowned_vite_task(lines, start_index, end_index) do
          Kernel.raise(
            "mix.exs #{alias_name} already contains an unowned Vite task. No writes occurred. Adopt the exact PhoenixHx marker block or use manual integration."
          )
        else
          insertion = alias_insertion_index(lines, start_index, end_index)

          block =
            marker_lines(
              begin_token,
              end_token,
              desired,
              alias_entry_indent(lines, start_index, end_index),
              "#"
            )

          {Enum.join(List.insert_at(lines, insertion, Enum.join(block, "\n")), "\n"),
           put_restore(restores, restore_key, nil)}
        end
      end
    end
  end

  defp desired_asset_alias_lines(alias_name, desired_line, original) do
    if not Kernel.is_nil(original) and single_line_alias(original, alias_name) do
      render_single_line_asset_alias(original, alias_name, desired_line)
    else
      [desired_line]
    end
  end

  defp single_line_alias(line, alias_name) do
    Regex.match?(
      rx("^[\\s]*[\"']#{Regex.escape(alias_name)}[\"']\\s*:\\s*\\[.*\\]\\s*,?\\s*$"),
      line
    )
  end

  defp render_single_line_asset_alias(line, alias_name, desired_line) do
    indent = leading_indent(line)
    unindented = String.replace_prefix(line, indent, "")
    pattern = rx("^([\"']#{Regex.escape(alias_name)}[\"']\\s*:\\s*)\\[(.*)\\](\\s*,?\\s*)$")
    captures = Regex.run(pattern, unindented)

    if Kernel.is_nil(captures) or length(captures) != 4 do
      Kernel.raise(
        "mix.exs #{alias_name} is not a supported single-line string-task alias. No writes occurred."
      )
    else
      parsed = Code.string_to_quoted("[#{Enum.at(captures, 2)}]")
      parsed_tag = tag(parsed)

      if parsed_tag != :ok do
        Kernel.raise(
          "mix.exs #{alias_name} is not a supported single-line string-task alias. No writes occurred."
        )
      else
        items = Kernel.elem(parsed, 1)

        if not Enum.all?(items, fn item -> Kernel.is_binary(item) end) do
          Kernel.raise(
            "mix.exs #{alias_name} single-line alias must contain literal string tasks. No writes occurred. Expand the alias manually for custom terms."
          )
        else
          desired = Code.string_to_quoted!(String.trim_trailing(desired_line, ","))

          esbuild_count =
            Enum.count(items, fn item ->
              String.starts_with?(Kernel.to_string(item), "esbuild")
            end)

          if esbuild_count > 1 do
            Kernel.raise(
              "mix.exs #{alias_name} contains multiple esbuild tasks. No writes occurred. Manual integration is required."
            )
          else
            updated_items =
              if esbuild_count == 1 do
                Enum.map(items, fn item ->
                  if String.starts_with?(Kernel.to_string(item), "esbuild"),
                    do: desired,
                    else: item
                end)
              else
                Enum.concat([desired], items)
              end

            rendered =
              Enum.map(Enum.with_index(updated_items), fn entry ->
                item = Kernel.elem(entry, 0)
                index = Kernel.elem(entry, 1)
                suffix = if index == length(updated_items) - 1, do: "", else: ","
                "  " <> Kernel.inspect(item) <> suffix
              end)

            Enum.concat(Enum.concat(["#{Enum.at(captures, 1)}["], rendered), [
              "]#{Enum.at(captures, 3)}"
            ])
          end
        end
      end
    end
  end

  defp find_alias_span(lines, alias_name) do
    start_index = nil
    _g = 0
    g_value = Enum.with_index(lines)

    start_index =
      Enum.reduce(g_value, start_index, fn entry, start_index_acc ->
        line = Kernel.elem(entry, 0)
        index = Kernel.elem(entry, 1)

        if Kernel.is_nil(start_index_acc) and
             Regex.match?(rx("[\"']" <> Regex.escape(alias_name) <> "[\"']\\s*:\\s*\\["), line),
           do: index,
           else: start_index_acc
      end)

    if Kernel.is_nil(start_index) do
      Kernel.raise(
        "mix.exs has no #{Kernel.inspect(alias_name)} list alias. No writes occurred. Canonical PhoenixHx aliases are required."
      )
    else
      initial_depth = bracket_delta(at(lines, start_index))

      if initial_depth < 0 do
        Kernel.raise(
          "mix.exs #{alias_name} is not a recognizable list alias. No writes occurred."
        )
      else
        if initial_depth == 0 do
          {start_index, start_index}
        else
          find_alias_end(lines, alias_name, start_index, initial_depth)
        end
      end
    end
  end

  defp find_alias_end(lines, alias_name, start_index, initial_depth) do
    depth = initial_depth
    end_index = nil
    _g = start_index + 1
    lines_length = length(lines)

    {_depth, end_index} =
      Enum.reduce((start_index + 1)..(lines_length - 1)//1, {depth, end_index}, fn _index,
                                                                                   {depth_acc,
                                                                                    end_index_acc} ->
        if Kernel.is_nil(end_index_acc) do
          depth_acc = depth_acc + bracket_delta(at(lines, start_index))
          end_index_acc = if depth_acc == 0, do: start_index, else: end_index_acc
          {depth_acc, end_index_acc}
        else
          {depth_acc, end_index_acc}
        end
      end)

    if Kernel.is_nil(end_index) do
      Kernel.raise("mix.exs #{alias_name} list is not balanced. No writes occurred.")
    else
      {start_index, end_index}
    end
  end

  defp bracket_delta(line) do
    Enum.reduce(String.graphemes(line), 0, fn character, depth ->
      cond do
        character == "[" -> depth + 1
        character == "]" -> depth - 1
        true -> depth
      end
    end)
  end

  defp find_unowned_vite_task(lines, start_index, end_index) do
    _g = start_index
    g_value = end_index + 1

    case Enum.reduce_while(start_index..(g_value - 1)//1, :__reflaxe_no_return__, fn index, _ ->
           line = at(lines, index)

           if String.contains?(line, "npm run assets:build") or
                String.contains?(line, "npm install"),
              do: {:halt, {:__reflaxe_return__, true}},
              else: {:cont, :__reflaxe_no_return__}
         end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      _ -> false
    end
  end

  defp alias_insertion_index(lines, start_index, end_index) do
    _g = start_index + 1
    g_value = end_index

    case Enum.reduce_while((start_index + 1)..(g_value - 1)//1, :__reflaxe_no_return__, fn index,
                                                                                           _ ->
           if String.contains?(at(lines, index), "END reflaxe_elixir haxe_compile_client_alias"),
             do: {:halt, {:__reflaxe_return__, index + 1}},
             else: {:cont, :__reflaxe_no_return__}
         end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      _ -> start_index + 1
    end
  end

  defp alias_entry_indent(lines, start_index, end_index) do
    _g = start_index + 1
    g_value = end_index

    case Enum.reduce_while((start_index + 1)..(g_value - 1)//1, :__reflaxe_no_return__, fn index,
                                                                                           _ ->
           line = at(lines, index)

           if String.trim(line) != "",
             do: {:halt, {:__reflaxe_return__, leading_indent(line)}},
             else: {:cont, :__reflaxe_no_return__}
         end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      _ -> "        "
    end
  end

  defp insert_into_function_list(content, function_pattern, block_lines, label) do
    options = [{:return, :index}]
    match = Regex.run(function_pattern, content, options)

    if Kernel.is_nil(match) or not Kernel.is_list(match) do
      Kernel.raise("could not find #{label}. No writes occurred.")
    else
      matches = match

      if length(matches) == 0 do
        Kernel.raise("could not find #{label}. No writes occurred.")
      else
        first = Enum.at(matches, 0)
        function_position = Kernel.elem(first, 0)

        remainder =
          String.slice(content, function_position, Kernel.byte_size(content) - function_position)

        list_match = :binary.match(remainder, "[")

        if list_match == :nomatch do
          Kernel.raise("could not find the list in #{label}. No writes occurred.")
        else
          match_position = Kernel.elem(list_match, 0)
          insertion = function_position + match_position + 1

          "#{String.slice(content, 0, insertion)}\n#{Enum.join(block_lines, "\n")}\n#{String.slice(content, insertion, Kernel.byte_size(content) - insertion)}"
        end
      end
    end
  end

  defp insert_vite_watcher(content, watcher_line, restores) do
    if Regex.match?(rx_with_options("^\\s*vite:\\s*", "m"), content) do
      Kernel.raise(
        "config/dev.exs already contains an unowned Vite watcher. No writes occurred. Manual integration is required."
      )
    else
      lines = split_lines(content)
      esbuild = []
      _g = 0
      g_value = Enum.with_index(lines)

      esbuild =
        Enum.reduce(g_value, esbuild, fn entry, esbuild_acc ->
          line = Kernel.elem(entry, 0)

          if Regex.match?(rx("^\\s*esbuild:\\s*"), line) do
            Enum.concat(esbuild_acc, [entry])
          else
            esbuild_acc
          end
        end)

      begin_token = "BEGIN reflaxe_elixir live_react_vite_watcher"
      end_token = "END reflaxe_elixir live_react_vite_watcher"

      if length(esbuild) == 1 do
        original = Kernel.elem(Enum.at(esbuild, 0), 0)
        index = Kernel.elem(Enum.at(esbuild, 0), 1)

        if not balanced_single_line_expression(original) do
          Kernel.raise(
            "config/dev.exs has a multi-line or ambiguous esbuild watcher. No writes occurred. Manual integration is required."
          )
        else
          block =
            marker_lines(begin_token, end_token, [watcher_line], leading_indent(original), "#")

          {Enum.join(List.replace_at(lines, index, Enum.join(block, "\n")), "\n"),
           put_restore(restores, "dev.esbuildWatcher", original)}
        end
      else
        if length(esbuild) == 0 do
          insertion = watcher_list_insertion_index(lines)

          block =
            marker_lines(
              begin_token,
              end_token,
              [watcher_line],
              watcher_entry_indent(lines, insertion),
              "#"
            )

          {Enum.join(List.insert_at(lines, insertion, Enum.join(block, "\n")), "\n"),
           put_restore(restores, "dev.esbuildWatcher", nil)}
        else
          Kernel.raise(
            "config/dev.exs contains #{Kernel.to_string(length(esbuild))} esbuild watcher entries. No writes occurred. Manual integration is required."
          )
        end
      end
    end
  end

  defp balanced_single_line_expression(line) do
    occurrence_count(line, "{") == occurrence_count(line, "}") and
      occurrence_count(line, "[") == occurrence_count(line, "]") and
      occurrence_count(line, "(") == occurrence_count(line, ")")
  end

  defp occurrence_count(content, token) do
    length(:binary.matches(content, token))
  end

  defp watcher_list_insertion_index(lines) do
    watcher_index = nil
    _g = 0
    g_value = Enum.with_index(lines)

    watcher_index =
      Enum.reduce(g_value, watcher_index, fn entry, watcher_index_acc ->
        line = Kernel.elem(entry, 0)

        if Kernel.is_nil(watcher_index_acc) and Regex.match?(rx("\\bwatchers\\s*:"), line) do
          Kernel.elem(entry, 1)
        else
          watcher_index_acc
        end
      end)

    if Kernel.is_nil(watcher_index) do
      Kernel.raise(
        "config/dev.exs has no watchers configuration. No writes occurred. Canonical Phoenix watcher topology is required."
      )
    else
      end_ = Kernel.min(length(lines) - 1, watcher_index + 16)
      _g = watcher_index
      g_value = end_ + 1

      case Enum.reduce_while(watcher_index..(g_value - 1)//1, :__reflaxe_no_return__, fn index,
                                                                                         _ ->
             if String.contains?(at(lines, index), "["),
               do: {:halt, {:__reflaxe_return__, index + 1}},
               else: {:cont, :__reflaxe_no_return__}
           end) do
        {:__reflaxe_return__, reflaxe_return_value} ->
          reflaxe_return_value

        _ ->
          Kernel.raise(
            "config/dev.exs watchers configuration has no recognizable list. No writes occurred."
          )
      end
    end
  end

  defp watcher_entry_indent(lines, insertion_index) do
    end_ = Kernel.min(length(lines) - 1, insertion_index + 11)
    _g = insertion_index
    g_value = end_ + 1

    case Enum.reduce_while(insertion_index..(g_value - 1)//1, :__reflaxe_no_return__, fn _index,
                                                                                         _ ->
           line = at(lines, insertion_index)
           trimmed = String.trim(line)

           if trimmed != "" and trimmed != "]" and trimmed != "])",
             do: {:halt, {:__reflaxe_return__, leading_indent(line)}},
             else: {:cont, :__reflaxe_no_return__}
         end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      _ -> "    "
    end
  end

  defp patch_app_js_import(content) do
    begin_token = "BEGIN reflaxe_elixir live_react_import"
    end_token = "END reflaxe_elixir live_react_import"
    desired = HaxePhoenixLiveReact.Core.live_react_import_lines()

    replaced =
      HaxeProjectPatch.replace_marker_block_lines(content, begin_token, end_token, desired)

    replaced_tag = tag(replaced)

    if replaced_tag == :ok do
      Kernel.elem(replaced, 1)
    else
      if replaced_tag == :error do
        Kernel.raise(
          "assets/js/app.js has a malformed LiveReact import marker (#{Kernel.inspect(Kernel.elem(replaced, 1))}). No writes occurred."
        )
      else
        if String.contains?(content, "live-react-hooks") do
          Kernel.raise(
            "assets/js/app.js already imports an unowned LiveReact hook module. No writes occurred. Manual integration is required."
          )
        else
          lines = split_lines(content)
          last_import = -1
          _g = 0
          g_value = Enum.with_index(lines)

          last_import =
            Enum.reduce(g_value, last_import, fn entry, last_import_acc ->
              line = Kernel.elem(entry, 0)

              if String.starts_with?(String.trim_leading(line), "import ") do
                Kernel.elem(entry, 1)
              else
                last_import_acc
              end
            end)

          Enum.join(
            List.insert_at(
              lines,
              last_import + 1,
              Enum.join(marker_lines(begin_token, end_token, desired, "", "//"), "\n")
            ),
            "\n"
          )
        end
      end
    end
  end

  defp patch_app_js_hooks(content, restores) do
    declaration = nil
    _g = 0
    g_value = Enum.with_index(split_lines(content))

    declaration =
      Enum.reduce(g_value, declaration, fn entry, declaration_acc ->
        line = Kernel.elem(entry, 0)

        if Kernel.is_nil(declaration_acc) and
             Regex.match?(rx("^\\s*(?:let|const|var)\\s+Hooks\\b"), line) do
          Kernel.elem(entry, 1)
        else
          declaration_acc
        end
      end)

    if Kernel.is_nil(declaration) do
      patch_window_hooks(content, restores)
    else
      patch_declared_hooks(content, declaration, restores)
    end
  end

  defp patch_declared_hooks(content, declaration, restores) do
    begin_token = "BEGIN reflaxe_elixir live_react_hooks"
    end_token = "END reflaxe_elixir live_react_hooks"
    desired = HaxePhoenixLiveReact.Core.declared_hooks_lines()

    replaced =
      HaxeProjectPatch.replace_marker_block_lines(content, begin_token, end_token, desired)

    replaced_tag = tag(replaced)

    if replaced_tag == :ok do
      {Kernel.elem(replaced, 1), restores}
    else
      if replaced_tag == :error do
        Kernel.raise(
          "assets/js/app.js has a malformed LiveReact hooks marker (#{Kernel.inspect(Kernel.elem(replaced, 1))}). No writes occurred."
        )
      else
        lines = split_lines(content)
        insertion = declaration + 1
        end_ = Kernel.min(length(lines) - 1, declaration + 8)
        _g = declaration + 1
        g_value = end_ + 1

        insertion =
          Enum.reduce((declaration + 1)..(g_value - 1)//1, insertion, fn index, insertion_acc ->
            if String.contains?(at(lines, index), "END reflaxe_elixir hooks_after_decl") do
              insertion_acc = index + 1
              insertion_acc
            else
              insertion_acc
            end
          end)

        block =
          marker_lines(
            begin_token,
            end_token,
            desired,
            leading_indent(at(lines, declaration)),
            "//"
          )

        {Enum.join(List.insert_at(lines, insertion, Enum.join(block, "\n")), "\n"), restores}
      end
    end
  end

  defp patch_window_hooks(content, restores) do
    begin_token = "BEGIN reflaxe_elixir live_react_window_hooks"
    end_token = "END reflaxe_elixir live_react_window_hooks"
    desired = HaxePhoenixLiveReact.Core.window_hooks_lines()

    replaced =
      HaxeProjectPatch.replace_marker_block_lines(content, begin_token, end_token, desired)

    replaced_tag = tag(replaced)
    updated = nil

    updated =
      cond do
        replaced_tag == :ok ->
          updated = Kernel.elem(replaced, 1)
          updated

        replaced_tag == :error ->
          Kernel.raise(
            "assets/js/app.js has a malformed LiveReact window-hooks marker (" <>
              Kernel.inspect(Kernel.elem(replaced, 1)) <> "). No writes occurred."
          )

          updated

        true ->
          lines = split_lines(content)
          live_socket = find_live_socket_index(lines)
          block = marker_lines(begin_token, end_token, desired, "", "//")
          updated = Enum.join(List.insert_at(lines, live_socket, Enum.join(block, "\n")), "\n")
          updated
      end

    if live_socket_uses_window_hooks(updated),
      do: {updated, restores},
      else: patch_live_socket_hooks_property(updated, restores)
  end

  defp live_socket_uses_window_hooks(content) do
    Enum.any?(split_lines(content), fn line ->
      String.contains?(line, "hooks:") and String.contains?(line, "window.Hooks")
    end)
  end

  defp patch_live_socket_hooks_property(content, restores) do
    begin_token = "BEGIN reflaxe_elixir live_react_hooks_property"
    end_token = "END reflaxe_elixir live_react_hooks_property"
    presence = marker_presence(content, begin_token, end_token)
    desired = if presence == :present, do: expected_hooks_property_lines(restores), else: []

    replaced =
      HaxeProjectPatch.replace_marker_block_lines(content, begin_token, end_token, desired)

    replaced_tag = tag(replaced)

    if replaced_tag == :ok do
      {Kernel.elem(replaced, 1), restores}
    else
      if replaced_tag == :error do
        Kernel.raise(
          "assets/js/app.js has a malformed LiveReact hooks-property marker (#{Kernel.inspect(Kernel.elem(replaced, 1))}). No writes occurred."
        )
      else
        lines = split_lines(content)
        live_socket = find_live_socket_index(lines)

        hooks_indices =
          indices(live_socket, Kernel.min(length(lines) - 1, live_socket + 20) + 1, fn index ->
            Regex.match?(rx("^\\s*hooks\\s*:"), at(lines, index))
          end)

        if length(hooks_indices) == 1 do
          index = Enum.at(hooks_indices, 0)
          original = at(lines, index)

          block =
            marker_lines(
              begin_token,
              end_token,
              [rewrite_hooks_property_with_window(original)],
              leading_indent(original),
              "//"
            )

          {Enum.join(List.replace_at(lines, index, Enum.join(block, "\n")), "\n"),
           put_restore(restores, "app.hooksProperty", original)}
        else
          if length(hooks_indices) > 1 do
            Kernel.raise(
              "assets/js/app.js has #{Kernel.to_string(length(hooks_indices))} LiveSocket hooks properties near construction. No writes occurred."
            )
          else
            live_socket_line = at(lines, live_socket)

            if Regex.match?(rx("\\bhooks\\s*:"), live_socket_line) do
              Kernel.raise(
                "assets/js/app.js has an inline LiveSocket hooks property that cannot be patched safely. No writes occurred. Expand the options object or use manual integration."
              )
            else
              if not String.contains?(live_socket_line, "{") do
                Kernel.raise(
                  "assets/js/app.js LiveSocket options are not a recognizable object. No writes occurred."
                )
              else
                candidate_indent = leading_indent(at_default(lines, live_socket + 1, "  "))

                next_indent =
                  if candidate_indent == "" do
                    "#{leading_indent(live_socket_line)}  "
                  else
                    candidate_indent
                  end

                block =
                  marker_lines(
                    begin_token,
                    end_token,
                    ["hooks: window.Hooks || {},"],
                    next_indent,
                    "//"
                  )

                updated =
                  if Regex.match?(rx("\\{\\s*\\}"), live_socket_line) do
                    options = [{:global, false}]

                    replacement_text =
                      Enum.join(
                        ["{", Enum.join(block, "\n"), "#{leading_indent(live_socket_line)}}"],
                        "\n"
                      )

                    replacement =
                      String.replace(
                        live_socket_line,
                        rx("\\{\\s*\\}"),
                        replacement_text,
                        options
                      )

                    Enum.join(List.replace_at(lines, live_socket, replacement), "\n")
                  else
                    Enum.join(
                      List.insert_at(lines, live_socket + 1, Enum.join(block, "\n")),
                      "\n"
                    )
                  end

                {updated, put_restore(restores, "app.hooksProperty", nil)}
              end
            end
          end
        end
      end
    end
  end

  defp expected_hooks_property_lines(restores) do
    fetched = Map.fetch(restores, "app.hooksProperty")
    fetched_tag = tag(fetched)

    if fetched_tag == :error do
      Kernel.raise(
        "phoenixhx-live-react.json is missing app.hooksProperty restore metadata. No writes occurred."
      )
    else
      original = Kernel.elem(fetched, 1)

      if Kernel.is_nil(original),
        do: ["hooks: window.Hooks || {},"],
        else: [rewrite_hooks_property_with_window(Kernel.to_string(original))]
    end
  end

  defp find_live_socket_index(lines) do
    _g = 0
    g_value = Enum.with_index(lines)

    case Enum.reduce_while(g_value, :__reflaxe_no_return__, fn entry, _ ->
           line = Kernel.elem(entry, 0)

           if String.contains?(line, "new LiveSocket"),
             do: {:halt, {:__reflaxe_return__, Kernel.elem(entry, 1)}},
             else: {:cont, :__reflaxe_no_return__}
         end) do
      {:__reflaxe_return__, reflaxe_return_value} ->
        reflaxe_return_value

      _ ->
        Kernel.raise(
          "assets/js/app.js has no recognizable LiveSocket construction. No writes occurred."
        )
    end
  end

  defp rewrite_hooks_property_with_window(line) do
    trimmed = String.trim(line)
    trailing_comma = String.ends_with?(trimmed, ",")

    without_comma =
      if trailing_comma do
        String.trim_trailing(trimmed, ",")
      else
        trimmed
      end

    options = [{:parts, 2}]
    parts = String.split(without_comma, "hooks:", options)

    if length(parts) != 2 do
      Kernel.raise("assets/js/app.js hooks property is not recognizable. No writes occurred.")
    else
      expression = String.trim(Enum.at(parts, 1))
      merged = nil

      merged =
        cond do
          String.starts_with?(expression, "{") and String.ends_with?(expression, "}") ->
            inner = String.trim(String.trim_trailing(String.trim_leading(expression, "{"), "}"))

            merged =
              if inner == "",
                do: "{...(window.Hooks || {})}",
                else: "{" <> inner <> ", ...(window.Hooks || {})}"

            merged

          expression != "" ->
            merged = "{..." <> expression <> ", ...(window.Hooks || {})}"
            merged

          true ->
            Kernel.raise("assets/js/app.js has an empty hooks property. No writes occurred.")
            merged
        end

      "hooks: #{merged}#{if trailing_comma, do: ",", else: ""}"
    end
  end

  defp find_root_app_script(content) do
    lines = split_lines(content)
    starts = []
    _g = 0
    g_value = Enum.with_index(lines)

    starts =
      Enum.reduce(g_value, starts, fn entry, starts_acc ->
        line = Kernel.elem(entry, 0)

        if String.contains?(line, "<script") and String.contains?(line, "/assets/app.js") do
          Enum.concat(starts_acc, [entry])
        else
          starts_acc
        end
      end)

    if length(starts) == 0 do
      Kernel.raise(
        "Phoenix root layout has no canonical /assets/app.js script. No writes occurred. Run the Phoenix scaffold first."
      )
    else
      if length(starts) != 1 do
        Kernel.raise(
          "Phoenix root layout has #{Kernel.to_string(length(starts))} app script candidates. No writes occurred."
        )
      else
        line = Kernel.elem(Enum.at(starts, 0), 0)
        start_index = Kernel.elem(Enum.at(starts, 0), 1)
        end_index = if String.contains?(line, "</script>"), do: start_index, else: nil

        end_index =
          if Kernel.is_nil(end_index) do
            end_ = Kernel.min(length(lines) - 1, start_index + 5)
            _g = start_index
            g_value = end_ + 1

            end_index =
              Enum.reduce(start_index..(g_value - 1)//1, end_index, fn index, _end_index_acc ->
                if Kernel.is_nil(index) and String.contains?(at(lines, index), "</script>"),
                  do: index,
                  else: index
              end)

            end_index
          else
            end_index
          end

        if Kernel.is_nil(end_index) do
          Kernel.raise(
            "Phoenix root layout app script is not closed within a supported span. No writes occurred."
          )
        else
          original =
            Enum.join(Enum.take(Enum.drop(lines, start_index), end_index - start_index + 1), "\n")

          %{
            original: original,
            start_index: start_index,
            end_index: end_index,
            indent: leading_indent(line)
          }
        end
      end
    end
  end

  defp root_asset_inner_lines(original) do
    if Kernel.is_nil(original) do
      Kernel.raise("missing original Phoenix root-layout app script")
    else
      original_lines = split_lines(original)
      original_indent = leading_indent(Enum.at(original_lines, 0))

      script =
        Enum.map(original_lines, fn line ->
          stripped =
            if String.starts_with?(line, original_indent) do
              String.replace_prefix(line, original_indent, "")
            else
              String.trim_leading(line)
            end

          "  " <> stripped
        end)

      Enum.concat(
        Enum.concat(["<LiveReact.Reload.vite_assets assets={[\"/js/app.js\"]}>"], script),
        ["</LiveReact.Reload.vite_assets>"]
      )
    end
  end

  defp remove_hooks_property(content, restores) do
    presence =
      marker_presence(
        content,
        "BEGIN reflaxe_elixir live_react_hooks_property",
        "END reflaxe_elixir live_react_hooks_property"
      )

    fetched = Map.fetch(restores, "app.hooksProperty")
    fetched_tag = tag(fetched)

    if fetched_tag == :error and presence == :missing do
      content
    else
      if fetched_tag == :ok and presence == :present do
        restore_owned_marker(
          content,
          "BEGIN reflaxe_elixir live_react_hooks_property",
          "END reflaxe_elixir live_react_hooks_property",
          expected_hooks_property_lines(restores),
          Kernel.elem(fetched, 1),
          "assets/js/app.js hooks property"
        )
      else
        if fetched_tag == :error do
          Kernel.raise(
            "phoenixhx-live-react.json is missing app.hooksProperty restore metadata. No writes occurred."
          )
        else
          Kernel.raise(
            "assets/js/app.js owned hooks-property marker is missing. No writes occurred."
          )
        end
      end
    end
  end

  defp remove_appended_owned_marker(content, begin_token, end_token, expected, trailing, label) do
    if not Kernel.is_binary(trailing) do
      Kernel.raise(
        "phoenixhx-live-react.json is missing trailing-whitespace restore metadata for #{label}. No writes occurred."
      )
    else
      lines = split_lines(content)
      marker = marker_indices(lines, begin_token, end_token, label)
      prefix = Enum.take(lines, elem(marker, 0))
      suffix = Enum.drop(lines, elem(marker, 1) + 1)

      if List.last(prefix) != "" do
        Kernel.raise("#{label} lost its owned separator line. No writes occurred.")
      else
        restore_owned_marker(content, begin_token, end_token, expected, nil, label)

        base =
          "#{Enum.join(Enum.take(prefix, length(prefix) - 1), "\n")}#{Kernel.to_string(trailing)}"

        if Enum.all?(suffix, fn line -> String.trim(line) == "" end) do
          base
        else
          "#{base}\n#{Enum.join(suffix, "\n")}"
        end
      end
    end
  end

  defp unwrap_owned_marker(content, begin_token, end_token, expected, label) do
    lines = split_lines(content)
    marker = marker_indices(lines, begin_token, end_token, label)
    indent = leading_indent(at(lines, elem(marker, 0)))

    inner =
      Enum.take(Enum.drop(lines, elem(marker, 0) + 1), elem(marker, 1) - elem(marker, 0) - 1)

    actual = Enum.map(inner, fn line -> strip_expected_indent(line, indent) end)

    if not same_array(actual, expected) do
      Kernel.raise("#{label} content drifted inside its ownership markers. No writes occurred.")
    else
      Enum.join(
        replace_line_range_with_lines(lines, elem(marker, 0), elem(marker, 1), inner),
        "\n"
      )
    end
  end

  defp remove_inserted_dependency_marker(content, begin_token, end_token, expected, label) do
    block = Enum.join(marker_lines(begin_token, end_token, expected, "      ", "#"), "\n")
    inserted = "\n#{block}\n"
    matches = :binary.matches(content, inserted)

    if length(matches) != 1 do
      Kernel.raise(
        "#{label} no longer matches the exact inserted dependency block. No writes occurred. Restore the owned block or retain the dependency as hand-owned before retrying."
      )
    else
      position = Kernel.elem(Enum.at(matches, 0), 0)
      length = Kernel.elem(Enum.at(matches, 0), 1)

      "#{Kernel.binary_part(content, 0, position)}#{Kernel.binary_part(content, position + length, Kernel.byte_size(content) - position - length)}"
    end
  end

  defp restore_owned_marker(content, begin_token, end_token, expected, original, label) do
    lines = split_lines(content)
    marker = marker_indices(lines, begin_token, end_token, label)
    indent = leading_indent(at(lines, elem(marker, 0)))

    actual =
      Enum.map(
        Enum.take(Enum.drop(lines, elem(marker, 0) + 1), elem(marker, 1) - elem(marker, 0) - 1),
        fn line -> strip_expected_indent(line, indent) end
      )

    if not same_array(actual, expected) do
      Kernel.raise("#{label} content drifted inside its ownership markers. No writes occurred.")
    else
      replacement =
        if Kernel.is_nil(original), do: [], else: split_lines(Kernel.to_string(original))

      Enum.join(
        replace_line_range_with_lines(lines, elem(marker, 0), elem(marker, 1), replacement),
        "\n"
      )
    end
  end

  defp strip_expected_indent(line, indent) do
    if indent != "" and String.starts_with?(line, indent) do
      String.replace_prefix(line, indent, "")
    else
      line
    end
  end

  defp marker_inner_lines(content, begin_token, end_token, label) do
    lines = split_lines(content)
    marker = marker_indices(lines, begin_token, end_token, label)

    Enum.map(
      Enum.take(Enum.drop(lines, elem(marker, 0) + 1), elem(marker, 1) - elem(marker, 0) - 1),
      fn line -> String.trim_leading(line) end
    )
  end

  defp marker_indices(lines, begin_token, end_token, label) do
    begins = matching_indices(lines, begin_token)
    ends = matching_indices(lines, end_token)

    if length(begins) == 1 and length(ends) == 1 and Enum.at(begins, 0) < Enum.at(ends, 0) do
      {Enum.at(begins, 0), Enum.at(ends, 0)}
    else
      Kernel.raise("#{label} must contain exactly one ordered marker pair. No writes occurred.")
    end
  end

  defp marker_presence(content, begin_token, end_token) do
    lines = split_lines(content)
    begins = matching_indices(lines, begin_token)
    ends = matching_indices(lines, end_token)

    if length(begins) == 0 and length(ends) == 0 do
      :missing
    else
      if length(begins) == 1 and length(ends) == 1 do
        :present
      else
        Kernel.raise("malformed ownership markers for #{begin_token}. No writes occurred.")
      end
    end
  end

  defp matching_indices(lines, token) do
    pattern = rx("(?:^|\\s)#{Regex.escape(token)}(?=$|\\s)")
    result = []
    _g = 0
    g_value = Enum.with_index(lines)

    result =
      Enum.reduce(g_value, result, fn entry, result_acc ->
        line = Kernel.elem(entry, 0)

        if Regex.match?(pattern, line) do
          Enum.concat(result_acc, [Kernel.elem(entry, 1)])
        else
          result_acc
        end
      end)

    result
  end

  defp validate_file_markers(content, source_path, label) do
    pairs = []
    _g = 0
    g_value = marker_specs()

    pairs =
      Enum.reduce(g_value, pairs, fn spec, pairs_acc ->
        spec_path = Kernel.elem(spec, 0)

        if spec_path == source_path do
          Enum.concat(pairs_acc, [{Kernel.elem(spec, 1), Kernel.elem(spec, 2)}])
        else
          pairs_acc
        end
      end)

    validate_marker_pairs(content, pairs, label)
  end

  defp validate_marker_pairs(content, pairs, label) do
    validated = HaxeProjectPatch.validate_marker_pairs(content, pairs)

    if validated != :ok do
      Kernel.raise(
        "#{label} has malformed or overlapping ownership markers: #{Kernel.inspect(Kernel.elem(validated, 1))}. No writes occurred."
      )
    end
  end

  defp append_marker_block(content, begin_token, end_token, desired, indent, comment_prefix) do
    "#{String.trim_trailing(content)}\n\n#{Enum.join(marker_lines(begin_token, end_token, desired, indent, comment_prefix), "\n")}\n"
  end

  defp marker_lines(begin_token, end_token, desired, indent, comment_prefix) do
    marker_lines_with_suffix(begin_token, end_token, desired, indent, comment_prefix, "")
  end

  defp marker_lines_with_suffix(begin_token, end_token, desired, indent, comment_prefix, suffix) do
    opening =
      "#{indent}#{comment_prefix} #{begin_token}#{if comment_prefix == "<%!--", do: " --%>", else: suffix}"

    closing =
      "#{indent}#{comment_prefix} #{end_token}#{if comment_prefix == "<%!--", do: " --%>", else: suffix}"

    body = Enum.map(desired, fn line -> indent <> line end)
    Enum.concat(Enum.concat([opening], body), [closing])
  end

  defp replace_line_range(lines, start_index, end_index, replacement) do
    Enum.concat(
      Enum.concat(Enum.take(lines, start_index), [replacement]),
      Enum.drop(lines, end_index + 1)
    )
  end

  defp replace_line_range_with_lines(lines, start_index, end_index, replacements) do
    Enum.concat(
      Enum.concat(Enum.take(lines, start_index), replacements),
      Enum.drop(lines, end_index + 1)
    )
  end

  defp trailing_whitespace(content) do
    trimmed = String.trim_trailing(content)

    Kernel.binary_part(
      content,
      Kernel.byte_size(trimmed),
      Kernel.byte_size(content) - Kernel.byte_size(trimmed)
    )
  end

  defp leading_indent(line) do
    capture = Regex.run(rx("^\\s*"), line)

    if Kernel.is_nil(capture) or length(capture) == 0 do
      ""
    else
      Enum.at(capture, 0)
    end
  end

  defp split_lines(content) do
    options = [{:trim, false}]
    String.split(content, "\n", options)
  end

  defp at(lines, index) do
    Enum.at(lines, index, "")
  end

  defp at_default(lines, index, fallback) do
    Enum.at(lines, index, fallback)
  end

  defp indices(start, end_exclusive, predicate) do
    result = []
    _g = start
    g_value = end_exclusive

    result =
      Enum.reduce(start..(g_value - 1)//1, result, fn index, result_acc ->
        if predicate.(index) do
          result_acc = Enum.concat(result_acc, [index])
          result_acc
        else
          result_acc
        end
      end)

    result
  end

  defp same_array(left, right) do
    left == right
  end

  defp map_get(map, key) do
    Map.get(map, key)
  end

  defp map_get_term(map, key) do
    Map.get(map, key)
  end

  defp map_get_nullable_string(map, key) do
    Map.get(map, key)
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

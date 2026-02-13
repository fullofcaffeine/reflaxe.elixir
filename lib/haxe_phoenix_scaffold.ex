defmodule HaxePhoenixScaffold do
  @moduledoc """
  Phoenix client scaffold for Reflaxe.Elixir projects.

  This module exists to solve a specific (and common) dev-watch race:

  - Phoenix runs esbuild in `--watch` mode.
  - Haxe deletes its `-js` output file at the start of compilation.
  - If esbuild imports that output (for example `import "./hx_app.js"`), esbuild can rebuild
    during the brief deletion window and error with: `Could not resolve "./hx_app.js"`.

  The scaffold uses a "temp output + promote" pattern:

  - `build-client.hxml` writes to a temp entry file: `assets/js/_hx_app_tmp.js`
  - A watcher (and one-shot build alias) promotes that temp file into the stable import path:
    `assets/js/hx_app.js`
  - esbuild always imports the stable path, so it never sees the module disappear.

  This is intentionally framework-level plumbing (not a compiler concern) because it's about
  coordinating external file watchers (Haxe compiler + esbuild), not code generation.
  """

  @type option ::
          {:verbose, boolean()}
          | {:strict, boolean()}
          | {:reflaxe_elixir_dep_path, binary() | nil}
          | {:client_mode, :genes | :plain_js}
          | {:yes, boolean()}

  @spec apply!(binary(), [option()]) :: :ok
  def apply!(project_root, opts \\ []) when is_binary(project_root) do
    verbose = Keyword.get(opts, :verbose, false)
    strict = Keyword.get(opts, :strict, true)
    reflaxe_elixir_dep_path = Keyword.get(opts, :reflaxe_elixir_dep_path, nil)
    client_mode = Keyword.get(opts, :client_mode, :genes)
    yes = Keyword.get(opts, :yes, false)

    assets_js_dir = Path.join([project_root, "assets", "js"])
    config_dir = Path.join(project_root, "config")

    unless File.dir?(assets_js_dir) do
      raise "expected Phoenix assets dir at #{assets_js_dir}"
    end

    unless File.dir?(config_dir) do
      raise "expected Phoenix config dir at #{config_dir}"
    end

    ensure_root_layout_boilerplate!(project_root, verbose: verbose, strict: strict)

    case client_mode do
      :genes ->
        apply_genes_scaffold!(
          project_root,
          assets_js_dir,
          config_dir,
          reflaxe_elixir_dep_path,
          verbose: verbose,
          strict: strict
        )

      :plain_js ->
        apply_plain_js_convergence!(
          project_root,
          assets_js_dir,
          config_dir,
          verbose: verbose,
          strict: strict,
          yes: yes
        )

      other ->
        raise "invalid client mode: #{inspect(other)}"
    end

    :ok
  end

  defp ensure_root_layout_boilerplate!(project_root, opts) when is_binary(project_root) do
    verbose = Keyword.get(opts, :verbose, false)

    candidates =
      [
        Path.join([project_root, "lib", "*_web", "components", "layouts", "root.html.heex"]),
        Path.join([project_root, "lib", "*_web", "templates", "layout", "root.html.heex"]),
        Path.join([project_root, "lib", "*_web", "templates", "layout", "root.html.leex"])
      ]
      |> Enum.flat_map(&Path.wildcard/1)
      |> Enum.uniq()

    Enum.each(candidates, fn path ->
      patch_file!(path, &patch_root_layout_template/1, verbose: verbose)
    end)

    :ok
  end

  defp patch_root_layout_template(content) when is_binary(content) do
    content
    |> ensure_doctype()
    |> ensure_csrf_meta()
    |> ensure_tracked_app_script()
  end

  defp ensure_doctype(content) when is_binary(content) do
    if Regex.match?(~r/^\s*<!doctype html>/im, content) do
      content
    else
      "<!DOCTYPE html>\n" <> content
    end
  end

  defp ensure_csrf_meta(content) when is_binary(content) do
    if String.contains?(content, "csrf-token") do
      content
    else
      insert_before_head_close(
        content,
        ~s|<meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />|
      )
    end
  end

  defp ensure_tracked_app_script(content) when is_binary(content) do
    if String.contains?(content, "phx-track-static") do
      content
    else
      insert_before_head_close(
        content,
        ~s|<script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}></script>|
      )
    end
  end

  defp insert_before_head_close(content, line_to_insert)
       when is_binary(content) and is_binary(line_to_insert) do
    case Regex.run(~r/^([ \t]*)<\/head>/im, content, capture: :all_but_first, return: :index) do
      [{indent_pos, indent_len}] ->
        indent = String.slice(content, indent_pos, indent_len)

        Regex.replace(
          ~r/^([ \t]*)<\/head>/im,
          content,
          "#{indent}#{line_to_insert}\n\\0",
          global: false
        )

      _ ->
        content
    end
  end

  defp apply_genes_scaffold!(
         project_root,
         assets_js_dir,
         config_dir,
         reflaxe_elixir_dep_path,
         opts
       )
       when is_binary(project_root) and is_binary(assets_js_dir) and is_binary(config_dir) do
    verbose = Keyword.get(opts, :verbose, false)
    strict = Keyword.get(opts, :strict, true)

    ensure_dir!(Path.join(project_root, "haxe_libraries"))

    ensure_haxe_libraries!(
      project_root,
      reflaxe_elixir_dep_path,
      verbose: verbose,
      strict: strict
    )

    ensure_file!(
      Path.join(project_root, "build-client.hxml"),
      build_client_hxml(),
      verbose: verbose,
      patch: &maybe_patch_build_client_hxml/1
    )

    ensure_dir!(Path.join([project_root, "src_haxe", "client"]))

    ensure_file!(
      Path.join([project_root, "src_haxe", "client", "Boot.hx"]),
      client_boot_hx(),
      verbose: verbose,
      patch: & &1
    )

    ensure_file!(
      Path.join([assets_js_dir, "hx_app.js"]),
      stable_hx_app_js_stub(),
      verbose: verbose,
      patch: &maybe_patch_hx_app_js_stub/1
    )

    patch_file!(Path.join([assets_js_dir, "app.js"]), &patch_phoenix_app_js(&1, strict: strict),
      verbose: verbose
    )

    patch_file!(Path.join([config_dir, "dev.exs"]), &patch_dev_exs(&1, strict: strict),
      verbose: verbose
    )

    patch_file!(Path.join([project_root, "mix.exs"]), &patch_mix_exs(&1, strict: strict),
      verbose: verbose
    )

    patch_file!(Path.join([project_root, ".gitignore"]), &patch_gitignore/1, verbose: verbose)
  end

  defp apply_plain_js_convergence!(project_root, assets_js_dir, config_dir, opts)
       when is_binary(project_root) and is_binary(assets_js_dir) and is_binary(config_dir) do
    verbose = Keyword.get(opts, :verbose, false)
    strict = Keyword.get(opts, :strict, true)
    yes = Keyword.get(opts, :yes, false)

    app_js_path = Path.join([assets_js_dir, "app.js"])
    dev_exs_path = Path.join([config_dir, "dev.exs"])
    mix_exs_path = Path.join([project_root, "mix.exs"])
    gitignore_path = Path.join([project_root, ".gitignore"])

    app_js_markers = [
      {"BEGIN reflaxe_elixir hx_app_import", "END reflaxe_elixir hx_app_import"},
      {"BEGIN reflaxe_elixir hooks_after_decl", "END reflaxe_elixir hooks_after_decl"},
      {"BEGIN reflaxe_elixir hooks_property", "END reflaxe_elixir hooks_property"},
      {"BEGIN reflaxe_elixir hooks_merge", "END reflaxe_elixir hooks_merge"}
    ]

    dev_exs_markers = [
      {"BEGIN reflaxe_elixir haxe_client", "END reflaxe_elixir haxe_client"}
    ]

    mix_exs_markers = [
      {"BEGIN reflaxe_elixir haxe_compile_client_alias",
       "END reflaxe_elixir haxe_compile_client_alias"},
      {"BEGIN reflaxe_elixir assets.build_task", "END reflaxe_elixir assets.build_task"},
      {"BEGIN reflaxe_elixir assets.deploy_task", "END reflaxe_elixir assets.deploy_task"}
    ]

    pending_actions = []

    pending_actions =
      if file_contains_any_marker?(app_js_path, app_js_markers) do
        pending_actions ++ ["Remove scaffold-managed markers from assets/js/app.js"]
      else
        pending_actions
      end

    pending_actions =
      if file_contains_any_marker?(dev_exs_path, dev_exs_markers) do
        pending_actions ++ ["Remove scaffold-managed haxe watcher from config/dev.exs"]
      else
        pending_actions
      end

    pending_actions =
      if file_contains_any_marker?(mix_exs_path, mix_exs_markers) do
        pending_actions ++ ["Remove scaffold-managed mix aliases from mix.exs"]
      else
        pending_actions
      end

    pending_actions =
      if File.exists?(gitignore_path) &&
           scaffold_gitignore_entry_present?(File.read!(gitignore_path)) do
        pending_actions ++ ["Remove scaffold-managed haxe client entries from .gitignore"]
      else
        pending_actions
      end

    managed_candidates = managed_plain_js_candidate_files(project_root, assets_js_dir)

    {managed_to_remove, custom_to_keep} =
      Enum.reduce(managed_candidates, {[], []}, fn {path, managed_fun, description},
                                                   {removable, keepers} ->
        if File.exists?(path) do
          content = File.read!(path)

          if managed_fun.(content) do
            {[{path, description} | removable], keepers}
          else
            {removable, [path | keepers]}
          end
        else
          {removable, keepers}
        end
      end)

    pending_actions =
      Enum.reduce(managed_to_remove, pending_actions, fn {_path, description}, acc ->
        acc ++ [description]
      end)

    confirm_plain_js_changes!(pending_actions, yes)

    patch_file!(
      app_js_path,
      &remove_scaffold_marker_blocks(&1, app_js_markers, strict, "assets/js/app.js"),
      verbose: verbose
    )

    patch_file!(
      dev_exs_path,
      &remove_scaffold_marker_blocks(&1, dev_exs_markers, strict, "config/dev.exs"),
      verbose: verbose
    )

    patch_file!(
      mix_exs_path,
      &remove_scaffold_marker_blocks(&1, mix_exs_markers, strict, "mix.exs"),
      verbose: verbose
    )

    if File.exists?(gitignore_path) do
      patch_file!(gitignore_path, &remove_scaffold_entries_from_gitignore/1, verbose: verbose)
    end

    Enum.each(managed_to_remove, fn {path, _description} ->
      File.rm!(path)
      if verbose, do: IO.puts("[scaffold] removed #{path}")
    end)

    if custom_to_keep != [] do
      IO.warn(
        "plain-js mode kept custom files that are not scaffold-managed:\n" <>
          Enum.map_join(Enum.sort(custom_to_keep), "\n", &"  - #{&1}")
      )
    end

    maybe_remove_empty_dir(Path.join([project_root, "src_haxe", "client"]))
    maybe_remove_empty_dir(Path.join(project_root, "haxe_libraries"))
  end

  defp managed_plain_js_candidate_files(project_root, assets_js_dir)
       when is_binary(project_root) and is_binary(assets_js_dir) do
    [
      {
        Path.join(project_root, "build-client.hxml"),
        &managed_build_client_hxml?/1,
        "Remove scaffold-managed build-client.hxml"
      },
      {
        Path.join([project_root, "src_haxe", "client", "Boot.hx"]),
        &managed_client_boot_hx?/1,
        "Remove scaffold-managed src_haxe/client/Boot.hx"
      },
      {
        Path.join([assets_js_dir, "hx_app.js"]),
        &managed_hx_app_stub?/1,
        "Remove scaffold-managed assets/js/hx_app.js stub"
      },
      {
        Path.join([project_root, "haxe_libraries", "genes.hxml"]),
        &managed_genes_stub?/1,
        "Remove scaffold-managed haxe_libraries/genes.hxml"
      },
      {
        Path.join([project_root, "haxe_libraries", "phoenix_js.hxml"]),
        &managed_phoenix_js_stub?/1,
        "Remove scaffold-managed haxe_libraries/phoenix_js.hxml"
      },
      {
        Path.join([project_root, "haxe_libraries", "helder.set.hxml"]),
        &managed_helder_set_stub?/1,
        "Remove scaffold-managed haxe_libraries/helder.set.hxml"
      }
    ]
  end

  defp file_contains_any_marker?(path, marker_pairs)
       when is_binary(path) and is_list(marker_pairs) do
    if File.exists?(path) do
      content = File.read!(path)

      Enum.any?(marker_pairs, fn {begin_token, _end_token} ->
        String.contains?(content, begin_token)
      end)
    else
      false
    end
  end

  defp confirm_plain_js_changes!(pending_actions, yes)
       when is_list(pending_actions) and is_boolean(yes) do
    if pending_actions == [] or yes do
      :ok
    else
      IO.puts("plain-js mode will remove scaffold-managed Genes wiring:")
      Enum.each(pending_actions, fn action -> IO.puts("  - #{action}") end)

      answer = IO.gets("Continue? [y/N]: ")

      approved =
        case answer do
          line when is_binary(line) ->
            normalized = line |> String.trim() |> String.downcase()
            normalized == "y" or normalized == "yes"

          _ ->
            false
        end

      if approved do
        :ok
      else
        raise "aborted plain-js convergence. Re-run with --yes to skip confirmation."
      end
    end
  end

  defp remove_scaffold_marker_blocks(content, marker_pairs, strict, file_label)
       when is_binary(content) and is_list(marker_pairs) and is_boolean(strict) and
              is_binary(file_label) do
    Enum.reduce(marker_pairs, content, fn {begin_token, end_token}, current ->
      case remove_marker_block_lines(current, begin_token, end_token) do
        {:ok, updated} ->
          updated

        :missing ->
          current

        :error ->
          warn_or_raise(
            "failed to patch #{file_label}: malformed reflaxe_elixir marker block (#{begin_token})",
            strict
          )

          current
      end
    end)
  end

  defp scaffold_gitignore_entry_present?(content) when is_binary(content) do
    entries = [
      "assets/js/_hx_app_tmp.js",
      "assets/js/_hx_app_tmp.js.map",
      "assets/js/hx_app.js",
      "assets/js/hx_app.js.map"
    ]

    Enum.any?(entries, &String.contains?(content, &1))
  end

  defp remove_scaffold_entries_from_gitignore(content) when is_binary(content) do
    removal_lines =
      MapSet.new([
        "# Reflaxe.Elixir (Haxe client JS intermediate output)",
        "assets/js/_hx_app_tmp.js",
        "assets/js/_hx_app_tmp.js.map",
        "# Reflaxe.Elixir (Haxe client JS stable import target; generated via promotion)",
        "assets/js/hx_app.js",
        "assets/js/hx_app.js.map"
      ])

    content
    |> String.split("\n", trim: false)
    |> Enum.reject(fn line -> MapSet.member?(removal_lines, String.trim(line)) end)
    |> Enum.join("\n")
  end

  defp maybe_remove_empty_dir(path) when is_binary(path) do
    if File.dir?(path) do
      case File.ls(path) do
        {:ok, []} -> File.rmdir(path)
        _ -> :ok
      end
    else
      :ok
    end
  end

  @haxe_lib_stub_signature_prefix "reflaxe_elixir:scaffolded_haxe_library"

  defp ensure_haxe_libraries!(project_root, reflaxe_elixir_dep_path, opts)
       when is_binary(project_root) and
              (is_binary(reflaxe_elixir_dep_path) or is_nil(reflaxe_elixir_dep_path)) do
    verbose = Keyword.get(opts, :verbose, false)

    default_dep_path = Path.join([project_root, "deps", "reflaxe_elixir"])

    # Prefer the dep checkout path if present (portable across machines, works for Hex/git deps,
    # and also for path deps once Mix has created the `deps/` symlink).
    dep_path =
      if File.dir?(default_dep_path) do
        default_dep_path
      else
        reflaxe_elixir_dep_path || default_dep_path
      end

    relative_dep_path =
      if is_binary(dep_path) do
        relative_path(project_root, dep_path)
      else
        "deps/reflaxe_elixir"
      end

    # These .hxml files live in the Phoenix project itself (not in this repo). They are required
    # so client builds can resolve `-lib genes` and `-lib phoenix_js` without needing global haxelib
    # state. The files are signature-managed so reruns can update them without clobbering user edits.
    helder_set_desired = helder_set_hxml()
    genes_desired = genes_hxml(relative_dep_path)
    phoenix_js_desired = phoenix_js_hxml(relative_dep_path)

    ensure_file!(
      Path.join([project_root, "haxe_libraries", "helder.set.hxml"]),
      helder_set_desired,
      verbose: verbose,
      patch: &maybe_patch_scaffolded_file(&1, helder_set_hxml_signature(), helder_set_desired)
    )

    ensure_file!(
      Path.join([project_root, "haxe_libraries", "genes.hxml"]),
      genes_desired,
      verbose: verbose,
      patch: &maybe_patch_scaffolded_file(&1, genes_hxml_signature(), genes_desired)
    )

    ensure_file!(
      Path.join([project_root, "haxe_libraries", "phoenix_js.hxml"]),
      phoenix_js_desired,
      verbose: verbose,
      patch: &maybe_patch_scaffolded_file(&1, phoenix_js_hxml_signature(), phoenix_js_desired)
    )
  end

  defp binary_index(haystack, needle) when is_binary(haystack) and is_binary(needle) do
    case :binary.match(haystack, needle) do
      {pos, _len} -> pos
      :nomatch -> nil
    end
  end

  defp warn_or_raise(message, strict) when is_binary(message) and is_boolean(strict) do
    if strict do
      raise message
    else
      IO.warn(message)
      :warned
    end
  end

  defp relative_path(from_dir, to_dir) when is_binary(from_dir) and is_binary(to_dir) do
    from = Path.expand(from_dir)
    to = Path.expand(to_dir)

    from_parts = Path.split(from)
    to_parts = Path.split(to)

    common_len =
      Enum.zip(from_parts, to_parts)
      |> Enum.take_while(fn {a, b} -> a == b end)
      |> length()

    from_rest = Enum.drop(from_parts, common_len)
    to_rest = Enum.drop(to_parts, common_len)

    up = List.duplicate("..", max(length(from_rest), 0))

    case up ++ to_rest do
      [] -> "."
      parts -> Path.join(parts)
    end
  end

  defp ensure_dir!(path) do
    File.mkdir_p!(path)
  end

  defp ensure_file!(path, content, opts) do
    verbose = Keyword.get(opts, :verbose, false)
    patch_fun = Keyword.fetch!(opts, :patch)

    if File.exists?(path) do
      existing = File.read!(path)
      updated = patch_fun.(existing)

      if updated != existing do
        atomic_write!(path, updated)
        if verbose, do: IO.puts("[scaffold] patched #{path}")
      end
    else
      atomic_write!(path, content)
      if verbose, do: IO.puts("[scaffold] wrote #{path}")
    end
  end

  defp patch_file!(path, patch_fun, opts) do
    verbose = Keyword.get(opts, :verbose, false)

    unless File.exists?(path) do
      # Don't silently ignore missing files; we want generator output to be predictably correct.
      raise "expected file at #{path}"
    end

    existing = File.read!(path)
    updated = patch_fun.(existing)

    if updated != existing do
      atomic_write!(path, updated)
      if verbose, do: IO.puts("[scaffold] patched #{path}")
    end
  end

  defp atomic_write!(path, content) do
    dir = Path.dirname(path)
    base = Path.basename(path)
    tmp = Path.join(dir, ".#{base}.tmp")

    File.write!(tmp, content)
    File.rename!(tmp, path)
  end

  defp maybe_patch_scaffolded_file(existing, signature, desired)
       when is_binary(existing) and is_binary(signature) and is_binary(desired) do
    if String.contains?(existing, signature) do
      desired
    else
      existing
    end
  end

  @build_client_hxml_signature "reflaxe_elixir:build_client_hxml:v1"

  defp maybe_patch_build_client_hxml(content) do
    cond do
      String.contains?(content, @build_client_hxml_signature) ->
        build_client_hxml()

      String.contains?(content, "assets/js/_hx_app_tmp.js") ->
        content

      String.contains?(content, "-js assets/js/hx_app.js") ->
        String.replace(content, "-js assets/js/hx_app.js", "-js assets/js/_hx_app_tmp.js")

      true ->
        # If the user already has a custom `-js` target, don't rewrite it.
        # The rest of the scaffold assumes `assets/js/hx_app.js` is stable and provided via promotion,
        # so we only auto-migrate the common default.
        content
    end
  end

  @hx_app_stub_signature "reflaxe_elixir:hx_app_stub:v1"

  defp normalize_scaffold_content(content) when is_binary(content) do
    content
    |> String.replace("\r\n", "\n")
    |> String.trim()
  end

  defp managed_build_client_hxml?(content) when is_binary(content) do
    normalized = normalize_scaffold_content(content)

    normalized == normalize_scaffold_content(build_client_hxml()) or
      normalized == normalize_scaffold_content(build_client_hxml_legacy())
  end

  defp managed_client_boot_hx?(content) when is_binary(content) do
    normalize_scaffold_content(content) == normalize_scaffold_content(client_boot_hx())
  end

  defp managed_hx_app_stub?(content) when is_binary(content) do
    String.contains?(content, @hx_app_stub_signature)
  end

  defp managed_genes_stub?(content) when is_binary(content) do
    String.contains?(content, genes_hxml_signature())
  end

  defp managed_phoenix_js_stub?(content) when is_binary(content) do
    String.contains?(content, phoenix_js_hxml_signature())
  end

  defp managed_helder_set_stub?(content) when is_binary(content) do
    String.contains?(content, helder_set_hxml_signature())
  end

  defp maybe_patch_hx_app_js_stub(existing) when is_binary(existing) do
    # Only rewrite if this is our stub (so we never clobber user customizations).
    if String.contains?(existing, @hx_app_stub_signature) do
      stable_hx_app_js_stub()
    else
      existing
    end
  end

  defp patch_phoenix_app_js(content, opts) do
    strict = Keyword.get(opts, :strict, true)

    content
    |> upsert_js_import_block(strict: strict)
    |> migrate_legacy_js_hooks_merge_block()
    |> upsert_js_hooks_merge_blocks(strict: strict)
  end

  defp upsert_js_import_block(content, opts) do
    strict = Keyword.get(opts, :strict, true)

    begin_token = "BEGIN reflaxe_elixir hx_app_import"
    end_token = "END reflaxe_elixir hx_app_import"
    desired_lines = [~s(import "./hx_app.js";)]

    case replace_marker_block_lines(content, begin_token, end_token, desired_lines) do
      {:ok, updated} ->
        updated

      :missing ->
        # If the import already exists (but isn't marker-managed), don't duplicate it.
        if String.contains?(content, Enum.at(desired_lines, 0)) do
          content
        else
          lines = String.split(content, "\n", trim: false)

          last_import_index =
            lines
            |> Enum.with_index()
            |> Enum.reduce(-1, fn {line, idx}, acc ->
              trimmed = String.trim_leading(line)

              cond do
                String.starts_with?(trimmed, "import ") -> idx
                trimmed == "" -> acc
                String.starts_with?(trimmed, "//") -> acc
                String.starts_with?(trimmed, "/*") -> acc
                true -> acc
              end
            end)

          insert_at = if last_import_index >= 0, do: last_import_index + 1, else: 0

          block =
            marker_block_lines(begin_token, end_token, desired_lines,
              indent: "",
              comment_prefix: "//"
            )

          List.insert_at(lines, insert_at, Enum.join(block, "\n")) |> Enum.join("\n")
        end

      :error ->
        warn_or_raise(
          "failed to patch assets/js/app.js: malformed reflaxe_elixir marker block (hx_app_import)",
          strict
        )

        content
    end
  end

  defp upsert_js_hooks_merge_blocks(content, opts) do
    strict = Keyword.get(opts, :strict, true)

    begin_token_after_decl = "BEGIN reflaxe_elixir hooks_after_decl"
    end_token_after_decl = "END reflaxe_elixir hooks_after_decl"

    begin_token_property = "BEGIN reflaxe_elixir hooks_property"
    end_token_property = "END reflaxe_elixir hooks_property"

    desired_after_decl = ["Object.assign(Hooks, window.Hooks || {});"]
    desired_property_line = "hooks: window.Hooks || {},"

    # 1) If a hooks property block exists, keep it and ensure it includes `window.Hooks`.
    case replace_marker_block_lines_with(
           content,
           begin_token_property,
           end_token_property,
           fn inner_lines ->
             existing =
               inner_lines
               |> Enum.map(&String.trim/1)
               |> Enum.find(fn line -> line != "" and not String.starts_with?(line, "//") end)

             if is_nil(existing) do
               inner_lines
             else
               case rewrite_hooks_property_line(existing) do
                 nil -> inner_lines
                 rewritten -> [rewritten]
               end
             end
           end
         ) do
      {:ok, updated} ->
        updated

      :missing ->
        # 2) If an after-decl block exists, ensure it's the canonical form.
        case replace_marker_block_lines(
               content,
               begin_token_after_decl,
               end_token_after_decl,
               desired_after_decl
             ) do
          {:ok, updated} ->
            updated

          :missing ->
            lines = String.split(content, "\n", trim: false)

            hooks_decl_index =
              lines
              |> Enum.with_index()
              |> Enum.find_value(fn {line, idx} ->
                trimmed = String.trim_leading(line)

                cond do
                  String.starts_with?(trimmed, "let Hooks") -> idx
                  String.starts_with?(trimmed, "const Hooks") -> idx
                  String.starts_with?(trimmed, "var Hooks") -> idx
                  true -> nil
                end
              end)

            if not is_nil(hooks_decl_index) do
              block =
                marker_block_lines(
                  begin_token_after_decl,
                  end_token_after_decl,
                  desired_after_decl,
                  indent: "",
                  comment_prefix: "//"
                )

              List.insert_at(lines, hooks_decl_index + 1, Enum.join(block, "\n"))
              |> Enum.join("\n")
            else
              hooks_prop_index =
                lines
                |> Enum.with_index()
                |> Enum.find_value(fn {line, idx} ->
                  if String.contains?(line, "hooks:"), do: idx, else: nil
                end)

              if is_nil(hooks_prop_index) do
                case upsert_live_socket_hooks_property(
                       lines,
                       begin_token_property,
                       end_token_property,
                       desired_property_line
                     ) do
                  {:ok, updated_lines} ->
                    Enum.join(updated_lines, "\n")

                  :error ->
                    warn_or_raise(
                      "failed to patch assets/js/app.js: could not find a `Hooks` declaration, a `hooks:` LiveSocket option, or a recognizable LiveSocket options object",
                      strict
                    )

                    content
                end
              else
                original = Enum.at(lines, hooks_prop_index)
                indent = leading_indent(original)
                rewritten = rewrite_hooks_property_line(original)

                if is_nil(rewritten) do
                  warn_or_raise(
                    "failed to patch assets/js/app.js: found `hooks:` but could not rewrite the expression safely",
                    strict
                  )

                  content
                else
                  block =
                    marker_block_lines(begin_token_property, end_token_property, [rewritten],
                      indent: indent,
                      comment_prefix: "//"
                    )

                  List.replace_at(lines, hooks_prop_index, Enum.join(block, "\n"))
                  |> Enum.join("\n")
                end
              end
            end

          :error ->
            warn_or_raise(
              "failed to patch assets/js/app.js: malformed reflaxe_elixir marker block (hooks_after_decl)",
              strict
            )

            content
        end

      :error ->
        warn_or_raise(
          "failed to patch assets/js/app.js: malformed reflaxe_elixir marker block (hooks_property)",
          strict
        )

        content
    end
  end

  defp upsert_live_socket_hooks_property(lines, begin_token, end_token, desired_line)
       when is_list(lines) and is_binary(begin_token) and is_binary(end_token) and
              is_binary(desired_line) do
    live_socket_index =
      lines
      |> Enum.with_index()
      |> Enum.find_value(fn {line, idx} ->
        if String.contains?(line, "new LiveSocket"), do: idx, else: nil
      end)

    if is_nil(live_socket_index) do
      :error
    else
      live_socket_line = Enum.at(lines, live_socket_index)

      cond do
        # Inline empty options object: `new LiveSocket(..., {})`
        Regex.match?(~r/new LiveSocket.*\{\s*\}/, live_socket_line) ->
          indent =
            leading_indent(live_socket_line)
            |> Kernel.<>("  ")

          block =
            marker_block_lines(begin_token, end_token, [desired_line],
              indent: indent,
              comment_prefix: "//"
            )

          replacement =
            live_socket_line
            |> String.replace("{", "{\n" <> Enum.join(block, "\n") <> "\n", global: false)

          updated_lines =
            lines
            |> List.replace_at(live_socket_index, replacement)
            |> Enum.join("\n")
            |> String.split("\n", trim: false)

          {:ok, updated_lines}

        # Multiline options object starting on this line (common in Phoenix templates).
        String.contains?(live_socket_line, "{") ->
          indent =
            lines
            |> Enum.at(live_socket_index + 1, "  ")
            |> leading_indent()
            |> case do
              "" -> "  "
              i -> i
            end

          block =
            marker_block_lines(begin_token, end_token, [desired_line],
              indent: indent,
              comment_prefix: "//"
            )

          {:ok, List.insert_at(lines, live_socket_index + 1, Enum.join(block, "\n"))}

        true ->
          :error
      end
    end
  end

  defp migrate_legacy_js_hooks_merge_block(content) when is_binary(content) do
    legacy_begin = "BEGIN reflaxe_elixir hooks_merge"
    legacy_end = "END reflaxe_elixir hooks_merge"

    if String.contains?(content, legacy_begin) do
      # Legacy marker was used for two different placements (after a `Hooks` declaration vs replacing
      # the LiveSocket `hooks:` property). Infer the correct new block name from the file shape:
      # - If the file declares a `Hooks` variable, treat it as `hooks_after_decl`.
      # - Otherwise treat it as `hooks_property` (modern Phoenix templates inline the hooks map).
      has_hooks_decl =
        String.contains?(content, "\nlet Hooks") or String.contains?(content, "\nconst Hooks") or
          String.contains?(content, "\nvar Hooks")

      {new_begin, new_end} =
        if has_hooks_decl do
          {"BEGIN reflaxe_elixir hooks_after_decl", "END reflaxe_elixir hooks_after_decl"}
        else
          {"BEGIN reflaxe_elixir hooks_property", "END reflaxe_elixir hooks_property"}
        end

      content
      |> String.replace(legacy_begin, new_begin)
      |> String.replace(legacy_end, new_end)
    else
      content
    end
  end

  defp rewrite_hooks_property_line(line) when is_binary(line) do
    # Keep behavior conservative: only rewrite a single-line `hooks:` property.
    # Return nil if the shape isn't recognized.
    trimmed = String.trim(line)

    # Already contains our merge: don't touch it.
    if String.contains?(trimmed, "window.Hooks") do
      String.trim(line)
    else
      has_trailing_comma = String.ends_with?(trimmed, ",")
      trimmed_no_comma = if has_trailing_comma, do: String.slice(trimmed, 0..-2//1), else: trimmed

      case String.split(trimmed_no_comma, "hooks:", parts: 2) do
        [_before, rhs] ->
          rhs_expr = String.trim(rhs)

          # Case 1: object literal (common in Phoenix templates): `hooks: {...colocatedHooks}`
          rhs_trim = String.trim(rhs_expr)

          merged_expr =
            cond do
              String.starts_with?(rhs_trim, "{") and String.ends_with?(rhs_trim, "}") ->
                inner = String.slice(rhs_trim, 1..-2//1)
                inner_trim = String.trim(inner)

                new_inner =
                  if inner_trim == "" do
                    " ...(window.Hooks || {})"
                  else
                    inner <> ", ...(window.Hooks || {})"
                  end

                "{" <> new_inner <> "}"

              rhs_trim != "" ->
                # Case 2: identifier/expression: `hooks: Hooks` or `hooks: someHooks()`
                "{..." <> rhs_trim <> ", ...(window.Hooks || {})}"

              true ->
                nil
            end

          if is_nil(merged_expr) do
            nil
          else
            "hooks: " <> merged_expr <> if(has_trailing_comma, do: ",", else: "")
          end

        _ ->
          nil
      end
    end
  end

  defp patch_dev_exs(content, opts) do
    strict = Keyword.get(opts, :strict, true)

    begin_token = "BEGIN reflaxe_elixir haxe_client"
    end_token = "END reflaxe_elixir haxe_client"

    desired_lines = [
      "# Haxe client JS build:",
      "# - Compiles to assets/js/_hx_app_tmp.js (temp output Haxe may delete during rebuilds).",
      "# - Promotes to assets/js/hx_app.js (stable import path for esbuild --watch).",
      "haxe_client: [",
      "  \"mix\",",
      "  \"haxe.watch\",",
      "  \"--hxml\",",
      "  \"build-client.hxml\",",
      "  \"--dirs\",",
      "  \"src_haxe\",",
      "  \"--debounce\",",
      "  \"150\",",
      "  \"--promote\",",
      "  \"assets/js/_hx_app_tmp.js:assets/js/hx_app.js,assets/js/_hx_app_tmp.js.map:assets/js/hx_app.js.map\",",
      "  cd: Path.expand(\"../\", __DIR__)",
      "],"
    ]

    # If the entry already exists (but isn't marker-managed), do not silently no-op. Strict mode
    # must fail fast so users don't think they're scaffolded but actually drift from the expected
    # watcher shape (promotion spec, debounce, etc.).
    if String.contains?(content, "haxe_client: [") and
         not String.contains?(content, begin_token) and
         not String.contains?(content, end_token) do
      warn_or_raise(
        "failed to patch config/dev.exs: found an existing haxe_client watcher entry, but it is not marker-managed.\n" <>
          "Remove the existing haxe_client watcher and re-run `mix haxe.phoenix.scaffold`, or wrap it in a marker block:\n" <>
          "  # #{begin_token}\n" <>
          "  ...\n" <>
          "  # #{end_token}",
        strict
      )

      content
    else
      case replace_marker_block_lines(content, begin_token, end_token, desired_lines) do
        {:ok, updated} ->
          updated

        :missing ->
          # Be tolerant to formatter drift (space/no-space) while still anchoring to the canonical Phoenix key.
          # We intentionally keep the insertion inside the watchers list so the diff is obvious and removable.
          idx =
            case Regex.run(~r/watchers:\s*\[/, content, return: :index) do
              [{pos, len} | _] -> {pos, len}
              _ -> nil
            end

          if is_nil(idx) do
            warn_or_raise(
              "failed to patch config/dev.exs: could not find a `watchers:` list (expected Phoenix dev.exs shape). Re-run with --warn-only to skip.",
              strict
            )

            content
          else
            {pos, len} = idx
            insert_at = pos + len

            insertion =
              "\n\n" <>
                Enum.join(
                  marker_block_lines(begin_token, end_token, desired_lines,
                    indent: "    ",
                    comment_prefix: "#"
                  ),
                  "\n"
                ) <>
                "\n"

            String.slice(content, 0, insert_at) <>
              insertion <> String.slice(content, insert_at..-1//1)
          end

        :error ->
          warn_or_raise(
            "failed to patch config/dev.exs: malformed reflaxe_elixir marker block (haxe_client)",
            strict
          )

          content
      end
    end
  end

  defp patch_mix_exs(content, opts) do
    strict = Keyword.get(opts, :strict, true)

    content
    |> upsert_haxe_compile_client_alias(strict: strict)
    |> upsert_assets_alias_task_marker("assets.build", strict: strict)
    |> upsert_assets_alias_task_marker("assets.deploy", strict: strict)
  end

  defp upsert_haxe_compile_client_alias(content, opts) do
    strict = Keyword.get(opts, :strict, true)

    begin_token = "BEGIN reflaxe_elixir haxe_compile_client_alias"
    end_token = "END reflaxe_elixir haxe_compile_client_alias"

    desired_lines = [
      "\"haxe.compile.client\": [",
      "  \"haxe.watch --once --hxml build-client.hxml --dirs src_haxe --promote assets/js/_hx_app_tmp.js:assets/js/hx_app.js,assets/js/_hx_app_tmp.js.map:assets/js/hx_app.js.map\"",
      "],"
    ]

    # If the alias already exists (but isn't marker-managed), do not silently no-op. The promote
    # spec is part of the scaffold contract; strict mode must fail fast on drift.
    if String.contains?(content, "\"haxe.compile.client\":") and
         not String.contains?(content, begin_token) and
         not String.contains?(content, end_token) do
      warn_or_raise(
        "failed to patch mix.exs: found an existing \"haxe.compile.client\" alias, but it is not marker-managed.\n" <>
          "Remove the existing alias and re-run `mix haxe.phoenix.scaffold`, or wrap it in a marker block:\n" <>
          "  # #{begin_token}\n" <>
          "  ...\n" <>
          "  # #{end_token}",
        strict
      )

      content
    else
      case replace_marker_block_lines(content, begin_token, end_token, desired_lines) do
        {:ok, updated} ->
          updated

        :missing ->
          idx =
            case Regex.run(~r/\bdefp\s+aliases\b/, content, return: :index) do
              [{pos, _len} | _] ->
                pos

              _ ->
                case Regex.run(~r/\bdef\s+aliases\b/, content, return: :index) do
                  [{pos2, _len2} | _] -> pos2
                  _ -> nil
                end
            end

          if is_nil(idx) do
            warn_or_raise(
              "failed to patch mix.exs: could not find an `aliases` function (expected Phoenix mix.exs shape). Re-run with --warn-only to skip.",
              strict
            )

            content
          else
            after_aliases = String.slice(content, idx..-1//1)
            list_open_idx = binary_index(after_aliases, "[")

            if is_nil(list_open_idx) do
              warn_or_raise(
                "failed to patch mix.exs: could not locate aliases list `[` after `defp aliases`",
                strict
              )

              content
            else
              insert_at = idx + list_open_idx + 1

              insertion =
                "\n\n" <>
                  Enum.join(
                    marker_block_lines(begin_token, end_token, desired_lines,
                      indent: "        ",
                      comment_prefix: "#"
                    ),
                    "\n"
                  ) <>
                  "\n"

              String.slice(content, 0, insert_at) <>
                insertion <> String.slice(content, insert_at..-1//1)
            end
          end

        :error ->
          warn_or_raise(
            "failed to patch mix.exs: malformed reflaxe_elixir marker block (haxe_compile_client_alias)",
            strict
          )

          content
      end
    end
  end

  defp upsert_assets_alias_task_marker(content, alias_name, opts) do
    strict = Keyword.get(opts, :strict, true)

    begin_token = "BEGIN reflaxe_elixir #{alias_name}_task"
    end_token = "END reflaxe_elixir #{alias_name}_task"
    desired_lines = ["\"haxe.compile.client\","]

    # If the task is already present (but isn't marker-managed), don't duplicate it.
    already_present =
      Regex.match?(
        ~r/"#{Regex.escape(alias_name)}"\s*:\s*\[[^\]]*"haxe\.compile\.client"/s,
        content
      )

    if already_present and
         not String.contains?(content, begin_token) and
         not String.contains?(content, end_token) do
      content
    else
      case replace_marker_block_lines(content, begin_token, end_token, desired_lines) do
        {:ok, updated} ->
          updated

        :missing ->
          pattern = ~r/"#{Regex.escape(alias_name)}"\s*:\s*\[/

          match =
            case Regex.run(pattern, content, return: :index) do
              [{pos, len} | _] -> {pos, len}
              _ -> nil
            end

          if is_nil(match) do
            warn_or_raise(
              "failed to patch mix.exs: could not find an #{inspect(alias_name)} alias entry (expected \\\"#{alias_name}\\\": [ ... ] shape).",
              strict
            )

            content
          else
            {pos, len} = match
            insert_at = pos + len
            remainder = String.slice(content, insert_at..-1//1)
            remainder_indent = if String.starts_with?(remainder, "\n"), do: "", else: "\n        "

            insertion =
              "\n\n" <>
                Enum.join(
                  marker_block_lines(begin_token, end_token, desired_lines,
                    indent: "        ",
                    comment_prefix: "#"
                  ),
                  "\n"
                ) <>
                remainder_indent

            String.slice(content, 0, insert_at) <> insertion <> remainder
          end

        :error ->
          warn_or_raise(
            "failed to patch mix.exs: malformed reflaxe_elixir marker block (#{alias_name})",
            strict
          )

          content
      end
    end
  end

  defp patch_gitignore(content) do
    entries = [
      {"# Reflaxe.Elixir (Haxe client JS intermediate output)", "assets/js/_hx_app_tmp.js"},
      {nil, "assets/js/_hx_app_tmp.js.map"},
      {"# Reflaxe.Elixir (Haxe client JS stable import target; generated via promotion)",
       "assets/js/hx_app.js"},
      {nil, "assets/js/hx_app.js.map"}
    ]

    missing =
      entries
      |> Enum.reject(fn {_comment, path} -> String.contains?(content, path) end)

    if missing == [] do
      content
    else
      lines =
        missing
        |> Enum.flat_map(fn {comment, path} ->
          case comment do
            nil -> [path]
            _ -> [comment, path]
          end
        end)

      content <> "\n\n" <> Enum.join(lines, "\n") <> "\n"
    end
  end

  defp replace_marker_block_lines(content, begin_token, end_token, desired_lines)
       when is_binary(content) and is_binary(begin_token) and is_binary(end_token) and
              is_list(desired_lines) do
    lines = String.split(content, "\n", trim: false)

    begin_index =
      Enum.find_index(lines, fn line ->
        String.contains?(line, begin_token)
      end)

    if is_nil(begin_index) do
      :missing
    else
      end_index =
        lines
        |> Enum.with_index()
        |> Enum.find_value(fn {line, idx} ->
          if idx > begin_index and String.contains?(line, end_token), do: idx, else: nil
        end)

      if is_nil(end_index) do
        :error
      else
        begin_line = Enum.at(lines, begin_index)
        end_line = Enum.at(lines, end_index)
        indent = leading_indent(begin_line)

        replacement =
          [begin_line]
          |> Kernel.++(Enum.map(desired_lines, fn l -> indent <> l end))
          |> Kernel.++([end_line])

        updated =
          lines
          |> Enum.with_index()
          |> Enum.flat_map(fn {line, idx} ->
            cond do
              idx < begin_index -> [line]
              idx == begin_index -> replacement
              idx > begin_index and idx < end_index -> []
              idx == end_index -> []
              true -> [line]
            end
          end)

        {:ok, Enum.join(updated, "\n")}
      end
    end
  end

  defp remove_marker_block_lines(content, begin_token, end_token)
       when is_binary(content) and is_binary(begin_token) and is_binary(end_token) do
    lines = String.split(content, "\n", trim: false)

    begin_index =
      Enum.find_index(lines, fn line ->
        String.contains?(line, begin_token)
      end)

    if is_nil(begin_index) do
      :missing
    else
      end_index =
        lines
        |> Enum.with_index()
        |> Enum.find_value(fn {line, idx} ->
          if idx > begin_index and String.contains?(line, end_token), do: idx, else: nil
        end)

      if is_nil(end_index) do
        :error
      else
        updated =
          lines
          |> Enum.with_index()
          |> Enum.reject(fn {_line, idx} -> idx >= begin_index and idx <= end_index end)
          |> Enum.map(fn {line, _idx} -> line end)
          |> Enum.join("\n")

        {:ok, updated}
      end
    end
  end

  defp replace_marker_block_lines_with(content, begin_token, end_token, fun)
       when is_binary(content) and is_binary(begin_token) and is_binary(end_token) and
              is_function(fun, 1) do
    lines = String.split(content, "\n", trim: false)

    begin_index =
      Enum.find_index(lines, fn line ->
        String.contains?(line, begin_token)
      end)

    if is_nil(begin_index) do
      :missing
    else
      end_index =
        lines
        |> Enum.with_index()
        |> Enum.find_value(fn {line, idx} ->
          if idx > begin_index and String.contains?(line, end_token), do: idx, else: nil
        end)

      if is_nil(end_index) do
        :error
      else
        begin_line = Enum.at(lines, begin_index)
        end_line = Enum.at(lines, end_index)
        indent = leading_indent(begin_line)

        existing_inner = Enum.slice(lines, begin_index + 1, end_index - begin_index - 1)
        desired_inner = fun.(existing_inner)

        replacement =
          [begin_line]
          |> Kernel.++(Enum.map(desired_inner, fn l -> indent <> String.trim_leading(l) end))
          |> Kernel.++([end_line])

        updated =
          lines
          |> Enum.with_index()
          |> Enum.flat_map(fn {line, idx} ->
            cond do
              idx < begin_index -> [line]
              idx == begin_index -> replacement
              idx > begin_index and idx < end_index -> []
              idx == end_index -> []
              true -> [line]
            end
          end)

        {:ok, Enum.join(updated, "\n")}
      end
    end
  end

  defp marker_block_lines(begin_token, end_token, desired_lines, opts) do
    indent = Keyword.get(opts, :indent, "")
    comment_prefix = Keyword.get(opts, :comment_prefix, "#")

    begin_line = indent <> comment_prefix <> " " <> begin_token
    end_line = indent <> comment_prefix <> " " <> end_token

    [begin_line]
    |> Kernel.++(Enum.map(desired_lines, fn l -> indent <> l end))
    |> Kernel.++([end_line])
  end

  defp leading_indent(line) when is_binary(line) do
    line
    |> String.graphemes()
    |> Enum.take_while(fn ch -> ch == " " or ch == "\t" end)
    |> Enum.join()
  end

  defp build_client_hxml do
    """
    # Haxe→JavaScript compilation for Phoenix LiveView client-side code
    # Generates ES6 modules compatible with esbuild

    # Source directories (client only)
    -cp src_haxe/client
    -cp src_haxe
    # Enable Genes ES6 module generator (uses haxe_libraries/genes.hxml)
    -lib genes
    # Typed Phoenix JS externs (Channels + LiveView)
    -lib phoenix_js

    # NOTE: Our vendored `-lib genes` does not automatically apply genes/extraParams.hxml,
    # so we explicitly enable the generator here.
    -D js-es=6
    --macro genes.Generator.use()
    --macro addMetadata('@:genes.disableNativeAccessors', 'haxe.Exception')

    # JavaScript target output
    #
    # IMPORTANT:
    # Haxe deletes the `-js` output file at the start of compilation. Since Phoenix runs esbuild in
    # `--watch` mode and `assets/js/app.js` imports `./hx_app.js`, that temporary deletion can race
    # esbuild and produce transient "Could not resolve ./hx_app.js" errors.
    #
    # To keep esbuild stable in watch mode, compile into a temporary entry file and then promote
    # it into a stable path used by esbuild imports:
    # - Haxe writes `assets/js/_hx_app_tmp.js` (and deletes it during rebuilds).
    # - A watcher promotes that output into the stable `assets/js/hx_app.js` path atomically.
    -js assets/js/_hx_app_tmp.js
    -D js-unflatten
    --dce=full

    # Haxe 4.3+ optimizations
    -D real-position
    -D js-source-map

    # Exclude server code from client compilation
    --macro exclude('server')

    # Main client entry point
    -main client.Boot
    """
  end

  defp build_client_hxml_legacy do
    build_client_hxml()
    |> String.replace(
      "To keep esbuild stable in watch mode, compile into a temporary entry file and then promote\n    # it into a stable path used by esbuild imports:\n    # - Haxe writes `assets/js/_hx_app_tmp.js` (and deletes it during rebuilds).\n    # - A watcher promotes that output into the stable `assets/js/hx_app.js` path atomically.\n    ",
      ""
    )
    |> String.replace("-js assets/js/_hx_app_tmp.js", "-js assets/js/hx_app.js")
  end

  defp helder_set_hxml_signature do
    "#{@haxe_lib_stub_signature_prefix}:helder.set:v1"
  end

  defp genes_hxml_signature do
    "#{@haxe_lib_stub_signature_prefix}:genes:v1"
  end

  defp phoenix_js_hxml_signature do
    "#{@haxe_lib_stub_signature_prefix}:phoenix_js:v1"
  end

  defp helder_set_hxml do
    """
    # #{helder_set_hxml_signature()}
    # helder.set — small Set<T> abstraction used by genes
    #
    # This file is scaffold-managed by `mix haxe.phoenix.scaffold`. If you customize it, remove
    # the signature line above to opt out of future updates.

    # @install: lix --silent download "haxelib:/helder.set#0.3.1" into helder.set/0.3.1/haxelib
    -cp ${HAXE_LIBCACHE}/helder.set/0.3.1/haxelib/src
    -D helder.set=0.3.1
    """
  end

  defp genes_hxml(reflaxe_elixir_rel_path) when is_binary(reflaxe_elixir_rel_path) do
    """
    # #{genes_hxml_signature()}
    # genes — ES6 JavaScript generator (vendored inside reflaxe_elixir)
    #
    # This file is scaffold-managed by `mix haxe.phoenix.scaffold`. If you customize it, remove
    # the signature line above to opt out of future updates.

    # genes core sources (vendored)
    -cp ${SCOPE_DIR}/#{reflaxe_elixir_rel_path}/vendor/genes/src

    # genes depends on helder.set for its Set<T> abstraction
    -lib helder.set

    # Library define for conditional compilation flags
    -D genes=0.4.14
    """
  end

  defp phoenix_js_hxml(reflaxe_elixir_rel_path) when is_binary(reflaxe_elixir_rel_path) do
    """
    # #{phoenix_js_hxml_signature()}
    # phoenix_js — Phoenix Channels + LiveView JS externs (vendored inside reflaxe_elixir)
    #
    # This file is scaffold-managed by `mix haxe.phoenix.scaffold`. If you customize it, remove
    # the signature line above to opt out of future updates.

    -cp ${SCOPE_DIR}/#{reflaxe_elixir_rel_path}/vendor/phoenix_js/src
    -cp ${SCOPE_DIR}/#{reflaxe_elixir_rel_path}/vendor/phoenix_shared/src

    # Library define for conditional compilation flags
    -D phoenix_js=0.1.0
    """
  end

  defp client_boot_hx do
    """
    package client;

    import js.Syntax;

    /**
     * Client entrypoint compiled to JS via Genes (ES modules).
     *
     * Publish a stable `window.Hooks` registry for Phoenix LiveView.
     * Your app can merge additional hooks into this object.
     */
    class Boot {
      public static function main(): Void {
        Syntax.code("window.Hooks = window.Hooks || {}");
      }
    }
    """
  end

  defp stable_hx_app_js_stub do
    """
    // #{@hx_app_stub_signature}
    //
    // Stable import path for the Haxe client bundle.
    // During development, `mix haxe.watch --hxml build-client.hxml --promote ...` replaces this file atomically.
    export {};
    """
  end
end

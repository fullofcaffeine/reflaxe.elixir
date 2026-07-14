defmodule HaxeGeneratedOutput do
  @moduledoc """
  Fail-closed ownership and cleanup for Haxe-generated Elixir files.

  `_GeneratedFiles.json` is the only authority for generated paths. Version 1
  Reflaxe manifests are accepted for upgrades; version 2 additionally records a
  SHA-256 digest for every owned file. Cleanup and recovery never discover files
  by scanning source text or directory contents.

  The Haxe-side publisher commits its manifest last. If compilation is
  interrupted, `recover/1` either restores the previous files and manifest or,
  when the new manifest already committed, removes only transaction artifacts.
  """

  @manifest_filename "_GeneratedFiles.json"
  @protocol "reflaxe-elixir/generated-output"
  @transaction_protocol "reflaxe-elixir/generated-output-transaction"
  @manifest_version 2
  @transaction_version 2
  @prepare_directory "._GeneratedFiles.prepare"
  @transaction_directory "._GeneratedFiles.transaction"
  @manifest_temp_filename "._GeneratedFiles.json.new"
  @owner_filename "owner"
  @journal_filename "journal.json"
  @previous_manifest_filename "previous_manifest.json"
  @next_manifest_filename "next_manifest.json"
  @backup_directory "backups"
  @owner_marker "reflaxe.elixir generated-output transaction v2\n"
  @output_temp_suffix ".__reflaxe_output_new__"

  @type ownership :: %{
          exists: boolean(),
          legacy: boolean(),
          id: non_neg_integer(),
          paths: [binary()],
          digests: %{optional(binary()) => binary()}
        }

  @doc "Returns the canonical ownership manifest path for an output root."
  @spec manifest_path(Path.t()) :: Path.t()
  def manifest_path(output_directory) do
    output_directory
    |> Path.expand()
    |> Path.join(@manifest_filename)
  end

  @doc """
  Returns generated files from the ownership manifest after validating its
  schema, path containment, and version 2 content digests.

  A missing manifest means no files are owned and returns an empty list. The
  function deliberately never falls back to scanning `*.ex` or source markers.
  """
  @spec generated_files(Path.t()) :: {:ok, [Path.t()]} | {:error, binary()}
  def generated_files(output_directory) do
    root = Path.expand(output_directory)

    with :ok <- recover(root),
         {:ok, ownership} <- read_ownership(root),
         :ok <- verify_owned_files(root, ownership) do
      {:ok, Enum.map(ownership.paths, &Path.join(root, &1))}
    end
  end

  @doc """
  Removes only manifest-owned files and then removes the manifest.

  Every path and digest is preflighted before the first deletion. A modified
  version 2 file, malformed manifest, symlink, or path escape fails the entire
  clean operation without deleting another owned file.
  """
  @spec clean(Path.t()) :: {:ok, non_neg_integer()} | {:error, binary()}
  def clean(output_directory) do
    root = Path.expand(output_directory)

    with :ok <- recover(root),
         {:ok, ownership} <- read_ownership(root),
         :ok <- verify_owned_files(root, ownership),
         :ok <- remove_owned_files(root, ownership.paths),
         :ok <- remove_manifest(root, ownership.exists) do
      prune_empty_owned_directories(root, ownership.paths)
      {:ok, length(ownership.paths)}
    end
  end

  @doc """
  Resolves interrupted Haxe publication state without scanning user files.

  Prepared-but-not-activated output is discarded. An active transaction is
  rolled back unless its exact next manifest is already live, in which case the
  generated files are committed and only transaction artifacts are removed.
  """
  @spec recover(Path.t()) :: :ok | {:error, binary()}
  def recover(output_directory) do
    root = Path.expand(output_directory)

    cond do
      not File.exists?(root) ->
        :ok

      not File.dir?(root) ->
        {:error, "Generated output root is not a directory: #{root}"}

      true ->
        active = Path.join(root, @transaction_directory)
        prepare = Path.join(root, @prepare_directory)

        with :ok <- recover_active_if_present(root, active),
             :ok <- remove_prepare_if_present(root, prepare),
             :ok <- reject_orphan_manifest_temp(root) do
          :ok
        end
    end
  rescue
    error -> {:error, Exception.message(error)}
  end

  defp read_ownership(output_directory) do
    root = Path.expand(output_directory)
    path = Path.join(root, @manifest_filename)

    case File.lstat(path) do
      {:error, :enoent} ->
        {:ok, %{exists: false, legacy: false, id: 0, paths: [], digests: %{}}}

      {:ok, %File.Stat{type: :regular}} ->
        with {:ok, content} <- File.read(path),
             {:ok, json} <- decode_json(content, "ownership manifest #{path}"),
             {:ok, ownership} <- validate_manifest(json, path) do
          {:ok, ownership}
        end

      {:ok, %File.Stat{type: type}} ->
        {:error, "Generated-output ownership manifest is not a regular file (#{type}): #{path}"}

      {:error, reason} ->
        {:error,
         "Cannot inspect generated-output ownership manifest #{path}: #{format_reason(reason)}"}
    end
  end

  defp validate_manifest(json, path) when is_map(json) do
    with {:ok, version} <- required_integer(json, "version", path),
         {:ok, id} <- required_integer(json, "id", path),
         {:ok, paths} <- required_paths(json, "filesGenerated", path) do
      case version do
        1 ->
          {:ok, %{exists: true, legacy: true, id: id, paths: paths, digests: %{}}}

        @manifest_version ->
          validate_v2_manifest(json, path, id, paths)

        unsupported ->
          {:error,
           "Unsupported generated-output ownership manifest version #{inspect(unsupported)}: #{path}"}
      end
    end
  end

  defp validate_manifest(_json, path),
    do: {:error, "Generated-output ownership manifest must contain a JSON object: #{path}"}

  defp validate_v2_manifest(json, path, id, paths) do
    with {:ok, @protocol} <- required_string(json, "protocol", path),
         {:ok, owned_values} <- required_list(json, "ownedFiles", path),
         {:ok, records, digests} <- validate_owned_records(owned_values, path),
         :ok <- require_same_owned_paths(paths, records, path),
         {:ok, generation} <- required_string(json, "generation", path),
         :ok <- require_generation_digest(generation, records, path) do
      {:ok, %{exists: true, legacy: false, id: id, paths: paths, digests: digests}}
    else
      {:ok, unexpected} ->
        {:error, "Unexpected generated-output ownership protocol #{inspect(unexpected)}: #{path}"}

      other ->
        other
    end
  end

  defp validate_owned_records(values, location) do
    Enum.reduce_while(values, {:ok, [], %{}}, fn value, {:ok, records, digests} ->
      with true <- is_map(value),
           {:ok, path} <- required_string(value, "path", location),
           {:ok, path} <- validate_relative_path(path, "owned manifest path"),
           false <- Map.has_key?(digests, path),
           {:ok, digest} <- required_string(value, "sha256", location),
           digest <- String.downcase(digest),
           true <- valid_sha256?(digest) do
        {:cont, {:ok, [%{path: path, sha256: digest} | records], Map.put(digests, path, digest)}}
      else
        false when is_map(value) ->
          {:halt, {:error, "Generated-output manifest owns a path more than once: #{location}"}}

        _ ->
          {:halt,
           {:error, "Generated-output manifest has an invalid owned-file record: #{location}"}}
      end
    end)
    |> case do
      {:ok, records, digests} -> {:ok, Enum.reverse(records), digests}
      error -> error
    end
  end

  defp require_same_owned_paths(paths, records, location) do
    record_paths = Enum.map(records, & &1.path)

    if length(paths) == length(record_paths) and MapSet.new(paths) == MapSet.new(record_paths) do
      :ok
    else
      {:error, "Generated-output manifest path and digest sets differ: #{location}"}
    end
  end

  defp require_generation_digest(generation, records, location) do
    expected =
      records
      |> Enum.sort_by(& &1.path)
      |> Enum.map_join(fn record -> record.path <> "\n" <> record.sha256 <> "\n" end)
      |> sha256()

    if String.downcase(generation) == expected do
      :ok
    else
      {:error,
       "Generated-output manifest generation digest does not match its files: #{location}"}
    end
  end

  defp verify_owned_files(_root, %{exists: false}), do: :ok

  defp verify_owned_files(root, ownership) do
    Enum.reduce_while(ownership.paths, :ok, fn relative, :ok ->
      with {:ok, target} <- safe_target(root, relative),
           {:ok, stat_or_missing} <- lstat_or_missing(target),
           :ok <- verify_owned_file_type(target, stat_or_missing),
           :ok <- verify_owned_digest(target, relative, stat_or_missing, ownership) do
        {:cont, :ok}
      else
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp verify_owned_file_type(_target, :missing), do: :ok
  defp verify_owned_file_type(_target, %File.Stat{type: :regular}), do: :ok

  defp verify_owned_file_type(target, %File.Stat{type: type}),
    do: {:error, "Owned generated output is not a regular file (#{type}): #{target}"}

  defp verify_owned_digest(_target, _relative, :missing, _ownership), do: :ok
  defp verify_owned_digest(_target, _relative, _stat, %{legacy: true}), do: :ok

  defp verify_owned_digest(target, relative, _stat, ownership) do
    expected = Map.get(ownership.digests, relative)

    with digest when is_binary(digest) <- expected,
         {:ok, actual} <- hash_file(target),
         true <- actual == digest do
      :ok
    else
      _ ->
        {:error,
         "Owned generated output was modified outside the compiler: #{target}. Refusing to overwrite or delete it."}
    end
  end

  defp remove_owned_files(root, paths) do
    Enum.reduce_while(paths, :ok, fn relative, :ok ->
      with {:ok, target} <- safe_target(root, relative),
           {:ok, stat_or_missing} <- lstat_or_missing(target),
           :ok <- remove_regular_or_missing(target, stat_or_missing) do
        {:cont, :ok}
      else
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp remove_regular_or_missing(_path, :missing), do: :ok

  defp remove_regular_or_missing(path, %File.Stat{type: :regular}),
    do: file_result(File.rm(path), path)

  defp remove_regular_or_missing(path, %File.Stat{type: type}),
    do: {:error, "Refusing to remove non-regular owned output (#{type}): #{path}"}

  defp remove_manifest(_root, false), do: :ok

  defp remove_manifest(root, true) do
    path = Path.join(root, @manifest_filename)

    case File.lstat(path) do
      {:ok, %File.Stat{type: :regular}} ->
        file_result(File.rm(path), path)

      {:ok, %File.Stat{type: type}} ->
        {:error, "Refusing to remove non-regular manifest (#{type}): #{path}"}

      {:error, :enoent} ->
        :ok

      {:error, reason} ->
        {:error, "Cannot inspect generated-output manifest #{path}: #{format_reason(reason)}"}
    end
  end

  defp prune_empty_owned_directories(root, paths) do
    paths
    |> Enum.flat_map(fn relative ->
      relative
      |> Path.dirname()
      |> parent_paths()
    end)
    |> Enum.uniq()
    |> Enum.sort_by(&path_depth/1, :desc)
    |> Enum.each(fn relative ->
      case safe_target(root, relative) do
        {:ok, directory} ->
          case File.lstat(directory) do
            {:ok, %File.Stat{type: :directory}} -> _ = File.rmdir(directory)
            _ -> :ok
          end

        _ ->
          :ok
      end
    end)
  end

  defp parent_paths("."), do: []

  defp parent_paths(path) do
    Stream.unfold(path, fn
      "." -> nil
      current -> {current, Path.dirname(current)}
    end)
    |> Enum.to_list()
  end

  defp path_depth(path), do: path |> Path.split() |> length()

  defp recover_active_if_present(root, active) do
    case File.lstat(active) do
      {:error, :enoent} ->
        :ok

      {:ok, _stat} ->
        recover_active(root, active)

      {:error, reason} ->
        {:error, "Cannot inspect transaction path #{active}: #{format_reason(reason)}"}
    end
  end

  defp remove_prepare_if_present(root, prepare) do
    case File.lstat(prepare) do
      {:error, :enoent} ->
        :ok

      {:ok, _stat} ->
        with :ok <- validate_control_directory(root, prepare),
             :ok <- safe_remove_tree(prepare) do
          :ok
        end

      {:error, reason} ->
        {:error, "Cannot inspect prepare path #{prepare}: #{format_reason(reason)}"}
    end
  end

  defp reject_orphan_manifest_temp(root) do
    path = Path.join(root, @manifest_temp_filename)

    case File.lstat(path) do
      {:error, :enoent} ->
        :ok

      {:ok, _stat} ->
        {:error,
         "Reserved generated-output manifest path exists without a recoverable transaction: #{path}"}

      {:error, reason} ->
        {:error, "Cannot inspect reserved manifest path #{path}: #{format_reason(reason)}"}
    end
  end

  defp recover_active(root, active) do
    with :ok <- validate_control_directory(root, active),
         {:ok, journal} <- read_journal(active),
         next_manifest = Path.join(active, @next_manifest_filename),
         {:ok, next_digest} <- hash_regular_file(next_manifest),
         :ok <- require_equal_digest(next_digest, journal.next_manifest_sha256, next_manifest) do
      manifest = Path.join(root, @manifest_filename)

      case hash_regular_file(manifest) do
        {:ok, ^next_digest} ->
          with :ok <- remove_transaction_temps(root, journal),
               :ok <- safe_remove_tree(active) do
            :ok
          end

        _ ->
          rollback_active(root, active, journal)
      end
    end
  end

  defp rollback_active(root, active, journal) do
    backups = Path.join(active, @backup_directory)

    with :ok <- preflight_rollback(root, active, journal),
         :ok <- rollback_transaction_paths(root, backups, journal.paths),
         :ok <- rollback_manifest(root, active, journal),
         :ok <- safe_remove_tree(active) do
      :ok
    end
  end

  defp preflight_rollback(root, active, journal) do
    backups = Path.join(active, @backup_directory)

    with :ok <- preflight_rollback_paths(root, backups, journal.paths),
         :ok <- preflight_rollback_manifest(root, active, journal) do
      :ok
    end
  end

  defp preflight_rollback_paths(root, backups, entries) do
    entries
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {entry, index}, :ok ->
      with {:ok, target} <- safe_target(root, entry.path),
           {:ok, temp} <- safe_target(root, entry.temp_path),
           :ok <- preflight_transaction_temp(temp, entry.next_sha256),
           :ok <- preflight_backup(Path.join(backups, Integer.to_string(index)), entry),
           :ok <- validate_rollback_target(target, entry) do
        {:cont, :ok}
      else
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp preflight_backup(_backup, %{had_previous: false}), do: :ok

  defp preflight_backup(backup, %{previous_sha256: previous_sha256}) do
    with {:ok, actual} <- hash_regular_file(backup),
         :ok <- require_equal_digest(actual, previous_sha256, backup) do
      :ok
    end
  end

  defp validate_rollback_target(target, %{had_previous: true} = entry) do
    with {:ok, current} <- hash_regular_or_missing(target),
         true <-
           current == :missing or current == entry.previous_sha256 or
             (is_binary(entry.next_sha256) and current == entry.next_sha256) do
      :ok
    else
      false ->
        {:error,
         "Generated output changed after the interrupted publication: #{target}. Refusing to overwrite the unexpected bytes during rollback."}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp validate_rollback_target(target, %{had_previous: false} = entry) do
    with {:ok, current} <- hash_regular_or_missing(target),
         true <- current == :missing or current == entry.next_sha256 do
      :ok
    else
      false ->
        {:error,
         "Unowned or modified output occupies an interrupted publication path: #{target}. Refusing to delete it during rollback."}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp preflight_rollback_manifest(root, active, journal) do
    target = Path.join(root, @manifest_filename)
    temp = Path.join(root, @manifest_temp_filename)

    with :ok <- preflight_transaction_temp(temp, journal.next_manifest_sha256),
         :ok <- preflight_previous_manifest(active, journal),
         :ok <- validate_rollback_manifest_target(target, journal) do
      :ok
    end
  end

  defp preflight_previous_manifest(_active, %{previous_manifest: false}), do: :ok

  defp preflight_previous_manifest(active, journal) do
    previous = Path.join(active, @previous_manifest_filename)

    with {:ok, actual} <- hash_regular_file(previous),
         :ok <- require_equal_digest(actual, journal.previous_manifest_sha256, previous) do
      :ok
    end
  end

  defp validate_rollback_manifest_target(target, %{previous_manifest: true} = journal) do
    with {:ok, current} <- hash_regular_or_missing(target),
         true <-
           current == :missing or current == journal.previous_manifest_sha256 or
             current == journal.next_manifest_sha256 do
      :ok
    else
      false ->
        {:error,
         "Generated-output ownership manifest changed after interrupted publication: #{target}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp validate_rollback_manifest_target(target, %{previous_manifest: false} = journal) do
    with {:ok, current} <- hash_regular_or_missing(target),
         true <- current == :missing or current == journal.next_manifest_sha256 do
      :ok
    else
      false ->
        {:error, "Unowned manifest occupies an interrupted publication path: #{target}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp rollback_transaction_paths(root, backups, entries) do
    entries
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {entry, index}, :ok ->
      with {:ok, target} <- safe_target(root, entry.path),
           {:ok, temp} <- safe_target(root, entry.temp_path),
           :ok <- remove_transaction_temp(temp, entry.next_sha256),
           :ok <-
             rollback_one_path(
               target,
               temp,
               Path.join(backups, Integer.to_string(index)),
               entry
             ) do
        {:cont, :ok}
      else
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp rollback_one_path(target, temp, backup, %{had_previous: true} = entry) do
    with :ok <- preflight_backup(backup, entry),
         :ok <- validate_rollback_target(target, entry),
         {:ok, current} <- hash_regular_or_missing(target) do
      if current == entry.previous_sha256 do
        :ok
      else
        with :ok <- ensure_parent_directory(target),
             :ok <- file_result(File.cp(backup, temp), temp),
             {:ok, copied} <- hash_regular_file(temp),
             :ok <- require_equal_digest(copied, entry.previous_sha256, temp),
             :ok <- validate_rollback_target(target, entry),
             :ok <- replace_file(temp, target) do
          :ok
        end
      end
    end
  end

  defp rollback_one_path(target, _temp, _backup, %{had_previous: false} = entry) do
    with :ok <- validate_rollback_target(target, entry),
         {:ok, current} <- hash_regular_or_missing(target) do
      case current do
        :missing -> :ok
        digest when digest == entry.next_sha256 -> file_result(File.rm(target), target)
      end
    end
  end

  defp rollback_manifest(root, active, %{previous_manifest: true} = journal) do
    previous = Path.join(active, @previous_manifest_filename)
    target = Path.join(root, @manifest_filename)
    temp = Path.join(root, @manifest_temp_filename)

    with :ok <- preflight_previous_manifest(active, journal),
         :ok <- remove_transaction_temp(temp, journal.next_manifest_sha256),
         :ok <- validate_rollback_manifest_target(target, journal),
         {:ok, current} <- hash_regular_or_missing(target) do
      if current == journal.previous_manifest_sha256 do
        :ok
      else
        with :ok <- file_result(File.cp(previous, temp), temp),
             {:ok, copied} <- hash_regular_file(temp),
             :ok <- require_equal_digest(copied, journal.previous_manifest_sha256, temp),
             :ok <- validate_rollback_manifest_target(target, journal),
             :ok <- replace_file(temp, target) do
          :ok
        end
      end
    end
  end

  defp rollback_manifest(root, _active, %{previous_manifest: false} = journal) do
    target = Path.join(root, @manifest_filename)
    temp = Path.join(root, @manifest_temp_filename)

    with :ok <- remove_transaction_temp(temp, journal.next_manifest_sha256),
         :ok <- validate_rollback_manifest_target(target, journal),
         {:ok, current} <- hash_regular_or_missing(target) do
      case current do
        :missing -> :ok
        digest when digest == journal.next_manifest_sha256 -> file_result(File.rm(target), target)
      end
    end
  end

  defp read_journal(active) do
    path = Path.join(active, @journal_filename)

    with {:ok, content} <- read_regular_file(path),
         {:ok, json} <- decode_json(content, "transaction journal #{path}"),
         true <- is_map(json),
         {:ok, @transaction_protocol} <- required_string(json, "protocol", path),
         {:ok, @transaction_version} <- required_integer(json, "version", path),
         {:ok, values} <- required_list(json, "paths", path),
         {:ok, entries} <- validate_journal_paths(values, path),
         {:ok, previous_manifest} <- required_boolean(json, "previousManifest", path),
         {:ok, previous_manifest_sha256} <-
           required_nullable_sha256(json, "previousManifestDigest", path),
         true <- previous_manifest == is_binary(previous_manifest_sha256),
         {:ok, next_digest} <- required_string(json, "nextManifestDigest", path),
         true <- valid_sha256?(String.downcase(next_digest)) do
      {:ok,
       %{
         paths: entries,
         previous_manifest: previous_manifest,
         previous_manifest_sha256: previous_manifest_sha256,
         next_manifest_sha256: String.downcase(next_digest)
       }}
    else
      _ -> {:error, "Invalid generated-output transaction journal: #{path}"}
    end
  end

  defp validate_journal_paths(values, location) do
    Enum.reduce_while(values, {:ok, [], MapSet.new()}, fn value, {:ok, entries, seen} ->
      with true <- is_map(value),
           {:ok, path} <- required_string(value, "path", location),
           {:ok, path} <- validate_relative_path(path, "transaction path"),
           false <- MapSet.member?(seen, path),
           {:ok, temp_path} <- required_string(value, "tempPath", location),
           {:ok, temp_path} <- validate_relative_path(temp_path, "transaction temporary path"),
           true <- temp_path == path <> @output_temp_suffix,
           {:ok, had_previous} <- required_boolean(value, "hadPrevious", location),
           {:ok, previous_sha256} <- required_nullable_sha256(value, "previousDigest", location),
           {:ok, next_sha256} <- required_nullable_sha256(value, "nextDigest", location),
           true <- had_previous == is_binary(previous_sha256),
           true <- is_binary(previous_sha256) or is_binary(next_sha256) do
        entry = %{
          path: path,
          temp_path: temp_path,
          had_previous: had_previous,
          previous_sha256: previous_sha256,
          next_sha256: next_sha256
        }

        {:cont, {:ok, [entry | entries], MapSet.put(seen, path)}}
      else
        _ -> {:halt, {:error, "Invalid generated-output transaction path: #{location}"}}
      end
    end)
    |> case do
      {:ok, entries, _seen} -> {:ok, Enum.reverse(entries)}
      error -> error
    end
  end

  defp validate_control_directory(root, directory) do
    owner = Path.join(directory, @owner_filename)

    with {:ok, relative} <- relative_control_path(root, directory),
         true <- Path.expand(relative, root) == directory,
         {:ok, %File.Stat{type: :directory}} <- File.lstat(directory),
         {:ok, @owner_marker} <- read_regular_file(owner) do
      :ok
    else
      _ ->
        {:error,
         "Reserved generated-output control path is not owned by Reflaxe.Elixir: #{directory}"}
    end
  end

  defp relative_control_path(root, directory) do
    relative = Path.relative_to(directory, root)

    if relative in [@prepare_directory, @transaction_directory] do
      {:ok, relative}
    else
      {:error, "Unexpected generated-output control path: #{directory}"}
    end
  end

  defp remove_transaction_temps(root, journal) do
    with :ok <- preflight_transaction_temps(root, journal),
         :ok <-
           Enum.reduce_while(journal.paths, :ok, fn entry, :ok ->
             with {:ok, temp} <- safe_target(root, entry.temp_path),
                  :ok <- remove_transaction_temp(temp, entry.next_sha256) do
               {:cont, :ok}
             else
               {:error, reason} -> {:halt, {:error, reason}}
             end
           end),
         :ok <-
           remove_transaction_temp(
             Path.join(root, @manifest_temp_filename),
             journal.next_manifest_sha256
           ) do
      :ok
    end
  end

  defp preflight_transaction_temps(root, journal) do
    with :ok <-
           Enum.reduce_while(journal.paths, :ok, fn entry, :ok ->
             with {:ok, temp} <- safe_target(root, entry.temp_path),
                  :ok <- preflight_transaction_temp(temp, entry.next_sha256) do
               {:cont, :ok}
             else
               {:error, reason} -> {:halt, {:error, reason}}
             end
           end),
         :ok <-
           preflight_transaction_temp(
             Path.join(root, @manifest_temp_filename),
             journal.next_manifest_sha256
           ) do
      :ok
    end
  end

  defp preflight_transaction_temp(path, expected_sha256) do
    case File.lstat(path) do
      {:ok, %File.Stat{type: :regular}} ->
        with true <- is_binary(expected_sha256),
             {:ok, actual} <- hash_file(path),
             true <- actual == expected_sha256 do
          :ok
        else
          _ ->
            {:error,
             "Generated-output transaction temporary path failed integrity validation: #{path}"}
        end

      {:ok, %File.Stat{type: type}} ->
        {:error, "Transaction temporary path is not regular (#{type}): #{path}"}

      {:error, :enoent} ->
        :ok

      {:error, reason} ->
        {:error, "Cannot inspect transaction temporary path #{path}: #{format_reason(reason)}"}
    end
  end

  defp remove_transaction_temp(path, expected_sha256) do
    with :ok <- preflight_transaction_temp(path, expected_sha256) do
      case File.lstat(path) do
        {:ok, %File.Stat{type: :regular}} ->
          file_result(File.rm(path), path)

        {:error, :enoent} ->
          :ok

        {:ok, %File.Stat{type: type}} ->
          {:error, "Transaction temporary path is not regular (#{type}): #{path}"}

        {:error, reason} ->
          {:error, "Cannot inspect transaction temporary path #{path}: #{format_reason(reason)}"}
      end
    end
  end

  defp remove_regular_or_missing_path(path) do
    case File.lstat(path) do
      {:ok, %File.Stat{type: :regular}} ->
        file_result(File.rm(path), path)

      {:error, :enoent} ->
        :ok

      {:ok, %File.Stat{type: type}} ->
        {:error, "Expected a regular file during replacement, found #{type}: #{path}"}

      {:error, reason} ->
        {:error, "Cannot inspect replacement target #{path}: #{format_reason(reason)}"}
    end
  end

  defp safe_remove_tree(path) do
    case File.lstat(path) do
      {:ok, %File.Stat{type: :directory}} ->
        with {:ok, children} <- File.ls(path),
             :ok <- remove_tree_children(path, children),
             :ok <- file_result(File.rmdir(path), path) do
          :ok
        end

      {:ok, %File.Stat{type: :regular}} ->
        file_result(File.rm(path), path)

      {:ok, %File.Stat{type: type}} ->
        {:error, "Refusing to follow #{type} in generated-output transaction data: #{path}"}

      {:error, :enoent} ->
        :ok

      {:error, reason} ->
        {:error, "Cannot inspect transaction data #{path}: #{format_reason(reason)}"}
    end
  end

  defp remove_tree_children(parent, children) do
    Enum.reduce_while(children, :ok, fn child, :ok ->
      case safe_remove_tree(Path.join(parent, child)) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp safe_target(root, relative) do
    with {:ok, relative} <- validate_relative_path(relative, "generated output path"),
         target = Path.expand(relative, root),
         true <- target != root,
         true <- String.starts_with?(target, root <> "/"),
         :ok <- reject_symlink_components(root, relative) do
      {:ok, target}
    else
      false ->
        {:error, "Generated output path escapes its root: #{inspect(relative)}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp reject_symlink_components(root, relative) do
    relative
    |> Path.split()
    |> Enum.reduce_while({:ok, root}, fn component, {:ok, current} ->
      candidate = Path.join(current, component)

      case File.lstat(candidate) do
        {:ok, %File.Stat{type: :symlink}} ->
          {:halt, {:error, "Generated output path crosses a symbolic link: #{candidate}"}}

        {:ok, _stat} ->
          {:cont, {:ok, candidate}}

        {:error, :enoent} ->
          {:halt, {:ok, candidate}}

        {:error, reason} ->
          {:halt,
           {:error, "Cannot inspect generated output path #{candidate}: #{format_reason(reason)}"}}
      end
    end)
    |> case do
      {:ok, _path} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_relative_path(path, label) when is_binary(path) do
    parts = Path.split(path)

    cond do
      path == "" or Path.type(path) != :relative or String.contains?(path, "\\") or
          control_character?(path) ->
        {:error, "Invalid #{label} #{inspect(path)}; expected a portable relative path"}

      Path.join(parts) != path or Enum.any?(parts, &(&1 in ["", ".", ".."])) ->
        {:error, "Invalid #{label} #{inspect(path)}; normalized traversal is forbidden"}

      reserved_path?(path) ->
        {:error,
         "Invalid #{label} #{inspect(path)}; the path is reserved by the ownership protocol"}

      true ->
        {:ok, path}
    end
  end

  defp validate_relative_path(path, label),
    do: {:error, "Invalid #{label} #{inspect(path)}; expected a string"}

  defp control_character?(path) do
    path
    |> String.to_charlist()
    |> Enum.any?(fn codepoint -> codepoint < 32 or codepoint == 127 end)
  end

  defp reserved_path?(path) do
    path == @manifest_filename or
      path == @prepare_directory or String.starts_with?(path, @prepare_directory <> "/") or
      path == @transaction_directory or String.starts_with?(path, @transaction_directory <> "/") or
      path == @manifest_temp_filename
  end

  defp required_paths(json, field, location) do
    with {:ok, values} <- required_list(json, field, location) do
      Enum.reduce_while(values, {:ok, [], MapSet.new()}, fn value, {:ok, paths, seen} ->
        with {:ok, path} <- validate_relative_path(value, "manifest path"),
             false <- MapSet.member?(seen, path) do
          {:cont, {:ok, [path | paths], MapSet.put(seen, path)}}
        else
          _ ->
            {:halt,
             {:error,
              "Generated-output metadata has invalid or duplicate paths in #{field}: #{location}"}}
        end
      end)
      |> case do
        {:ok, paths, _seen} -> {:ok, Enum.reverse(paths)}
        error -> error
      end
    end
  end

  defp required_list(json, field, location) do
    case Map.get(json, field) do
      value when is_list(value) -> {:ok, value}
      _ -> {:error, "Generated-output metadata has invalid #{field}: #{location}"}
    end
  end

  defp required_string(json, field, location) do
    case Map.get(json, field) do
      value when is_binary(value) -> {:ok, value}
      _ -> {:error, "Generated-output metadata has invalid #{field}: #{location}"}
    end
  end

  defp required_integer(json, field, location) do
    case Map.get(json, field) do
      value when is_integer(value) and value >= 0 -> {:ok, value}
      _ -> {:error, "Generated-output metadata has invalid #{field}: #{location}"}
    end
  end

  defp required_boolean(json, field, location) do
    case Map.get(json, field) do
      value when is_boolean(value) -> {:ok, value}
      _ -> {:error, "Generated-output metadata has invalid #{field}: #{location}"}
    end
  end

  defp required_nullable_sha256(json, field, location) do
    case Map.fetch(json, field) do
      {:ok, nil} ->
        {:ok, nil}

      {:ok, value} when is_binary(value) ->
        digest = String.downcase(value)

        if valid_sha256?(digest) do
          {:ok, digest}
        else
          {:error, "Generated-output metadata has invalid #{field}: #{location}"}
        end

      _ ->
        {:error, "Generated-output metadata has invalid or missing #{field}: #{location}"}
    end
  end

  defp decode_json(content, label) do
    case Jason.decode(content) do
      {:ok, decoded} -> {:ok, decoded}
      {:error, error} -> {:error, "Cannot parse #{label}: #{Exception.message(error)}"}
    end
  end

  defp hash_regular_file(path) do
    case File.lstat(path) do
      {:ok, %File.Stat{type: :regular}} ->
        hash_file(path)

      {:ok, %File.Stat{type: type}} ->
        {:error, "Expected regular transaction file, found #{type}: #{path}"}

      {:error, reason} ->
        {:error, "Cannot inspect transaction file #{path}: #{format_reason(reason)}"}
    end
  end

  defp read_regular_file(path) do
    case File.lstat(path) do
      {:ok, %File.Stat{type: :regular}} ->
        File.read(path)

      {:ok, %File.Stat{type: type}} ->
        {:error, "Expected regular transaction file, found #{type}: #{path}"}

      {:error, reason} ->
        {:error, "Cannot inspect transaction file #{path}: #{format_reason(reason)}"}
    end
  end

  defp hash_regular_or_missing(path) do
    case File.lstat(path) do
      {:ok, %File.Stat{type: :regular}} ->
        hash_file(path)

      {:ok, %File.Stat{type: type}} ->
        {:error, "Expected regular recovery file, found #{type}: #{path}"}

      {:error, :enoent} ->
        {:ok, :missing}

      {:error, reason} ->
        {:error, "Cannot inspect recovery file #{path}: #{format_reason(reason)}"}
    end
  end

  defp hash_file(path) do
    case File.read(path) do
      {:ok, content} -> {:ok, sha256(content)}
      {:error, reason} -> {:error, "Cannot read #{path}: #{format_reason(reason)}"}
    end
  end

  defp sha256(content),
    do: :crypto.hash(:sha256, content) |> Base.encode16(case: :lower)

  defp valid_sha256?(value),
    do: is_binary(value) and String.match?(value, ~r/\A[0-9a-f]{64}\z/)

  defp require_equal_digest(value, value, _path), do: :ok

  defp require_equal_digest(_actual, _expected, path),
    do: {:error, "Generated-output transaction failed integrity validation: #{path}"}

  defp replace_file(temporary, target) do
    case File.rename(temporary, target) do
      :ok ->
        :ok

      {:error, _reason} ->
        with :ok <- remove_regular_or_missing_path(target),
             :ok <- file_result(File.rename(temporary, target), target) do
          :ok
        end
    end
  end

  defp ensure_parent_directory(path) do
    case File.mkdir_p(Path.dirname(path)) do
      :ok ->
        :ok

      {:error, reason} ->
        {:error, "Cannot create parent directory for #{path}: #{format_reason(reason)}"}
    end
  end

  defp lstat_or_missing(path) do
    case File.lstat(path) do
      {:ok, stat} -> {:ok, stat}
      {:error, :enoent} -> {:ok, :missing}
      {:error, reason} -> {:error, "Cannot inspect #{path}: #{format_reason(reason)}"}
    end
  end

  defp file_result(:ok, _path), do: :ok

  defp file_result({:error, reason}, path),
    do: {:error, "Filesystem operation failed for #{path}: #{format_reason(reason)}"}

  defp format_reason(reason) when is_atom(reason),
    do: reason |> :file.format_error() |> to_string()

  defp format_reason(reason), do: inspect(reason)
end

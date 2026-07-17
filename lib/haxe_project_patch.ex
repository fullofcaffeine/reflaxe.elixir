defmodule HaxeProjectPatch do
  @moduledoc false

  import Bitwise, only: [band: 2]

  @transaction_directory ".reflaxe-elixir-project-patch"
  @owner_filename "owner"
  @journal_filename "journal.json"
  @owner_marker "reflaxe.elixir project patch transaction v1\n"
  @protocol "reflaxe-elixir/project-patch"
  @version 1

  # A publish validates every input, stages replacement files beside their targets, and keeps
  # content-addressed backups until every target reaches its requested state. A surviving journal
  # lets the next invocation either roll a mixed state back or accept an entirely published state.
  # This is intentionally a recovery protocol over atomic per-file renames; it is not a claim of a
  # power-loss-safe, filesystem-wide transaction.

  defmodule Plan do
    @moduledoc false
    @enforce_keys [:root]
    defstruct root: nil, operations: [], seen_paths: MapSet.new()
  end

  defmodule Operation do
    @moduledoc false
    @enforce_keys [:kind, :path, :relative, :before, :after, :action]
    defstruct [:kind, :path, :relative, :before, :after, :action, manifest?: false]
  end

  @type file_state ::
          %{state: :missing}
          | %{state: :regular, content: binary(), sha256: binary(), mode: non_neg_integer()}

  @type plan :: %Plan{}
  @type recovery_status :: :clean | {:pending, :rollback | :commit_cleanup}

  @spec new!(Path.t(), keyword()) :: plan()
  def new!(root, opts \\ []) when is_binary(root) and is_list(opts) do
    root = Path.expand(root)

    if Keyword.get(opts, :recover, true) do
      recover!(root)
    end

    require_directory!(root, "project patch root")
    %Plan{root: root}
  end

  @spec update_file!(
          plan(),
          Path.t(),
          (file_state() -> :keep | :delete | {:write, binary()}),
          keyword()
        ) :: plan()
  def update_file!(%Plan{} = plan, path, fun, opts \\ [])
      when is_binary(path) and is_function(fun, 1) and is_list(opts) do
    {absolute, relative} = normalize_target!(plan.root, path)

    if MapSet.member?(plan.seen_paths, absolute) do
      raise "project patch plan contains more than one operation for #{absolute}"
    end

    before = snapshot!(plan.root, absolute)

    if Keyword.get(opts, :required, false) and before.state == :missing do
      raise Keyword.get(opts, :missing_message, "expected file at #{absolute}")
    end

    instruction = fun.(before)
    seen_paths = MapSet.put(plan.seen_paths, absolute)

    case normalize_instruction!(instruction, before, absolute) do
      :keep ->
        %{plan | seen_paths: seen_paths}

      {kind, after_state, action} ->
        operation = %Operation{
          kind: kind,
          path: absolute,
          relative: relative,
          before: before,
          after: after_state,
          action: action,
          manifest?: Keyword.get(opts, :manifest, false)
        }

        %{plan | operations: [operation | plan.operations], seen_paths: seen_paths}
    end
  end

  @spec ensure_file!(plan(), Path.t(), binary(), (binary() -> binary()), keyword()) :: plan()
  def ensure_file!(%Plan{} = plan, path, initial_content, patch_fun, opts \\ [])
      when is_binary(path) and is_binary(initial_content) and is_function(patch_fun, 1) and
             is_list(opts) do
    update_file!(
      plan,
      path,
      fn
        %{state: :missing} -> {:write, initial_content}
        %{state: :regular, content: content} -> {:write, patch_fun.(content)}
      end,
      opts
    )
  end

  @spec patch_file!(plan(), Path.t(), (binary() -> binary()), keyword()) :: plan()
  def patch_file!(%Plan{} = plan, path, patch_fun, opts \\ [])
      when is_binary(path) and is_function(patch_fun, 1) and is_list(opts) do
    update_file!(
      plan,
      path,
      fn %{state: :regular, content: content} -> {:write, patch_fun.(content)} end,
      Keyword.put(opts, :required, true)
    )
  end

  @spec write_file!(plan(), Path.t(), binary(), keyword()) :: plan()
  def write_file!(%Plan{} = plan, path, content, opts \\ [])
      when is_binary(path) and is_binary(content) and is_list(opts) do
    update_file!(plan, path, fn _state -> {:write, content} end, opts)
  end

  @spec delete_file!(plan(), Path.t(), keyword()) :: plan()
  def delete_file!(%Plan{} = plan, path, opts \\ [])
      when is_binary(path) and is_list(opts) do
    update_file!(plan, path, fn _state -> :delete end, opts)
  end

  @spec changes(plan()) :: [map()]
  def changes(%Plan{} = plan) do
    plan.operations
    |> Enum.reverse()
    |> Enum.map(fn operation ->
      %{
        action: operation.action,
        path: operation.path,
        relative: operation.relative,
        manifest?: operation.manifest?
      }
    end)
  end

  @spec publish!(plan(), keyword()) :: :ok
  def publish!(%Plan{} = plan, opts \\ []) when is_list(opts) do
    operations = ordered_operations(plan)

    if operations == [] do
      :ok
    else
      validate_plan!(plan.root, operations)
      transaction = prepare_transaction!(plan.root, operations)
      fault_injector = Keyword.get(opts, :fault_injector, fn _stage, _operation -> :ok end)

      case publish_operations(transaction, fault_injector) do
        :ok ->
          finish_committed_transaction!(transaction)
          :ok

        {:error, error} ->
          case rollback_transaction(transaction) do
            :ok ->
              raise RuntimeError,
                    "project patch publication failed and was rolled back: #{Exception.message(error)}"

            {:error, rollback_message} ->
              raise RuntimeError,
                    "project patch publication failed: #{Exception.message(error)}; " <>
                      "automatic rollback could not complete: #{rollback_message}. " <>
                      "Transaction data was retained at #{transaction.directory}."
          end
      end
    end
  end

  @spec recovery_status!(Path.t()) :: recovery_status()
  def recovery_status!(root) when is_binary(root) do
    root = Path.expand(root)

    case recovery_action!(root) do
      :clean -> :clean
      {:discard_incomplete, _directory} -> {:pending, :rollback}
      {:rollback, _transaction} -> {:pending, :rollback}
      {:commit_cleanup, _transaction} -> {:pending, :commit_cleanup}
    end
  end

  @spec recover!(Path.t()) :: :ok
  def recover!(root) when is_binary(root) do
    root = Path.expand(root)

    case recovery_action!(root) do
      :clean ->
        :ok

      {:discard_incomplete, directory} ->
        remove_incomplete_transaction!(directory)

      {:commit_cleanup, transaction} ->
        finish_committed_transaction!(transaction)

      {:rollback, transaction} ->
        case rollback_transaction(transaction) do
          :ok -> :ok
          {:error, message} -> raise message
        end
    end
  end

  defp recovery_action!(root) do
    transaction_directory = Path.join(root, @transaction_directory)

    case File.lstat(transaction_directory) do
      {:error, :enoent} ->
        :clean

      {:ok, %File.Stat{type: :directory}} ->
        recovery_action_from_directory!(root, transaction_directory)

      {:ok, %File.Stat{type: type}} ->
        raise "project patch transaction path is not a directory (#{type}): #{transaction_directory}"

      {:error, reason} ->
        raise "cannot inspect project patch transaction path #{transaction_directory}: #{inspect(reason)}"
    end
  end

  @spec replace_marker_block_lines(binary(), binary(), binary(), [binary()]) ::
          {:ok, binary()} | :missing | {:error, term()}
  def replace_marker_block_lines(content, begin_token, end_token, desired_lines)
      when is_binary(content) and is_binary(begin_token) and is_binary(end_token) and
             is_list(desired_lines) do
    with {:ok, lines, begin_index, end_index} <- marker_span(content, begin_token, end_token) do
      begin_line = Enum.at(lines, begin_index)
      end_line = Enum.at(lines, end_index)
      indent = leading_indent(begin_line)

      replacement =
        [begin_line]
        |> Kernel.++(Enum.map(desired_lines, fn line -> indent <> line end))
        |> Kernel.++([end_line])

      {:ok, replace_line_span(lines, begin_index, end_index, replacement)}
    end
  end

  @spec replace_marker_block_lines_with(binary(), binary(), binary(), ([binary()] -> [binary()])) ::
          {:ok, binary()} | :missing | {:error, term()}
  def replace_marker_block_lines_with(content, begin_token, end_token, fun)
      when is_binary(content) and is_binary(begin_token) and is_binary(end_token) and
             is_function(fun, 1) do
    with {:ok, lines, begin_index, end_index} <- marker_span(content, begin_token, end_token) do
      begin_line = Enum.at(lines, begin_index)
      end_line = Enum.at(lines, end_index)
      indent = leading_indent(begin_line)
      existing_inner = Enum.slice(lines, begin_index + 1, end_index - begin_index - 1)

      desired_inner =
        fun.(existing_inner)
        |> Enum.map(fn line -> indent <> String.trim_leading(line) end)

      replacement = [begin_line] ++ desired_inner ++ [end_line]
      {:ok, replace_line_span(lines, begin_index, end_index, replacement)}
    end
  end

  @spec remove_marker_block_lines(binary(), binary(), binary()) ::
          {:ok, binary()} | :missing | {:error, term()}
  def remove_marker_block_lines(content, begin_token, end_token)
      when is_binary(content) and is_binary(begin_token) and is_binary(end_token) do
    with {:ok, lines, begin_index, end_index} <- marker_span(content, begin_token, end_token) do
      updated =
        lines
        |> Enum.with_index()
        |> Enum.reject(fn {_line, index} -> index >= begin_index and index <= end_index end)
        |> Enum.map(fn {line, _index} -> line end)
        |> Enum.join("\n")

      {:ok, updated}
    end
  end

  @spec validate_marker_pairs(binary(), [{binary(), binary()}]) :: :ok | {:error, term()}
  def validate_marker_pairs(content, marker_pairs)
      when is_binary(content) and is_list(marker_pairs) do
    marker_pairs
    |> Enum.reduce_while({:ok, []}, fn {begin_token, end_token}, {:ok, spans} ->
      case marker_span(content, begin_token, end_token) do
        :missing -> {:cont, {:ok, spans}}
        {:ok, _lines, first, last} -> {:cont, {:ok, [{first, last, begin_token} | spans]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:error, reason} ->
        {:error, reason}

      {:ok, spans} ->
        spans
        |> Enum.sort_by(fn {first, _last, _token} -> first end)
        |> reject_overlapping_spans()
    end
  end

  @spec marker_block_lines(binary(), binary(), [binary()], keyword()) :: [binary()]
  def marker_block_lines(begin_token, end_token, desired_lines, opts \\ [])
      when is_binary(begin_token) and is_binary(end_token) and is_list(desired_lines) and
             is_list(opts) do
    indent = Keyword.get(opts, :indent, "")
    comment_prefix = Keyword.get(opts, :comment_prefix, "#")

    [indent <> comment_prefix <> " " <> begin_token]
    |> Kernel.++(Enum.map(desired_lines, fn line -> indent <> line end))
    |> Kernel.++([indent <> comment_prefix <> " " <> end_token])
  end

  @spec signature_status(binary(), binary()) :: :unowned | :owned | {:error, term()}
  def signature_status(content, signature)
      when is_binary(content) and is_binary(signature) and byte_size(signature) > 0 do
    case length(:binary.matches(content, signature)) do
      0 -> :unowned
      1 -> :owned
      count -> {:error, {:duplicate_signature, signature, count}}
    end
  end

  @spec managed_file_content(binary(), binary(), binary()) ::
          {:ok, binary()} | :unowned | {:error, term()}
  def managed_file_content(existing, signature, desired)
      when is_binary(existing) and is_binary(signature) and is_binary(desired) do
    case signature_status(existing, signature) do
      :owned -> {:ok, desired}
      :unowned -> :unowned
      {:error, reason} -> {:error, reason}
    end
  end

  @spec package_key_status(binary(), [binary()], term()) ::
          {:ok, :missing | :equal | {:conflict, term()}} | {:error, binary()}
  def package_key_status(content, path, expected)
      when is_binary(content) and is_list(path) and path != [] do
    with {:ok, json} <- decode_json_object(content),
         :ok <- validate_key_path(path) do
      case fetch_json_path(json, path) do
        :missing -> {:ok, :missing}
        {:ok, ^expected} -> {:ok, :equal}
        {:ok, actual} -> {:ok, {:conflict, actual}}
        {:error, message} -> {:error, message}
      end
    end
  end

  @spec validate_package_key_change(binary(), binary(), [binary()], term()) ::
          :ok | {:error, binary()}
  def validate_package_key_change(before, after_content, path, expected)
      when is_binary(before) and is_binary(after_content) and is_list(path) and path != [] do
    with {:ok, before_json} <- decode_json_object(before),
         {:ok, after_json} <- decode_json_object(after_content),
         :ok <- validate_key_path(path),
         {:ok, ^expected} <- fetch_required_json_path(after_json, path),
         true <- strip_json_path(before_json, path) == strip_json_path(after_json, path) do
      :ok
    else
      :missing -> {:error, "updated package JSON is missing #{Enum.join(path, ".")}"}
      {:ok, actual} -> {:error, "updated package JSON has conflicting value #{inspect(actual)}"}
      false -> {:error, "package JSON update changed keys outside #{Enum.join(path, ".")}"}
      {:error, message} -> {:error, message}
    end
  end

  defp normalize_instruction!(:keep, _before, _path), do: :keep
  defp normalize_instruction!(:delete, %{state: :missing}, _path), do: :keep

  defp normalize_instruction!(:delete, _before, _path) do
    {:delete, %{state: :missing}, :removed}
  end

  defp normalize_instruction!({:write, content}, before, _path) when is_binary(content) do
    mode = if before.state == :regular, do: before.mode, else: 0o644
    after_state = regular_state(content, mode)

    if same_state?(before, after_state) do
      :keep
    else
      action = if before.state == :missing, do: :wrote, else: :patched
      {:write, after_state, action}
    end
  end

  defp normalize_instruction!(instruction, _before, path) do
    raise "invalid project patch instruction for #{path}: #{inspect(instruction)}"
  end

  defp ordered_operations(%Plan{} = plan) do
    operations = Enum.reverse(plan.operations)
    {ordinary, manifests} = Enum.split_with(operations, &(not &1.manifest?))

    if length(manifests) > 1 do
      raise "project patch plan may contain at most one manifest operation"
    end

    ordinary ++ manifests
  end

  defp validate_plan!(root, operations) do
    Enum.each(operations, fn operation ->
      current = snapshot!(root, operation.path)

      unless same_state?(current, operation.before) do
        raise "project patch input changed after discovery: #{operation.path}"
      end
    end)
  end

  defp prepare_transaction!(root, operations) do
    directory = Path.join(root, @transaction_directory)

    case File.lstat(directory) do
      {:error, :enoent} ->
        :ok

      {:ok, _stat} ->
        raise "project patch transaction already exists: #{directory}"

      {:error, reason} ->
        raise "cannot inspect project patch transaction path: #{inspect(reason)}"
    end

    id = Integer.to_string(System.unique_integer([:positive, :monotonic]))
    created_dirs = missing_parent_directories(root, operations)
    staged_operations = build_staged_operations(root, directory, id, operations)
    validate_staged_paths!(staged_operations)

    File.mkdir!(directory)
    File.write!(Path.join(directory, @owner_filename), @owner_marker, [:write, :exclusive])
    File.mkdir!(Path.join(directory, "backups"))

    transaction = %{
      root: root,
      directory: directory,
      id: id,
      operations: staged_operations,
      created_dirs: created_dirs
    }

    write_journal!(transaction)

    try do
      Enum.each(created_dirs, &File.mkdir!/1)
      Enum.each(staged_operations, &stage_operation!/1)
      transaction
    rescue
      error ->
        case rollback_transaction(transaction) do
          :ok ->
            reraise error, __STACKTRACE__

          {:error, message} ->
            raise "#{Exception.message(error)}; staging cleanup failed: #{message}"
        end
    end
  end

  defp build_staged_operations(root, directory, id, operations) do
    operations
    |> Enum.with_index()
    |> Enum.map(fn {operation, index} ->
      basename = Path.basename(operation.path)

      new_path =
        if operation.kind == :write do
          Path.join(
            Path.dirname(operation.path),
            ".#{basename}.reflaxe-patch-#{id}-#{index}.new"
          )
        end

      backup_path =
        if operation.before.state == :regular do
          Path.join([directory, "backups", Integer.to_string(index)])
        end

      %{
        operation: operation,
        new_path: new_path,
        new_relative: relative_or_nil(root, new_path),
        backup_path: backup_path,
        backup_relative: relative_or_nil(root, backup_path)
      }
    end)
  end

  defp validate_staged_paths!(staged_operations) do
    targets = Enum.map(staged_operations, & &1.operation.path)
    temporary_paths = Enum.flat_map(staged_operations, &present_path(&1.new_path))
    backup_paths = Enum.flat_map(staged_operations, &present_path(&1.backup_path))

    assert_unique_paths!(targets, "target")
    assert_unique_paths!(temporary_paths, "temporary")
    assert_unique_paths!(backup_paths, "backup")

    collisions =
      targets
      |> MapSet.new()
      |> MapSet.intersection(MapSet.new(temporary_paths ++ backup_paths))

    if MapSet.size(collisions) > 0 do
      raise "project patch staging paths collide with targets: #{inspect(MapSet.to_list(collisions))}"
    end

    :ok
  end

  defp missing_parent_directories(root, operations) do
    operations
    |> Enum.filter(&(&1.kind == :write))
    |> Enum.flat_map(fn operation -> missing_directories(root, Path.dirname(operation.path)) end)
    |> Enum.uniq()
    |> Enum.sort_by(fn path -> length(Path.split(path)) end)
  end

  defp missing_directories(root, directory) do
    relative = Path.relative_to(directory, root)

    relative
    |> Path.split()
    |> Enum.reduce({root, []}, fn part, {parent, missing} ->
      path = Path.join(parent, part)

      case File.lstat(path) do
        {:ok, %File.Stat{type: :directory}} ->
          {path, missing}

        {:error, :enoent} ->
          {path, missing ++ [path]}

        {:ok, %File.Stat{type: type}} ->
          raise "project patch parent is not a directory (#{type}): #{path}"

        {:error, reason} ->
          raise "cannot inspect project patch parent #{path}: #{inspect(reason)}"
      end
    end)
    |> elem(1)
  end

  defp stage_operation!(staged) do
    operation = staged.operation

    if is_binary(staged.backup_path) do
      write_exclusive!(staged.backup_path, operation.before.content, operation.before.mode)
    end

    if is_binary(staged.new_path) do
      write_exclusive!(staged.new_path, operation.after.content, operation.after.mode)
    end
  end

  defp publish_operations(transaction, fault_injector) do
    transaction.operations
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {staged, index}, :ok ->
      case safely(fn ->
             invoke_fault!(fault_injector, {:before_publish, index}, staged.operation)
             verify_target!(transaction.root, staged.operation, :before)
             publish_one!(staged)
             invoke_fault!(fault_injector, {:after_publish, index}, staged.operation)
           end) do
        :ok -> {:cont, :ok}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  defp publish_one!(%{operation: %{kind: :write, path: path}, new_path: new_path}) do
    File.rename!(new_path, path)
  end

  defp publish_one!(%{operation: %{kind: :delete, path: path}}) do
    File.rm!(path)
  end

  defp finish_committed_transaction!(transaction) do
    Enum.each(transaction.operations, fn staged ->
      verify_target!(transaction.root, staged.operation, :after)
    end)

    cleanup_transaction!(transaction)
  end

  defp rollback_transaction(transaction) do
    with :ok <- validate_recoverable_targets(transaction),
         :ok <- restore_operations(transaction),
         :ok <- cleanup_transaction!(transaction),
         :ok <- prune_created_directories(transaction.created_dirs) do
      :ok
    end
  rescue
    error -> {:error, Exception.message(error)}
  end

  defp validate_recoverable_targets(transaction) do
    Enum.each(transaction.operations, fn staged ->
      current = snapshot!(transaction.root, staged.operation.path)

      unless same_state?(current, staged.operation.before) or
               same_state?(current, staged.operation.after) do
        raise "project patch target has unexpected bytes during recovery: #{staged.operation.path}"
      end

      if same_state?(current, staged.operation.after) and
           staged.operation.before.state == :regular do
        verify_backup!(transaction.root, staged)
      end
    end)

    :ok
  end

  defp restore_operations(transaction) do
    transaction.operations
    |> Enum.reverse()
    |> Enum.each(fn staged ->
      operation = staged.operation
      current = snapshot!(transaction.root, operation.path)

      if same_state?(current, operation.after) do
        case operation.before.state do
          :regular ->
            verify_backup!(transaction.root, staged)
            File.rename!(staged.backup_path, operation.path)

          :missing ->
            File.rm!(operation.path)
        end
      end
    end)

    :ok
  end

  defp verify_backup!(root, staged) do
    backup = snapshot!(root, staged.backup_path)

    unless same_state?(backup, staged.operation.before) do
      raise "project patch backup failed integrity validation: #{staged.backup_path}"
    end

    :ok
  end

  defp cleanup_transaction!(transaction) do
    Enum.each(transaction.operations, fn staged ->
      remove_owned_temp!(transaction.root, staged.new_path, staged.operation.after)
    end)

    require_owned_transaction_directory!(transaction.directory)

    case File.rm_rf(transaction.directory) do
      {:ok, _paths} ->
        :ok

      {:error, reason, path} ->
        raise "cannot remove project patch transaction data #{path}: #{inspect(reason)}"
    end
  end

  defp remove_owned_temp!(_root, nil, _expected), do: :ok

  defp remove_owned_temp!(root, path, expected) do
    validate_owned_temp!(root, path, expected)

    case File.rm(path) do
      :ok -> :ok
      {:error, :enoent} -> :ok
      {:error, reason} -> raise "cannot remove project patch temporary file: #{inspect(reason)}"
    end
  end

  defp prune_created_directories(directories) do
    directories
    |> Enum.reverse()
    |> Enum.each(fn directory ->
      case File.rmdir(directory) do
        :ok ->
          :ok

        {:error, :enoent} ->
          :ok

        {:error, :eexist} ->
          :ok

        {:error, :enotempty} ->
          :ok

        {:error, reason} ->
          raise "cannot remove project patch directory #{directory}: #{inspect(reason)}"
      end
    end)

    :ok
  end

  defp recovery_action_from_directory!(root, directory) do
    require_owned_transaction_directory!(directory)
    journal_path = Path.join(directory, @journal_filename)

    case File.lstat(journal_path) do
      {:error, :enoent} ->
        {:discard_incomplete, directory}

      {:ok, %File.Stat{type: :regular}} ->
        transaction = read_journal!(root, directory, journal_path)

        if Enum.all?(transaction.operations, fn staged ->
             same_state?(snapshot!(root, staged.operation.path), staged.operation.after)
           end) do
          validate_commit_cleanup!(transaction)
          {:commit_cleanup, transaction}
        else
          validate_recoverable_targets(transaction)
          {:rollback, transaction}
        end

      {:ok, %File.Stat{type: type}} ->
        raise "project patch journal is not a regular file (#{type}): #{journal_path}"

      {:error, reason} ->
        raise "cannot inspect project patch journal #{journal_path}: #{inspect(reason)}"
    end
  end

  defp validate_commit_cleanup!(transaction) do
    Enum.each(transaction.operations, fn staged ->
      verify_target!(transaction.root, staged.operation, :after)
      validate_owned_temp!(transaction.root, staged.new_path, staged.operation.after)
    end)

    :ok
  end

  defp validate_owned_temp!(_root, nil, _expected), do: :ok

  defp validate_owned_temp!(root, path, expected) do
    case snapshot!(root, path) do
      %{state: :missing} ->
        :ok

      current ->
        unless same_state?(current, expected) do
          raise "project patch temporary file failed integrity validation: #{path}"
        end

        :ok
    end
  end

  defp remove_incomplete_transaction!(directory) do
    require_owned_transaction_directory!(directory)

    case File.rm_rf(directory) do
      {:ok, _paths} ->
        :ok

      {:error, reason, path} ->
        raise "cannot remove incomplete transaction #{path}: #{inspect(reason)}"
    end
  end

  defp write_journal!(transaction) do
    journal = %{
      "protocol" => @protocol,
      "version" => @version,
      "id" => transaction.id,
      "createdDirectories" =>
        Enum.map(transaction.created_dirs, &Path.relative_to(&1, transaction.root)),
      "operations" => Enum.map(transaction.operations, &operation_to_json/1)
    }

    content = Jason.encode_to_iodata!(journal, pretty: true) |> IO.iodata_to_binary()
    atomic_write!(Path.join(transaction.directory, @journal_filename), content <> "\n")
  end

  defp operation_to_json(staged) do
    %{
      "kind" => Atom.to_string(staged.operation.kind),
      "path" => staged.operation.relative,
      "before" => state_to_json(staged.operation.before),
      "after" => state_to_json(staged.operation.after),
      "newPath" => staged.new_relative,
      "backupPath" => staged.backup_relative,
      "manifest" => staged.operation.manifest?
    }
  end

  defp state_to_json(%{state: :missing}), do: %{"state" => "missing"}

  defp state_to_json(%{state: :regular, sha256: sha256, mode: mode}) do
    %{"state" => "regular", "sha256" => sha256, "mode" => mode}
  end

  defp read_journal!(root, directory, path) do
    with {:ok, json} <- Jason.decode(File.read!(path)),
         %{"protocol" => @protocol, "version" => @version, "id" => id} <- json,
         true <- valid_transaction_id?(id),
         created when is_list(created) <- Map.get(json, "createdDirectories"),
         operations when is_list(operations) <- Map.get(json, "operations") do
      operations =
        operations
        |> Enum.with_index()
        |> Enum.map(fn {operation, index} ->
          operation_from_json!(root, directory, id, operation, index)
        end)

      transaction = %{
        root: root,
        directory: directory,
        id: id,
        created_dirs: Enum.map(created, &path_from_relative!(root, &1)),
        operations: operations
      }

      validate_loaded_transaction!(transaction)
      transaction
    else
      _ -> raise "invalid project patch transaction journal: #{path}"
    end
  end

  defp operation_from_json!(root, directory, id, json, index) when is_map(json) do
    kind =
      case Map.get(json, "kind") do
        "write" -> :write
        "delete" -> :delete
        other -> raise "invalid project patch operation kind: #{inspect(other)}"
      end

    relative = Map.fetch!(json, "path")
    path = path_from_relative!(root, relative)
    reject_reserved_target!(relative)
    before = state_from_json!(Map.fetch!(json, "before"))
    after_state = state_from_json!(Map.fetch!(json, "after"))
    manifest? = required_boolean!(json, "manifest")

    validate_operation_states!(kind, before, after_state, relative)

    operation = %Operation{
      kind: kind,
      path: path,
      relative: relative,
      before: before,
      after: after_state,
      action: if(kind == :delete, do: :removed, else: :patched),
      manifest?: manifest?
    }

    new_path = nullable_relative_path!(root, Map.get(json, "newPath"))
    backup_path = nullable_relative_path!(root, Map.get(json, "backupPath"))

    expected_backup =
      if before.state == :regular,
        do: Path.join([directory, "backups", Integer.to_string(index)]),
        else: nil

    expected_new =
      if kind == :write do
        Path.join(
          Path.dirname(path),
          ".#{Path.basename(path)}.reflaxe-patch-#{id}-#{index}.new"
        )
      end

    if backup_path != expected_backup do
      raise "invalid project patch backup path for #{relative}"
    end

    if new_path != expected_new do
      raise "invalid project patch temporary path for #{relative}"
    end

    %{operation: operation, new_path: new_path, backup_path: backup_path}
  end

  defp validate_loaded_transaction!(transaction) do
    operations = transaction.operations

    if operations == [] do
      raise "project patch transaction contains no operations"
    end

    validate_staged_paths!(operations)

    manifest_indices =
      operations
      |> Enum.with_index()
      |> Enum.flat_map(fn {staged, index} ->
        if staged.operation.manifest?, do: [index], else: []
      end)

    case manifest_indices do
      [] -> :ok
      [index] when index == length(operations) - 1 -> :ok
      _ -> raise "project patch transaction manifest must be the final operation"
    end

    created_dirs = transaction.created_dirs
    assert_unique_paths!(created_dirs, "created directory")

    unless created_dirs ==
             Enum.sort_by(created_dirs, &path_depth(transaction.root, &1)) do
      raise "project patch created directories are not ordered from parent to child"
    end

    allowed_created_dirs =
      operations
      |> Enum.filter(&(&1.operation.kind == :write))
      |> Enum.flat_map(&parent_directories(transaction.root, &1.operation.path))
      |> MapSet.new()

    Enum.each(created_dirs, fn directory ->
      unless MapSet.member?(allowed_created_dirs, directory) do
        raise "invalid project patch created directory: #{directory}"
      end
    end)

    :ok
  end

  defp validate_operation_states!(:write, before, %{state: :regular} = after_state, relative) do
    if same_state?(before, after_state) do
      raise "project patch journal contains a no-op write for #{relative}"
    end

    :ok
  end

  defp validate_operation_states!(:delete, %{state: :regular}, %{state: :missing}, _relative),
    do: :ok

  defp validate_operation_states!(kind, before, after_state, relative) do
    raise "invalid project patch #{kind} state transition for #{relative}: " <>
            "#{inspect(before.state)} -> #{inspect(after_state.state)}"
  end

  defp required_boolean!(json, key) do
    case Map.fetch(json, key) do
      {:ok, value} when is_boolean(value) -> value
      _ -> raise "invalid project patch boolean field: #{key}"
    end
  end

  defp valid_transaction_id?(id) when is_binary(id),
    do: String.match?(id, ~r/\A[1-9][0-9]*\z/)

  defp valid_transaction_id?(_id), do: false

  defp present_path(nil), do: []
  defp present_path(path), do: [path]

  defp assert_unique_paths!(paths, label) do
    if length(paths) != MapSet.size(MapSet.new(paths)) do
      raise "project patch transaction contains duplicate #{label} paths"
    end

    :ok
  end

  defp parent_directories(root, path) do
    case Path.relative_to(Path.dirname(path), root) do
      "." ->
        []

      relative ->
        relative
        |> Path.split()
        |> Enum.scan(root, fn part, parent -> Path.join(parent, part) end)
    end
  end

  defp path_depth(root, path), do: path |> Path.relative_to(root) |> Path.split() |> length()

  defp state_from_json!(%{"state" => "missing"}), do: %{state: :missing}

  defp state_from_json!(%{"state" => "regular", "sha256" => sha256, "mode" => mode})
       when is_binary(sha256) and byte_size(sha256) == 64 and is_integer(mode) and mode >= 0 and
              mode <= 0o7777 do
    if String.match?(sha256, ~r/\A[0-9a-f]{64}\z/) do
      %{state: :regular, sha256: sha256, mode: mode}
    else
      raise "invalid project patch content digest: #{inspect(sha256)}"
    end
  end

  defp state_from_json!(other), do: raise("invalid project patch file state: #{inspect(other)}")

  defp verify_target!(root, operation, side) when side in [:before, :after] do
    expected = Map.fetch!(operation, side)
    current = snapshot!(root, operation.path)

    unless same_state?(current, expected) do
      raise "project patch target changed before publication: #{operation.path}"
    end

    :ok
  end

  defp invoke_fault!(fault_injector, stage, operation) do
    case fault_injector.(stage, operation) do
      :ok -> :ok
      {:error, message} -> raise "injected project patch failure: #{message}"
      other -> raise "invalid project patch fault injector result: #{inspect(other)}"
    end
  end

  defp safely(fun) do
    fun.()
    :ok
  rescue
    error -> {:error, error}
  end

  defp snapshot!(root, path) do
    validate_parent_chain!(root, path)

    case File.lstat(path) do
      {:error, :enoent} ->
        %{state: :missing}

      {:ok, %File.Stat{type: :regular, mode: mode}} ->
        regular_state(File.read!(path), band(mode, 0o7777))

      {:ok, %File.Stat{type: type}} ->
        raise "project patch target is not a regular file (#{type}): #{path}"

      {:error, reason} ->
        raise "cannot inspect project patch target #{path}: #{inspect(reason)}"
    end
  end

  defp regular_state(content, mode) do
    %{state: :regular, content: content, sha256: sha256(content), mode: mode}
  end

  defp same_state?(%{state: :missing}, %{state: :missing}), do: true

  defp same_state?(
         %{state: :regular, sha256: left_sha, mode: left_mode},
         %{state: :regular, sha256: right_sha, mode: right_mode}
       ),
       do: left_sha == right_sha and left_mode == right_mode

  defp same_state?(_left, _right), do: false

  defp sha256(content), do: :crypto.hash(:sha256, content) |> Base.encode16(case: :lower)

  defp normalize_target!(root, path) do
    absolute =
      if Path.type(path) == :absolute, do: Path.expand(path), else: Path.expand(path, root)

    relative = Path.relative_to(absolute, root)

    if relative == "." or escapes_root?(relative) do
      raise "project patch target escapes the project root: #{path}"
    end

    reject_reserved_target!(relative)
    validate_parent_chain!(root, absolute)
    {absolute, relative}
  end

  defp path_from_relative!(root, relative) when is_binary(relative) do
    if Path.type(relative) == :absolute or relative == "." or escapes_root?(relative) do
      raise "invalid project patch relative path: #{inspect(relative)}"
    end

    path = Path.expand(relative, root)

    if Path.relative_to(path, root) != relative do
      raise "project patch relative path is not canonical: #{inspect(relative)}"
    end

    validate_parent_chain!(root, path)
    path
  end

  defp path_from_relative!(_root, relative),
    do: raise("invalid project patch relative path: #{inspect(relative)}")

  defp nullable_relative_path!(_root, nil), do: nil
  defp nullable_relative_path!(root, path), do: path_from_relative!(root, path)

  defp relative_or_nil(_root, nil), do: nil
  defp relative_or_nil(root, path), do: Path.relative_to(path, root)

  defp reject_reserved_target!(relative) do
    if relative == @transaction_directory or
         String.starts_with?(relative, @transaction_directory <> "/") do
      raise "project patch target uses the reserved transaction path: #{relative}"
    end

    :ok
  end

  defp escapes_root?(relative) do
    Path.type(relative) == :absolute or relative == ".." or String.starts_with?(relative, "../")
  end

  defp validate_parent_chain!(root, path) do
    require_directory!(root, "project patch root")
    relative = Path.relative_to(path, root)

    if escapes_root?(relative) do
      raise "project patch path escapes the project root: #{path}"
    end

    relative
    |> Path.dirname()
    |> Path.split()
    |> Enum.reduce_while(root, fn
      ".", current ->
        {:cont, current}

      part, current ->
        next = Path.join(current, part)

        case File.lstat(next) do
          {:ok, %File.Stat{type: :directory}} ->
            {:cont, next}

          {:error, :enoent} ->
            {:halt, next}

          {:ok, %File.Stat{type: type}} ->
            raise "project patch parent is not a directory (#{type}): #{next}"

          {:error, reason} ->
            raise "cannot inspect project patch parent #{next}: #{inspect(reason)}"
        end
    end)

    :ok
  end

  defp require_directory!(path, label) do
    case File.lstat(path) do
      {:ok, %File.Stat{type: :directory}} -> :ok
      {:ok, %File.Stat{type: type}} -> raise "#{label} is not a directory (#{type}): #{path}"
      {:error, reason} -> raise "cannot inspect #{label} #{path}: #{inspect(reason)}"
    end
  end

  defp require_owned_transaction_directory!(directory) do
    require_directory!(directory, "project patch transaction path")
    owner = Path.join(directory, @owner_filename)

    case File.lstat(owner) do
      {:ok, %File.Stat{type: :regular}} ->
        if File.read!(owner) != @owner_marker do
          raise "project patch transaction owner marker is invalid: #{owner}"
        end

      {:ok, %File.Stat{type: type}} ->
        raise "project patch transaction owner is not a regular file (#{type}): #{owner}"

      {:error, reason} ->
        raise "cannot inspect project patch transaction owner #{owner}: #{inspect(reason)}"
    end

    :ok
  end

  defp write_exclusive!(path, content, mode) do
    File.write!(path, content, [:write, :exclusive, :binary])
    File.chmod!(path, mode)
  end

  defp atomic_write!(path, content) do
    temp = path <> ".tmp"
    File.write!(temp, content, [:write, :exclusive, :binary])
    File.rename!(temp, path)
  end

  defp marker_span(content, begin_token, end_token) do
    if begin_token == "" or end_token == "" or begin_token == end_token do
      {:error, {:invalid_marker_tokens, begin_token, end_token}}
    else
      lines = String.split(content, "\n", trim: false)
      begins = matching_line_indices(lines, begin_token)
      ends = matching_line_indices(lines, end_token)

      case {begins, ends} do
        {[], []} ->
          :missing

        {[begin_index], [end_index]} when begin_index < end_index ->
          {:ok, lines, begin_index, end_index}

        {[begin_index], [end_index]} ->
          {:error, {:inverted_marker_pair, begin_token, end_token, begin_index, end_index}}

        _ ->
          {:error, {:marker_count, begin_token, length(begins), end_token, length(ends)}}
      end
    end
  end

  defp matching_line_indices(lines, token) do
    lines
    |> Enum.with_index()
    |> Enum.flat_map(fn {line, index} ->
      if String.contains?(line, token), do: [index], else: []
    end)
  end

  defp replace_line_span(lines, begin_index, end_index, replacement) do
    lines
    |> Enum.with_index()
    |> Enum.flat_map(fn {line, index} ->
      cond do
        index < begin_index -> [line]
        index == begin_index -> replacement
        index <= end_index -> []
        true -> [line]
      end
    end)
    |> Enum.join("\n")
  end

  defp reject_overlapping_spans([]), do: :ok
  defp reject_overlapping_spans([_span]), do: :ok

  defp reject_overlapping_spans([{first_start, first_end, first_token}, second | rest]) do
    {second_start, second_end, second_token} = second

    if second_start <= first_end do
      {:error,
       {:overlapping_marker_pairs, first_token, {first_start, first_end}, second_token,
        {second_start, second_end}}}
    else
      reject_overlapping_spans([second | rest])
    end
  end

  defp leading_indent(line) do
    line
    |> String.graphemes()
    |> Enum.take_while(&(&1 in [" ", "\t"]))
    |> Enum.join()
  end

  defp decode_json_object(content) do
    case Jason.decode(content) do
      {:ok, value} when is_map(value) -> {:ok, value}
      {:ok, _value} -> {:error, "package JSON must contain an object"}
      {:error, error} -> {:error, "invalid package JSON: #{Exception.message(error)}"}
    end
  end

  defp validate_key_path(path) do
    if Enum.all?(path, &(is_binary(&1) and &1 != "")) do
      :ok
    else
      {:error, "package JSON key path must contain non-empty strings"}
    end
  end

  defp fetch_json_path(json, path), do: fetch_json_path(json, path, [])

  defp fetch_json_path(json, [key], _parents) do
    case Map.fetch(json, key) do
      {:ok, value} -> {:ok, value}
      :error -> :missing
    end
  end

  defp fetch_json_path(json, [key | rest], parents) do
    case Map.fetch(json, key) do
      {:ok, value} when is_map(value) ->
        fetch_json_path(value, rest, parents ++ [key])

      {:ok, _value} ->
        {:error,
         "package JSON key path #{Enum.join(parents ++ [key], ".")} must contain an object"}

      :error ->
        :missing
    end
  end

  defp fetch_required_json_path(json, path), do: fetch_json_path(json, path)

  defp strip_json_path(json, [key]) do
    Map.delete(json, key)
  end

  defp strip_json_path(json, [key | rest]) do
    case Map.fetch(json, key) do
      {:ok, value} when is_map(value) ->
        child = strip_json_path(value, rest)

        if map_size(child) == 0 do
          Map.delete(json, key)
        else
          Map.put(json, key, child)
        end

      _ ->
        json
    end
  end
end

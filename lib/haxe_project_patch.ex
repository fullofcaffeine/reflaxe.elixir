defmodule HaxeProjectPatch do
  def new!(root, opts \\ nil) do
    options = normalize_options(opts)
    expanded = Path.expand(root)
    if Keyword.get(options, :recover, true), do: recover!(expanded)
    require_directory_bang(expanded, "project patch root")
    HaxeProjectPatch.Plan.new(expanded)
  end

  def update_file!(plan, path, fun, opts \\ nil) do
    options = normalize_options(opts)
    normalized = normalize_target_bang(plan.root, path)
    absolute = Kernel.elem(normalized, 0)
    relative = Kernel.elem(normalized, 1)

    if MapSet.member?(plan.seen_paths, absolute) do
      Kernel.raise("project patch plan contains more than one operation for #{absolute}")
    else
      before = snapshot_bang(plan.root, absolute)

      if Keyword.get(options, :required, false) and before.state == :missing do
        missing_message = Keyword.get(options, :missing_message, "expected file at #{absolute}")
        Kernel.raise(missing_message)
      else
        instruction = fun.(before)
        seen_paths = MapSet.put(plan.seen_paths, absolute)
        normalized_instruction = normalize_instruction_bang(instruction, before, absolute)
        plan = %{plan | seen_paths: seen_paths}

        if same_term(normalized_instruction, :keep) do
          plan
        else
          kind = Kernel.elem(normalized_instruction, 0)
          after_state = Kernel.elem(normalized_instruction, 1)
          action = Kernel.elem(normalized_instruction, 2)

          operation =
            HaxeProjectPatch.Operation.new(
              kind,
              absolute,
              relative,
              before,
              after_state,
              action,
              Keyword.get(options, :manifest, false)
            )

          plan = %{plan | operations: Enum.concat([operation], plan.operations)}
          plan
        end
      end
    end
  end

  def ensure_file!(plan, path, initial_content, patch_fun, opts \\ nil) do
    update_file!(
      plan,
      path,
      fn state ->
        if state.state == :missing,
          do: write_instruction(initial_content),
          else: write_instruction(patch_fun.(state.content))
      end,
      opts
    )
  end

  def patch_file!(plan, path, patch_fun, opts \\ nil) do
    options = Keyword.put(normalize_options(opts), :required, true)

    update_file!(
      plan,
      path,
      fn state -> write_instruction(patch_fun.(state.content)) end,
      options
    )
  end

  def write_file!(plan, path, content, opts \\ nil) do
    update_file!(plan, path, fn _state -> write_instruction(content) end, opts)
  end

  def delete_file!(plan, path, opts \\ nil) do
    update_file!(plan, path, fn _state -> :delete end, opts)
  end

  def changes(plan) do
    Enum.map(Enum.reverse(plan.operations), fn operation ->
      change = Map.new()

      change =
        change
        |> Map.put(:action, operation.action)
        |> Map.put(:path, operation.path)
        |> Map.put(:relative, operation.relative)

      Map.put(change, :manifest?, operation.manifest?)
    end)
  end

  def publish!(plan, opts \\ nil) do
    operations = ordered_operations(plan)

    if length(operations) == 0 do
      :ok
    else
      validate_plan_bang(plan.root, operations)
      transaction = prepare_transaction_bang(plan.root, operations)

      fault_injector =
        Keyword.get(normalize_options(opts), :fault_injector, fn _stage, _operation -> :ok end)

      published = publish_operations(transaction, fault_injector)

      if same_term(published, :ok) do
        finish_committed_transaction_bang(transaction)
        :ok
      else
        publication_error = Kernel.elem(published, 1)
        rollback = rollback_transaction(transaction)

        if same_term(rollback, :ok) do
          Kernel.raise(
            "project patch publication failed and was rolled back: #{Exception.message(publication_error)}"
          )
        else
          rollback_message = Kernel.elem(rollback, 1)

          Kernel.raise(
            "project patch publication failed: #{Exception.message(publication_error)}; automatic rollback could not complete: #{rollback_message}. Transaction data was retained at #{transaction.directory}."
          )
        end
      end
    end
  end

  def recovery_status!(root) do
    action = recovery_action_bang(Path.expand(root))

    if same_term(action, :clean) do
      :clean
    else
      tag = tuple_tag(action)
      {:pending, if(tag == :commit_cleanup, do: :commit_cleanup, else: :rollback)}
    end
  end

  def recover!(root) do
    action = recovery_action_bang(Path.expand(root))

    if same_term(action, :clean) do
      :ok
    else
      tag = tuple_tag(action)

      if tag == :discard_incomplete do
        remove_incomplete_transaction_bang(Kernel.elem(action, 1))
        :ok
      else
        transaction = Kernel.elem(action, 1)

        if tag == :commit_cleanup do
          finish_committed_transaction_bang(transaction)
          :ok
        else
          rollback = rollback_transaction(transaction)

          if same_term(rollback, :ok) do
            :ok
          else
            Kernel.raise(Kernel.elem(rollback, 1))
          end
        end
      end
    end
  end

  def replace_marker_block_lines(content, begin_token, end_token, desired_lines) do
    span = marker_span(content, begin_token, end_token)

    if same_term(span, :missing) do
      :missing
    else
      if has_tag(span, :error) do
        error(Kernel.elem(span, 1))
      else
        lines = Kernel.elem(span, 1)
        begin_index = Kernel.elem(span, 2)
        end_index = Kernel.elem(span, 3)
        begin_line = Enum.at(lines, begin_index, "")
        end_line = Enum.at(lines, end_index, "")
        indent = leading_indent(begin_line)
        indented = Enum.map(desired_lines, fn line -> indent <> line end)
        replacement = Enum.concat(Enum.concat([begin_line], indented), [end_line])
        ok(replace_line_span(lines, begin_index, end_index, replacement))
      end
    end
  end

  def replace_marker_block_lines_with(content, begin_token, end_token, fun) do
    span = marker_span(content, begin_token, end_token)

    if same_term(span, :missing) do
      :missing
    else
      if has_tag(span, :error) do
        error(Kernel.elem(span, 1))
      else
        lines = Kernel.elem(span, 1)
        begin_index = Kernel.elem(span, 2)
        end_index = Kernel.elem(span, 3)
        begin_line = Enum.at(lines, begin_index, "")
        end_line = Enum.at(lines, end_index, "")
        indent = leading_indent(begin_line)
        existing_inner = Enum.take(Enum.drop(lines, begin_index + 1), end_index - begin_index - 1)

        desired_inner =
          Enum.map(fun.(existing_inner), fn line -> indent <> String.trim_leading(line) end)

        replacement = Enum.concat(Enum.concat([begin_line], desired_inner), [end_line])
        ok(replace_line_span(lines, begin_index, end_index, replacement))
      end
    end
  end

  def remove_marker_block_lines(content, begin_token, end_token) do
    span = marker_span(content, begin_token, end_token)

    if same_term(span, :missing) do
      :missing
    else
      if has_tag(span, :error) do
        error(Kernel.elem(span, 1))
      else
        lines = Kernel.elem(span, 1)
        begin_index = Kernel.elem(span, 2)
        end_index = Kernel.elem(span, 3)

        retained =
          Enum.flat_map(Enum.with_index(lines), fn entry ->
            line = Kernel.elem(entry, 0)
            index = Kernel.elem(entry, 1)
            if index >= begin_index and index <= end_index, do: [], else: [line]
          end)

        ok(Enum.join(retained, "\n"))
      end
    end
  end

  def validate_marker_pairs(content, marker_pairs) do
    collected = collect_marker_spans(content, marker_pairs, 0, [])

    if has_tag(collected, :error) do
      collected
    else
      spans = Kernel.elem(collected, 1)
      validate_ordered_spans(Enum.sort_by(spans, fn span -> span.first end), 1)
    end
  end

  def marker_block_lines(begin_token, end_token, desired_lines, opts \\ nil) do
    options = if Kernel.is_nil(opts), do: [], else: opts
    indent = Keyword.get(options, :indent, "")
    comment_prefix = Keyword.get(options, :comment_prefix, "#")
    body = Enum.map(desired_lines, fn line -> indent <> line end)

    Enum.concat(Enum.concat(["#{indent}#{comment_prefix} #{begin_token}"], body), [
      "#{indent}#{comment_prefix} #{end_token}"
    ])
  end

  def signature_status(content, signature) do
    count = length(:binary.matches(content, signature))

    if count == 0 do
      :unowned
    else
      if count == 1, do: :owned, else: error({:duplicate_signature, signature, count})
    end
  end

  def managed_file_content(existing, signature, desired) do
    status = signature_status(existing, signature)
    if same_term(status, :owned), do: ok(desired), else: status
  end

  def package_key_status(content, path, expected) do
    decoded = decode_json_object(content)

    if has_tag(decoded, :error) do
      decoded
    else
      path_validation = validate_key_path(path)

      if not same_term(path_validation, :ok) do
        path_validation
      else
        json = Kernel.elem(decoded, 1)
        fetched = fetch_json_path(json, path, [])

        if same_term(fetched, :missing) or has_tag(fetched, :error) do
          if same_term(fetched, :missing), do: ok(:missing), else: fetched
        else
          actual = Kernel.elem(fetched, 1)
          if same_term(actual, expected), do: ok(:equal), else: ok({:conflict, actual})
        end
      end
    end
  end

  def validate_package_key_change(before, after_content, path, expected) do
    before_decoded = decode_json_object(before)

    if has_tag(before_decoded, :error) do
      before_decoded
    else
      after_decoded = decode_json_object(after_content)

      if has_tag(after_decoded, :error) do
        after_decoded
      else
        path_validation = validate_key_path(path)

        if not same_term(path_validation, :ok) do
          path_validation
        else
          before_json = Kernel.elem(before_decoded, 1)
          after_json = Kernel.elem(after_decoded, 1)
          fetched = fetch_json_path(after_json, path, [])

          if same_term(fetched, :missing) do
            error("updated package JSON is missing #{Enum.join(path, ".")}")
          else
            if has_tag(fetched, :error) do
              fetched
            else
              actual = Kernel.elem(fetched, 1)

              if not same_term(actual, expected) do
                error("updated package JSON has conflicting value #{Kernel.inspect(actual)}")
              else
                if not same_term(
                     strip_json_path(before_json, path),
                     strip_json_path(after_json, path)
                   ),
                   do: error("package JSON update changed keys outside #{Enum.join(path, ".")}"),
                   else: :ok
              end
            end
          end
        end
      end
    end
  end

  defp normalize_options(opts) do
    if Kernel.is_nil(opts), do: [], else: opts
  end

  defp write_instruction(content) do
    {:write, content}
  end

  defp normalize_instruction_bang(instruction, before, path) do
    if same_term(instruction, :keep) do
      :keep
    else
      if same_term(instruction, :delete) do
        if before.state == :missing, do: :keep, else: {:delete, missing_state(), :removed}
      else
        if has_tag(instruction, :write) do
          content = Kernel.elem(instruction, 1)

          if not Kernel.is_binary(content) do
            Kernel.raise(
              "invalid project patch instruction for #{path}: #{Kernel.inspect(instruction)}"
            )
          else
            mode = if before.state == :regular, do: before.mode, else: 420
            after_state = regular_state(Kernel.elem(instruction, 1), mode)

            if same_state(before, after_state),
              do: :keep,
              else:
                {:write, after_state, if(before.state == :missing, do: :wrote, else: :patched)}
          end
        else
          Kernel.raise(
            "invalid project patch instruction for #{path}: #{Kernel.inspect(instruction)}"
          )
        end
      end
    end
  end

  defp ordered_operations(plan) do
    operations = Enum.reverse(plan.operations)
    split = Enum.split_with(operations, fn operation -> not operation.manifest? end)
    ordinary = Kernel.elem(split, 0)
    manifests = Kernel.elem(split, 1)

    if length(manifests) > 1 do
      Kernel.raise("project patch plan may contain at most one manifest operation")
    else
      Enum.concat(ordinary, manifests)
    end
  end

  defp validate_plan_bang(root, operations) do
    Enum.each(operations, fn operation ->
      current = snapshot_bang(root, operation.path)

      if not same_state(current, operation.before) do
        Kernel.raise("project patch input changed after discovery: " <> operation.path)
      end
    end)

    :ok
  end

  defp prepare_transaction_bang(root, operations) do
    directory = Path.join(root, ".reflaxe-elixir-project-patch")
    status = File.lstat(directory)

    if not has_tag(status, :error) or not same_term(Kernel.elem(status, 1), :enoent) do
      if has_tag(status, :ok) do
        Kernel.raise("project patch transaction already exists: #{directory}")
      else
        Kernel.raise(
          "cannot inspect project patch transaction path: #{Kernel.inspect(Kernel.elem(status, 1))}"
        )
      end
    else
      id = Integer.to_string(System.unique_integer([:positive, :monotonic]))
      created_dirs = missing_parent_directories(root, operations)
      staged_operations = build_staged_operations(root, directory, id, operations)
      validate_staged_paths_bang(staged_operations)
      File.mkdir!(directory)

      File.write!(
        Path.join(directory, "owner"),
        "reflaxe.elixir project patch transaction v1\n",
        [:write, :exclusive]
      )

      File.mkdir!(Path.join(directory, "backups"))

      transaction = %{
        root: root,
        directory: directory,
        id: id,
        operations: staged_operations,
        created_dirs: created_dirs
      }

      write_journal_bang(transaction)

      try do
        Enum.each(created_dirs, fn path -> File.mkdir!(path) end)
        Enum.each(staged_operations, fn staged -> stage_operation_bang(staged) end)
        transaction
      rescue
        error ->
          rollback = rollback_transaction(transaction)

          if same_term(rollback, :ok) do
            Kernel.raise(error)
          else
            Kernel.raise(
              Exception.message(error) <> "; staging cleanup failed: " <> Kernel.elem(rollback, 1)
            )
          end
      end
    end
  end

  defp build_staged_operations(root, directory, id, operations) do
    Enum.map(Enum.with_index(operations), fn entry ->
      operation = Kernel.elem(entry, 0)
      index = Kernel.elem(entry, 1)
      basename = Path.basename(operation.path)

      new_path =
        if operation.kind == :write do
          Path.join(
            Path.dirname(operation.path),
            "." <>
              basename <> ".reflaxe-patch-" <> id <> "-" <> Integer.to_string(index) <> ".new"
          )
        else
          nil
        end

      backup_path =
        if operation.before.state == :regular do
          Path.join([directory, "backups", Integer.to_string(index)])
        else
          nil
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

  defp validate_staged_paths_bang(staged_operations) do
    targets = Enum.map(staged_operations, fn staged -> staged.operation.path end)

    temporary_paths =
      Enum.flat_map(staged_operations, fn staged -> present_path(staged.new_path) end)

    backup_paths =
      Enum.flat_map(staged_operations, fn staged -> present_path(staged.backup_path) end)

    assert_unique_paths_bang(targets, "target")
    assert_unique_paths_bang(temporary_paths, "temporary")
    assert_unique_paths_bang(backup_paths, "backup")

    collisions =
      MapSet.intersection(
        MapSet.new(targets),
        MapSet.new(Enum.concat(temporary_paths, backup_paths))
      )

    if MapSet.size(collisions) > 0 do
      Kernel.raise(
        "project patch staging paths collide with targets: #{Kernel.inspect(MapSet.to_list(collisions))}"
      )
    else
      :ok
    end
  end

  defp missing_parent_directories(root, operations) do
    all =
      Enum.flat_map(
        Enum.filter(operations, fn operation -> operation.kind == :write end),
        fn operation -> missing_directories(root, Path.dirname(operation.path)) end
      )

    Enum.sort_by(Enum.uniq(all), fn path -> length(Path.split(path)) end)
  end

  defp missing_directories(root, directory) do
    collect_missing_directories(Path.split(Path.relative_to(directory, root)), 0, root, [])
  end

  defp collect_missing_directories(parts, index, parent, missing) do
    if index >= length(parts) do
      missing
    else
      path = Path.join(parent, Enum.at(parts, index))
      status = File.lstat(path)

      if has_tag(status, :ok) do
        stat = Kernel.elem(status, 1)

        if stat.type != :directory do
          Kernel.raise(
            "project patch parent is not a directory (#{Kernel.to_string(stat.type)}): #{path}"
          )
        else
          collect_missing_directories(parts, index + 1, path, missing)
        end
      else
        reason = Kernel.elem(status, 1)

        if same_term(reason, :enoent) do
          collect_missing_directories(parts, index + 1, path, Enum.concat(missing, [path]))
        else
          Kernel.raise("cannot inspect project patch parent #{path}: #{Kernel.inspect(reason)}")
        end
      end
    end
  end

  defp stage_operation_bang(staged) do
    operation = staged.operation

    if not Kernel.is_nil(staged.backup_path) do
      write_exclusive_bang(staged.backup_path, operation.before.content, operation.before.mode)
    end

    if not Kernel.is_nil(staged.new_path) do
      write_exclusive_bang(staged.new_path, operation.after.content, operation.after.mode)
    end
  end

  defp publish_operations(transaction, fault_injector) do
    publish_operations_at(transaction, fault_injector, 0)
  end

  defp publish_operations_at(transaction, fault_injector, index) do
    if index >= length(transaction.operations) do
      :ok
    else
      staged = Enum.at(transaction.operations, index)

      result =
        safely(fn ->
          invoke_fault_bang(fault_injector, {:before_publish, index}, staged.operation)
          verify_target_bang(transaction.root, staged.operation, "before")
          publish_one_bang(staged)
          invoke_fault_bang(fault_injector, {:after_publish, index}, staged.operation)
        end)

      if same_term(result, :ok) do
        publish_operations_at(transaction, fault_injector, index + 1)
      else
        result
      end
    end
  end

  defp publish_one_bang(staged) do
    if staged.operation.kind == :write do
      File.rename!(staged.new_path, staged.operation.path)
    else
      File.rm!(staged.operation.path)
    end
  end

  defp finish_committed_transaction_bang(transaction) do
    Enum.each(transaction.operations, fn staged ->
      verify_target_bang(transaction.root, staged.operation, "after")
    end)

    cleanup_transaction_bang(transaction)
  end

  defp rollback_transaction(transaction) do
    try do
      validate_recoverable_targets(transaction)
      restore_operations(transaction)
      cleanup_transaction_bang(transaction)
      prune_created_directories(transaction.created_dirs)
      :ok
    rescue
      exception ->
        error(Exception.message(exception))
    end
  end

  defp validate_recoverable_targets(transaction) do
    Enum.each(transaction.operations, fn staged ->
      current = snapshot_bang(transaction.root, staged.operation.path)

      if not same_state(current, staged.operation.before) and
           not same_state(current, staged.operation.after) do
        Kernel.raise(
          "project patch target has unexpected bytes during recovery: " <> staged.operation.path
        )
      end

      if same_state(current, staged.operation.after) and
           staged.operation.before.state == :regular,
         do: verify_backup_bang(transaction.root, staged)
    end)

    :ok
  end

  defp restore_operations(transaction) do
    Enum.each(Enum.reverse(transaction.operations), fn staged ->
      operation = staged.operation
      current = snapshot_bang(transaction.root, operation.path)

      if same_state(current, operation.after) do
        if operation.before.state == :regular do
          verify_backup_bang(transaction.root, staged)
          File.rename!(staged.backup_path, operation.path)
        else
          File.rm!(operation.path)
        end
      end
    end)

    :ok
  end

  defp verify_backup_bang(root, staged) do
    backup = snapshot_bang(root, staged.backup_path)

    if not same_state(backup, staged.operation.before) do
      Kernel.raise("project patch backup failed integrity validation: #{staged.backup_path}")
    else
      :ok
    end
  end

  defp cleanup_transaction_bang(transaction) do
    Enum.each(transaction.operations, fn staged ->
      remove_owned_temp_bang(transaction.root, staged.new_path, staged.operation.after)
    end)

    require_owned_transaction_directory_bang(transaction.directory)
    result = File.rm_rf(transaction.directory)

    if has_tag(result, :ok) do
      :ok
    else
      reason = Kernel.elem(result, 1)
      path = Kernel.elem(result, 2)

      Kernel.raise(
        "cannot remove project patch transaction data #{path}: #{Kernel.inspect(reason)}"
      )
    end
  end

  defp remove_owned_temp_bang(root, path, expected) do
    if Kernel.is_nil(path) do
      :ok
    else
      validate_owned_temp_bang(root, path, expected)
      result = File.rm(path)

      if same_term(result, :ok) do
        :ok
      else
        reason = Kernel.elem(result, 1)

        if same_term(reason, :enoent) do
          :ok
        else
          Kernel.raise("cannot remove project patch temporary file: #{Kernel.inspect(reason)}")
        end
      end
    end
  end

  defp prune_created_directories(directories) do
    Enum.each(Enum.reverse(directories), fn directory ->
      result = File.rmdir(directory)

      if not same_term(result, :ok) do
        reason = Kernel.elem(result, 1)

        if not same_term(reason, :enoent) and not same_term(reason, :eexist) and
             not same_term(reason, :enotempty) do
          Kernel.raise(
            "cannot remove project patch directory " <>
              directory <> ": " <> Kernel.inspect(reason)
          )
        end
      end
    end)

    :ok
  end

  defp recovery_action_bang(root) do
    transaction_directory = Path.join(root, ".reflaxe-elixir-project-patch")
    result = File.lstat(transaction_directory)

    if has_tag(result, :error) do
      reason = Kernel.elem(result, 1)

      if same_term(reason, :enoent) do
        :clean
      else
        Kernel.raise(
          "cannot inspect project patch transaction path #{transaction_directory}: #{Kernel.inspect(reason)}"
        )
      end
    else
      stat = Kernel.elem(result, 1)

      if stat.type != :directory do
        Kernel.raise(
          "project patch transaction path is not a directory (#{Kernel.to_string(stat.type)}): #{transaction_directory}"
        )
      else
        recovery_action_from_directory_bang(root, transaction_directory)
      end
    end
  end

  defp recovery_action_from_directory_bang(root, directory) do
    require_owned_transaction_directory_bang(directory)
    journal_path = Path.join(directory, "journal.json")
    result = File.lstat(journal_path)

    if has_tag(result, :error) do
      reason = Kernel.elem(result, 1)

      if same_term(reason, :enoent) do
        {:discard_incomplete, directory}
      else
        Kernel.raise(
          "cannot inspect project patch journal #{journal_path}: #{Kernel.inspect(reason)}"
        )
      end
    else
      stat = Kernel.elem(result, 1)

      if stat.type != :regular do
        Kernel.raise(
          "project patch journal is not a regular file (#{Kernel.to_string(stat.type)}): #{journal_path}"
        )
      else
        transaction = read_journal_bang(root, directory, journal_path)

        complete =
          Enum.all?(transaction.operations, fn staged ->
            same_state(snapshot_bang(root, staged.operation.path), staged.operation.after)
          end)

        if complete do
          validate_commit_cleanup_bang(transaction)
          {:commit_cleanup, transaction}
        else
          validate_recoverable_targets(transaction)
          {:rollback, transaction}
        end
      end
    end
  end

  defp validate_commit_cleanup_bang(transaction) do
    Enum.each(transaction.operations, fn staged ->
      verify_target_bang(transaction.root, staged.operation, "after")
      validate_owned_temp_bang(transaction.root, staged.new_path, staged.operation.after)
    end)

    :ok
  end

  defp validate_owned_temp_bang(root, path, expected) do
    if Kernel.is_nil(path) do
      :ok
    else
      current = snapshot_bang(root, path)

      if current.state != :missing and not same_state(current, expected) do
        Kernel.raise("project patch temporary file failed integrity validation: #{path}")
      else
        :ok
      end
    end
  end

  defp remove_incomplete_transaction_bang(directory) do
    require_owned_transaction_directory_bang(directory)
    result = File.rm_rf(directory)

    if has_tag(result, :ok) do
      :ok
    else
      reason = Kernel.elem(result, 1)
      path = Kernel.elem(result, 2)
      Kernel.raise("cannot remove incomplete transaction #{path}: #{Kernel.inspect(reason)}")
    end
  end

  defp write_journal_bang(transaction) do
    journal =
      json_object([
        {"protocol", "reflaxe-elixir/project-patch"},
        {"version", 1},
        {"id", transaction.id},
        {"createdDirectories",
         Enum.map(transaction.created_dirs, fn path ->
           Path.relative_to(path, transaction.root)
         end)},
        {"operations", Enum.map(transaction.operations, &operation_to_json/1)}
      ])

    content = Jason.encode!(journal, [{:pretty, true}])
    atomic_write_bang(Path.join(transaction.directory, "journal.json"), "#{content}\n")
    :ok
  end

  defp operation_to_json(staged) do
    json_object([
      {"kind", Kernel.to_string(staged.operation.kind)},
      {"path", staged.operation.relative},
      {"before", state_to_json(staged.operation.before)},
      {"after", state_to_json(staged.operation.after)},
      {"newPath", staged.new_relative},
      {"backupPath", staged.backup_relative},
      {"manifest", staged.operation.manifest?}
    ])
  end

  defp state_to_json(state) do
    if state.state == :missing,
      do: json_object([{"state", "missing"}]),
      else: json_object([{"state", "regular"}, {"sha256", state.sha256}, {"mode", state.mode}])
  end

  defp read_journal_bang(root, directory, path) do
    decoded = Jason.decode(File.read!(path))

    if not has_tag(decoded, :ok) do
      Kernel.raise("invalid project patch transaction journal: #{path}")
    else
      json = Kernel.elem(decoded, 1)

      if not Kernel.is_map(json) do
        Kernel.raise("invalid project patch transaction journal: #{path}")
      else
        protocol = Map.get(json, "protocol")
        version = Map.get(json, "version")
        id = Map.get(json, "id")
        created = Map.get(json, "createdDirectories")
        operation_values = Map.get(json, "operations")

        if not same_term(protocol, "reflaxe-elixir/project-patch") or not same_term(version, 1) or
             not valid_transaction_id(id) or not Kernel.is_list(created) or
             not Kernel.is_list(operation_values) do
          Kernel.raise("invalid project patch transaction journal: #{path}")
        else
          operation_terms = Kernel.elem({:ok, operation_values}, 1)

          operations =
            Enum.map(Enum.with_index(operation_terms), fn entry ->
              operation_from_json_bang(
                root,
                directory,
                Kernel.elem(id_value(id), 0),
                Kernel.elem(entry, 0),
                Kernel.elem(entry, 1)
              )
            end)

          created_values = Kernel.elem({:ok, created}, 1)

          transaction = %{
            root: root,
            directory: directory,
            id: elem(id_value(id), 0),
            created_dirs:
              Enum.map(created_values, fn relative ->
                path_from_relative_bang(
                  root,
                  require_binary(relative, "invalid project patch transaction journal: " <> path)
                )
              end),
            operations: operations
          }

          validate_loaded_transaction_bang(transaction)
          transaction
        end
      end
    end
  end

  defp operation_from_json_bang(root, directory, id, json, index) do
    if not Kernel.is_map(json) do
      Kernel.raise("invalid project patch operation: #{Kernel.inspect(json)}")
    else
      kind_value = Map.get(json, "kind")

      kind =
        cond do
          same_term(kind_value, "write") -> :write
          same_term(kind_value, "delete") -> :delete
          true -> nil
        end

      if Kernel.is_nil(kind) do
        Kernel.raise("invalid project patch operation kind: #{Kernel.inspect(kind_value)}")
      else
        relative =
          require_binary(fetch_json_bang(json, "path"), "invalid project patch operation path")

        path = path_from_relative_bang(root, relative)
        reject_reserved_target_bang(relative)
        before = state_from_json_bang(fetch_json_bang(json, "before"))
        after_state = state_from_json_bang(fetch_json_bang(json, "after"))
        manifest = required_boolean_bang(json, "manifest")
        validate_operation_states_bang(kind, before, after_state, relative)

        operation =
          HaxeProjectPatch.Operation.new(
            kind,
            path,
            relative,
            before,
            after_state,
            if(kind == :delete, do: :removed, else: :patched),
            manifest
          )

        new_path = nullable_relative_path_bang(root, Map.get(json, "newPath"))
        backup_path = nullable_relative_path_bang(root, Map.get(json, "backupPath"))

        expected_backup =
          if before.state == :regular do
            Path.join([directory, "backups", Integer.to_string(index)])
          else
            nil
          end

        expected_new =
          if kind == :write do
            Path.join(
              Path.dirname(path),
              ".#{Path.basename(path)}.reflaxe-patch-#{id}-#{Integer.to_string(index)}.new"
            )
          else
            nil
          end

        if backup_path != expected_backup do
          Kernel.raise("invalid project patch backup path for #{relative}")
        else
          if new_path != expected_new do
            Kernel.raise("invalid project patch temporary path for #{relative}")
          else
            %{
              operation: operation,
              new_path: new_path,
              new_relative: relative_or_nil(root, new_path),
              backup_path: backup_path,
              backup_relative: relative_or_nil(root, backup_path)
            }
          end
        end
      end
    end
  end

  defp validate_loaded_transaction_bang(transaction) do
    operations = transaction.operations

    if length(operations) == 0 do
      Kernel.raise("project patch transaction contains no operations")
    else
      validate_staged_paths_bang(operations)

      manifest_indices =
        Enum.flat_map(Enum.with_index(operations), fn entry ->
          staged = Kernel.elem(entry, 0)
          if staged.operation.manifest?, do: [Kernel.elem(entry, 1)], else: []
        end)

      if length(manifest_indices) > 1 or
           (length(manifest_indices) == 1 and
              Enum.at(manifest_indices, 0) != length(operations) - 1) do
        Kernel.raise("project patch transaction manifest must be the final operation")
      else
        created_dirs = transaction.created_dirs
        assert_unique_paths_bang(created_dirs, "created directory")

        sorted_dirs =
          Enum.sort_by(created_dirs, fn path -> path_depth(transaction.root, path) end)

        if not same_term(created_dirs, sorted_dirs) do
          Kernel.raise("project patch created directories are not ordered from parent to child")
        else
          allowed_created_dirs =
            MapSet.new(
              Enum.flat_map(
                Enum.filter(operations, fn staged -> staged.operation.kind == :write end),
                fn staged -> parent_directories(transaction.root, staged.operation.path) end
              )
            )

          Enum.each(created_dirs, fn directory ->
            if not MapSet.member?(allowed_created_dirs, directory) do
              Kernel.raise("invalid project patch created directory: " <> directory)
            end
          end)

          :ok
        end
      end
    end
  end

  defp validate_operation_states_bang(kind, before, after_state, relative) do
    cond do
      kind == :write and after_state.state == :regular ->
        if same_state(before, after_state) do
          Kernel.raise("project patch journal contains a no-op write for " <> relative)
        else
          :ok
        end

      kind == :delete and before.state == :regular and after_state.state == :missing ->
        :ok

      true ->
        Kernel.raise(
          "invalid project patch " <>
            Kernel.to_string(kind) <>
            " state transition for " <>
            relative <>
            ": " <> Kernel.inspect(before.state) <> " -> " <> Kernel.inspect(after_state.state)
        )
    end
  end

  defp required_boolean_bang(json, key) do
    fetched = Map.fetch(json, key)

    if not has_tag(fetched, :ok) do
      Kernel.raise("invalid project patch boolean field: #{key}")
    else
      value = Kernel.elem(fetched, 1)

      if Kernel.is_boolean(value) do
        Kernel.elem({:ok, value}, 1)
      else
        Kernel.raise("invalid project patch boolean field: #{key}")
      end
    end
  end

  defp valid_transaction_id(id) do
    Kernel.is_binary(id) and
      Regex.match?(Regex.compile!("\\A[1-9][0-9]*\\z"), Kernel.elem({:ok, id}, 1))
  end

  defp id_value(id) do
    {Kernel.elem({:ok, id}, 1)}
  end

  defp present_path(path) do
    if Kernel.is_nil(path), do: [], else: [path]
  end

  defp assert_unique_paths_bang(paths, label) do
    if length(paths) != MapSet.size(MapSet.new(paths)) do
      Kernel.raise("project patch transaction contains duplicate #{label} paths")
    else
      :ok
    end
  end

  defp parent_directories(root, path) do
    relative = Path.relative_to(Path.dirname(path), root)

    if relative == "." do
      []
    else
      Enum.scan(Path.split(relative), root, fn part, parent -> Path.join(parent, part) end)
    end
  end

  defp path_depth(root, path) do
    length(Path.split(Path.relative_to(path, root)))
  end

  defp state_from_json_bang(json) do
    if not Kernel.is_map(json) do
      Kernel.raise("invalid project patch file state: #{Kernel.inspect(json)}")
    else
      state = Map.get(json, "state")

      cond do
        same_term(state, "missing") -> missing_state()
        same_term(state, "regular") -> regular_state_from_json_bang(json)
        true -> Kernel.raise("invalid project patch file state: " <> Kernel.inspect(json))
      end
    end
  end

  defp regular_state_from_json_bang(json) do
    digest = Map.get(json, "sha256")
    mode = Map.get(json, "mode")

    if not Kernel.is_binary(digest) or not Kernel.is_integer(mode) do
      Kernel.raise("invalid project patch file state: #{Kernel.inspect(json)}")
    else
      sha = Kernel.elem({:ok, digest}, 1)
      numeric_mode = Kernel.elem({:ok, mode}, 1)

      if String.length(sha) != 64 or numeric_mode < 0 or numeric_mode > 4095 or
           not Regex.match?(Regex.compile!("\\A[0-9a-f]{64}\\z"), sha) do
        Kernel.raise("invalid project patch content digest: #{Kernel.inspect(digest)}")
      else
        %{state: :regular, sha256: sha, mode: numeric_mode}
      end
    end
  end

  defp verify_target_bang(root, operation, side) do
    expected = if side == "before", do: operation.before, else: operation.after
    current = snapshot_bang(root, operation.path)

    if not same_state(current, expected) do
      Kernel.raise("project patch target changed before publication: #{operation.path}")
    else
      :ok
    end
  end

  defp invoke_fault_bang(fault_injector, stage, operation) do
    result = fault_injector.(stage, operation)

    if same_term(result, :ok) do
      :ok
    else
      if has_tag(result, :error) do
        Kernel.raise(
          "injected project patch failure: #{Kernel.to_string(Kernel.elem(result, 1))}"
        )
      else
        Kernel.raise("invalid project patch fault injector result: #{Kernel.inspect(result)}")
      end
    end
  end

  defp safely(fun) do
    try do
      fun.()
      :ok
    rescue
      error ->
        {:error, error}
    end
  end

  defp snapshot_bang(root, path) do
    validate_parent_chain_bang(root, path)
    result = File.lstat(path)

    if has_tag(result, :error) do
      reason = Kernel.elem(result, 1)

      if same_term(reason, :enoent) do
        missing_state()
      else
        Kernel.raise("cannot inspect project patch target #{path}: #{Kernel.inspect(reason)}")
      end
    else
      snapshot_regular_bang(path, result)
    end
  end

  defp snapshot_regular_bang(path, result) do
    stat = Kernel.elem(result, 1)

    if stat.type != :regular do
      Kernel.raise(
        "project patch target is not a regular file (#{Kernel.to_string(stat.type)}): #{path}"
      )
    else
      regular_state(File.read!(path), Bitwise.band(stat.mode, 4095))
    end
  end

  defp missing_state() do
    %{state: :missing}
  end

  defp regular_state(content, mode) do
    %{state: :regular, content: content, sha256: sha256(content), mode: mode}
  end

  defp same_state(left, right) do
    if left.state == :missing or right.state == :missing,
      do: left.state == :missing and right.state == :missing,
      else:
        left.state == :regular and right.state == :regular and left.sha256 == right.sha256 and
          left.mode == right.mode
  end

  defp sha256(content) do
    Base.encode16(:crypto.hash(:sha256, content), [{:case, :lower}])
  end

  defp normalize_target_bang(root, path) do
    path_type = Path.type(path)

    absolute =
      if path_type == :absolute do
        Path.expand(path)
      else
        Path.expand(path, root)
      end

    relative = Path.relative_to(absolute, root)

    if relative == "." or escapes_root(relative) do
      Kernel.raise("project patch target escapes the project root: #{path}")
    else
      reject_reserved_target_bang(relative)
      validate_parent_chain_bang(root, absolute)
      {absolute, relative}
    end
  end

  defp path_from_relative_bang(root, relative) do
    path_type = Path.type(relative)

    if path_type == :absolute or relative == "." or escapes_root(relative) do
      Kernel.raise("invalid project patch relative path: #{Kernel.inspect(relative)}")
    else
      path = Path.expand(relative, root)

      if Path.relative_to(path, root) != relative do
        Kernel.raise("project patch relative path is not canonical: #{Kernel.inspect(relative)}")
      else
        validate_parent_chain_bang(root, path)
        path
      end
    end
  end

  defp nullable_relative_path_bang(root, path) do
    if Kernel.is_nil(path),
      do: nil,
      else:
        path_from_relative_bang(
          root,
          require_binary(path, "invalid project patch relative path: #{Kernel.inspect(path)}")
        )
  end

  defp relative_or_nil(root, path) do
    if Kernel.is_nil(path) do
      nil
    else
      Path.relative_to(path, root)
    end
  end

  defp reject_reserved_target_bang(relative) do
    if relative == ".reflaxe-elixir-project-patch" or
         String.starts_with?(relative, ".reflaxe-elixir-project-patch/") do
      Kernel.raise("project patch target uses the reserved transaction path: #{relative}")
    else
      :ok
    end
  end

  defp escapes_root(relative) do
    path_type = Path.type(relative)
    path_type == :absolute or relative == ".." or String.starts_with?(relative, "../")
  end

  defp validate_parent_chain_bang(root, path) do
    require_directory_bang(root, "project patch root")
    relative = Path.relative_to(path, root)

    if escapes_root(relative) do
      Kernel.raise("project patch path escapes the project root: #{path}")
    else
      validate_parent_parts_bang(Path.split(Path.dirname(relative)), 0, root)
      :ok
    end
  end

  defp validate_parent_parts_bang(parts, index, current) do
    if index >= length(parts) do
      current
    else
      part = Enum.at(parts, index)

      if part == "." do
        validate_parent_parts_bang(parts, index + 1, current)
      else
        next = Path.join(current, part)
        result = File.lstat(next)

        if has_tag(result, :ok) do
          stat = Kernel.elem(result, 1)

          if stat.type != :directory do
            Kernel.raise(
              "project patch parent is not a directory (#{Kernel.to_string(stat.type)}): #{next}"
            )
          else
            validate_parent_parts_bang(parts, index + 1, next)
          end
        else
          reason = Kernel.elem(result, 1)

          if same_term(reason, :enoent) do
            next
          else
            Kernel.raise("cannot inspect project patch parent #{next}: #{Kernel.inspect(reason)}")
          end
        end
      end
    end
  end

  defp require_directory_bang(path, label) do
    result = File.lstat(path)

    if has_tag(result, :ok) do
      stat = Kernel.elem(result, 1)

      if stat.type == :directory do
        :ok
      else
        Kernel.raise("#{label} is not a directory (#{Kernel.to_string(stat.type)}): #{path}")
      end
    else
      Kernel.raise("cannot inspect #{label} #{path}: #{Kernel.inspect(Kernel.elem(result, 1))}")
    end
  end

  defp require_owned_transaction_directory_bang(directory) do
    require_directory_bang(directory, "project patch transaction path")
    owner = Path.join(directory, "owner")
    result = File.lstat(owner)

    if has_tag(result, :ok) do
      stat = Kernel.elem(result, 1)

      if stat.type != :regular do
        Kernel.raise(
          "project patch transaction owner is not a regular file (#{Kernel.to_string(stat.type)}): #{owner}"
        )
      else
        if File.read!(owner) != "reflaxe.elixir project patch transaction v1\n" do
          Kernel.raise("project patch transaction owner marker is invalid: #{owner}")
        else
          :ok
        end
      end
    else
      Kernel.raise(
        "cannot inspect project patch transaction owner #{owner}: #{Kernel.inspect(Kernel.elem(result, 1))}"
      )
    end
  end

  defp write_exclusive_bang(path, content, mode) do
    File.write!(path, content, [:write, :exclusive, :binary])
    File.chmod!(path, mode)
    :ok
  end

  defp atomic_write_bang(path, content) do
    temp = "#{path}.tmp"
    File.write!(temp, content, [:write, :exclusive, :binary])
    File.rename!(temp, path)
    :ok
  end

  defp json_object(pairs) do
    build_json_object(pairs, 0, Map.new())
  end

  defp build_json_object(pairs, index, value) do
    if index >= length(pairs) do
      value
    else
      pair = Enum.at(pairs, index)
      build_json_object(pairs, index + 1, Map.put(value, elem(pair, 0), elem(pair, 1)))
    end
  end

  defp fetch_json_bang(json, key) do
    fetched = Map.fetch(json, key)

    if has_tag(fetched, :ok) do
      Kernel.elem(fetched, 1)
    else
      Kernel.raise("missing project patch JSON field: #{key}")
    end
  end

  defp require_binary(value, message) do
    if Kernel.is_binary(value) do
      Kernel.elem({:ok, value}, 1)
    else
      Kernel.raise(message)
    end
  end

  defp marker_span(content, begin_token, end_token) do
    if begin_token == "" or end_token == "" or begin_token == end_token do
      error({:invalid_marker_tokens, begin_token, end_token})
    else
      lines = String.split(content, "\n")
      begins = matching_line_indices(lines, begin_token)
      ends = matching_line_indices(lines, end_token)

      if length(begins) == 0 and length(ends) == 0 do
        :missing
      else
        if length(begins) == 1 and length(ends) == 1 do
          begin_index = Enum.at(begins, 0)
          end_index = Enum.at(ends, 0)

          if begin_index < end_index,
            do: {:ok, lines, begin_index, end_index},
            else: error({:inverted_marker_pair, begin_token, end_token, begin_index, end_index})
        else
          error({:marker_count, begin_token, length(begins), end_token, length(ends)})
        end
      end
    end
  end

  defp matching_line_indices(lines, token) do
    Enum.flat_map(Enum.with_index(lines), fn entry ->
      line = Kernel.elem(entry, 0)
      index = Kernel.elem(entry, 1)
      if marker_token_on_line(line, token), do: [index], else: []
    end)
  end

  defp marker_token_on_line(line, token) do
    pattern = "(?:^|\\s)#{Regex.escape(token)}(?=$|\\s)"
    Regex.match?(Regex.compile!(pattern), line)
  end

  defp replace_line_span(lines, begin_index, end_index, replacement) do
    updated =
      Enum.flat_map(Enum.with_index(lines), fn entry ->
        line = Kernel.elem(entry, 0)
        index = Kernel.elem(entry, 1)

        if index < begin_index do
          [line]
        else
          if index == begin_index do
            replacement
          else
            if index <= end_index, do: [], else: [line]
          end
        end
      end)

    Enum.join(updated, "\n")
  end

  defp leading_indent(line) do
    leading =
      Enum.take_while(String.graphemes(line), fn character ->
        character == " " or character == "\t"
      end)

    Enum.join(leading, "")
  end

  defp decode_json_object(content) do
    decoded = Jason.decode(content)

    if has_tag(decoded, :ok) do
      value = Kernel.elem(decoded, 1)
      if Kernel.is_map(value), do: ok(value), else: error("package JSON must contain an object")
    else
      reason = Kernel.elem(decoded, 1)
      error("invalid package JSON: #{Exception.message(reason)}")
    end
  end

  defp validate_key_path(path) do
    validate_key_path_at(path, 0)
  end

  defp fetch_json_path(json, path, parents) do
    key = Enum.at(path, 0)
    fetched = Map.fetch(json, key)

    if same_term(fetched, :error) do
      :missing
    else
      value = Kernel.elem(fetched, 1)

      if length(path) == 1 do
        ok(value)
      else
        if not Kernel.is_map(value) do
          error(
            "package JSON key path #{Enum.join(Enum.concat(parents, [key]), ".")} must contain an object"
          )
        else
          fetch_json_path(value, Enum.drop(path, 1), Enum.concat(parents, [key]))
        end
      end
    end
  end

  defp strip_json_path(json, path) do
    key = Enum.at(path, 0)

    if length(path) == 1 do
      Map.delete(json, key)
    else
      fetched = Map.fetch(json, key)

      if same_term(fetched, :error) do
        json
      else
        value = Kernel.elem(fetched, 1)

        if not Kernel.is_map(value) do
          json
        else
          child = strip_json_path(value, Enum.drop(path, 1))

          if Kernel.map_size(child) == 0 do
            Map.delete(json, key)
          else
            Map.put(json, key, child)
          end
        end
      end
    end
  end

  defp tuple_tag(value) do
    if Kernel.is_tuple(value) and Kernel.tuple_size(value) > 0 do
      Kernel.elem(value, 0)
    else
      nil
    end
  end

  defp collect_marker_spans(content, pairs, index, spans) do
    if index >= length(pairs) do
      ok(spans)
    else
      pair = Enum.at(pairs, index)
      span = marker_span(content, elem(pair, 0), elem(pair, 1))

      if has_tag(span, :error) do
        span
      else
        updated = spans

        updated =
          if not same_term(span, :missing) do
            Enum.concat(spans, [
              %{first: Kernel.elem(span, 2), last: Kernel.elem(span, 3), token: elem(pair, 0)}
            ])
          else
            updated
          end

        collect_marker_spans(content, pairs, index + 1, updated)
      end
    end
  end

  defp validate_ordered_spans(spans, index) do
    if index >= length(spans) do
      :ok
    else
      first = Enum.at(spans, index - 1)
      second = Enum.at(spans, index)

      if second.first <= first.last,
        do:
          error(
            {:overlapping_marker_pairs, first.token, {first.first, first.last}, second.token,
             {second.first, second.last}}
          ),
        else: validate_ordered_spans(spans, index + 1)
    end
  end

  defp validate_key_path_at(path, index) do
    if index >= length(path) do
      if length(path) == 0,
        do: error("package JSON key path must contain non-empty strings"),
        else: :ok
    else
      if Enum.at(path, index) == "",
        do: error("package JSON key path must contain non-empty strings"),
        else: validate_key_path_at(path, index + 1)
    end
  end

  defp has_tag(value, tag) do
    actual = tuple_tag(value)
    same_term(actual, tag)
  end

  defp same_term(left, right) do
    left == right
  end

  defp ok(value) do
    {:ok, value}
  end

  defp error(reason) do
    {:error, reason}
  end
end

defmodule Template do
  defp __haxe_static_get__(key, init) do
    static_key = {:__haxe_static__, Template, key}
    (case Process.get(static_key) do
      {:set, value} -> value
      nil ->
        value = init
        _ = Process.put(static_key, {:set, value})
        value
    end)
  end
  defp __haxe_static_put__(key, value) do
    static_key = {:__haxe_static__, Template, key}
    _ = Process.put(static_key, {:set, value})
    value
  end
  def globals() do
    __haxe_static_get__(:globals, %{})
  end
  def globals(value) do
    __haxe_static_put__(:globals, value)
  end
  def new(str) do
    struct = %{:__reflaxe_class__ => Template, :source => nil}
    struct = %{struct | source: str}
    struct
  end
  def execute(struct, context, macros) do
    render(struct.source, context, (if (Reflaxe.Elixir.HaxeFloat.eq(macros, nil)), do: %{}, else: macros), Template.globals())
  end
  defp render(source_param, context, macros, globals) do

    template = source_param
    root_context = context
    macro_context = macros || %{}
    global_context = globals || %{}

    trim = fn text -> String.trim(Kernel.to_string(text)) end

    fetch_key = fn container, key ->
      cond do
        Kernel.is_nil(container) ->
          :missing

        is_map(container) ->
          atom_key = String.to_atom(key)

          cond do
            Map.has_key?(container, key) -> {:found, Map.get(container, key)}
            Map.has_key?(container, atom_key) -> {:found, Map.get(container, atom_key)}
            true -> :missing
          end

        true ->
          :missing
      end
    end

    lookup_path = fn _lookup_path, stack, path ->
      parts = String.split(trim.(path), ".")

      read_from = fn read_from, container, remaining ->
        case remaining do
          [] ->
            {:found, container}

          [key | rest] ->
            case fetch_key.(container, key) do
              {:found, value} -> read_from.(read_from, value, rest)
              :missing -> :missing
            end
        end
      end

      found =
        Enum.find_value(stack, :missing, fn ctx ->
          case read_from.(read_from, ctx, parts) do
            {:found, value} -> {:found, value}
            :missing -> nil
          end
        end)

      case found do
        {:found, value} ->
          value

        :missing ->
          case read_from.(read_from, global_context, parts) do
            {:found, value} -> value
            :missing -> nil
          end
      end
    end

    eval_expr = fn eval_expr, stack, expr ->
      expr = trim.(expr)

      cond do
        expr == "__current__" ->
          List.first(stack)

        expr == "true" ->
          true

        expr == "false" ->
          false

        expr == "null" ->
          nil

        String.starts_with?(expr, "!") ->
          value = eval_expr.(eval_expr, stack, String.slice(expr, 1..-1//1))
          Kernel.is_nil(value) or value == false

        String.starts_with?(expr, "\"") and String.ends_with?(expr, "\"") ->
          String.slice(expr, 1, String.length(expr) - 2)

        true ->
          case Integer.parse(expr) do
            {integer, ""} ->
              integer

            _ ->
              if Regex.match?(~r/^[+-]?(?:(?:\d+\.\d*)|(?:\.\d+)|(?:\d+))(?:[eE][+-]?\d+)?$/, expr) do
                Reflaxe.Elixir.HaxeFloat.parse(expr)
              else
                lookup_path.(lookup_path, stack, expr)
              end
          end
      end
    end

    stringify = fn
      nil -> "null"
      true -> "true"
      false -> "false"
      value when is_binary(value) -> value
      value -> Reflaxe.Elixir.HaxeFloat.to_string(value)
    end

    find_directive = fn text, start_pos ->
      tail = binary_part(text, start_pos, byte_size(text) - start_pos)

      case :binary.match(tail, "::") do
        {offset, _} -> start_pos + offset
        :nomatch -> nil
      end
    end

    read_directive = fn text, marker_pos ->
      body_start = marker_pos + 2
      tail = binary_part(text, body_start, byte_size(text) - body_start)

      case :binary.match(tail, "::") do
        {offset, _} ->
          body = binary_part(text, body_start, offset)
          {trim.(body), body_start + offset + 2}

        :nomatch ->
          raise Reflaxe.Elixir.HaxeThrow, [value: "Unclosed template directive"]
      end
    end

    find_if_block = fn _find_if_block, text, start_pos ->
      scan = fn scan, pos, depth, else_info ->
        marker = find_directive.(text, pos)

        if Kernel.is_nil(marker) do
          raise Reflaxe.Elixir.HaxeThrow, [value: "Unclosed template block"]
        else
          {directive, after_directive} = read_directive.(text, marker)

          cond do
            String.starts_with?(directive, "if ") or String.starts_with?(directive, "foreach ") ->
              scan.(scan, after_directive, depth + 1, else_info)

            directive == "end" and depth == 0 ->
              {else_info, marker, after_directive}

            directive == "end" ->
              scan.(scan, after_directive, depth - 1, else_info)

            directive == "else" and depth == 0 and Kernel.is_nil(else_info) ->
              scan.(scan, after_directive, depth, {marker, after_directive})

            true ->
              scan.(scan, after_directive, depth, else_info)
          end
        end
      end

      scan.(scan, start_pos, 0, nil)
    end

    find_end_block = fn _find_end_block, text, start_pos ->
      {_, end_pos, after_end} = find_if_block.(find_if_block, text, start_pos)
      {end_pos, after_end}
    end

    find_macro_end = fn text, open_pos ->
      scan = fn scan, pos, depth ->
        if pos >= byte_size(text) do
          raise Reflaxe.Elixir.HaxeThrow, [value: "Unclosed macro parenthesis"]
        end

        char = :binary.at(text, pos)

        cond do
          char == ?( ->
            scan.(scan, pos + 1, depth + 1)

          char == ?) and depth == 0 ->
            pos

          char == ?) ->
            scan.(scan, pos + 1, depth - 1)

          true ->
            scan.(scan, pos + 1, depth)
        end
      end

      scan.(scan, open_pos + 1, 0)
    end

    split_macro_args = fn args_text ->
      if trim.(args_text) == "" do
        []
      else
        String.split(args_text, ",") |> Enum.map(trim)
      end
    end

    render_segment = fn render_segment, text, stack ->
      render_from = fn render_from, pos, acc ->
        if pos >= byte_size(text) do
          acc
        else
          tail = binary_part(text, pos, byte_size(text) - pos)
          directive_match = :binary.match(tail, "::")
          macro_match = :binary.match(tail, <<36, 36>>)

          {kind, marker} =
            case {directive_match, macro_match} do
              {:nomatch, :nomatch} -> {nil, nil}
              {{directive_offset, _}, :nomatch} -> {:directive, pos + directive_offset}
              {:nomatch, {macro_offset, _}} -> {:macro, pos + macro_offset}
              {{directive_offset, _}, {macro_offset, _}} when directive_offset <= macro_offset -> {:directive, pos + directive_offset}
              {_, {macro_offset, _}} -> {:macro, pos + macro_offset}
            end

          if Kernel.is_nil(kind) do
            acc <> binary_part(text, pos, byte_size(text) - pos)
          else
            acc = acc <> binary_part(text, pos, marker - pos)

            case kind do
              :directive ->
                {directive, after_directive} = read_directive.(text, marker)

                cond do
                  String.starts_with?(directive, "if ") ->
                    condition = String.slice(directive, 3, String.length(directive) - 3)
                    {else_info, end_pos, after_end} = find_if_block.(find_if_block, text, after_directive)
                    value = eval_expr.(eval_expr, stack, condition)

                    rendered =
                      if Kernel.is_nil(value) or value == false do
                        case else_info do
                          nil -> ""
                          {_, else_after} -> render_segment.(render_segment, binary_part(text, else_after, end_pos - else_after), stack)
                        end
                      else
                        true_end = case else_info do nil -> end_pos; {else_pos, _} -> else_pos end
                        render_segment.(render_segment, binary_part(text, after_directive, true_end - after_directive), stack)
                      end

                    render_from.(render_from, after_end, acc <> rendered)

                  String.starts_with?(directive, "foreach ") ->
                    expr = String.slice(directive, 8, String.length(directive) - 8)
                    {end_pos, after_end} = find_end_block.(find_end_block, text, after_directive)
                    body = binary_part(text, after_directive, end_pos - after_directive)
                    value = eval_expr.(eval_expr, stack, expr)

                    items =
                      cond do
                        is_list(value) -> value
                        is_map(value) -> Map.values(value)
                        Kernel.is_nil(value) -> []
                        true -> raise Reflaxe.Elixir.HaxeThrow, [value: "Cannot iter on " <> Kernel.inspect(value)]
                      end

                    rendered = Enum.map_join(items, "", fn item -> render_segment.(render_segment, body, [item | stack]) end)
                    render_from.(render_from, after_end, acc <> rendered)

                  directive in ["else", "end"] ->
                    raise Reflaxe.Elixir.HaxeThrow, [value: "Unexpected template directive " <> directive]

                  true ->
                    value = eval_expr.(eval_expr, stack, directive)
                    render_from.(render_from, after_directive, acc <> stringify.(value))
                end

              :macro ->
                name_start = marker + 2
                rest = binary_part(text, name_start, byte_size(text) - name_start)

                case :binary.match(rest, "(") do
                  :nomatch ->
                    render_from.(render_from, marker + 2, acc <> <<36, 36>>)

                  {open_offset, _} ->
                    open_pos = name_start + open_offset
                    name = binary_part(text, name_start, open_offset)
                    close_pos = find_macro_end.(text, open_pos)
                    args_text = binary_part(text, open_pos + 1, close_pos - open_pos - 1)
                    resolver = fn name -> lookup_path.(lookup_path, stack, name) end
                    args = [resolver | Enum.map(split_macro_args.(args_text), fn arg -> eval_expr.(eval_expr, stack, arg) end)]
                    macro_fun = lookup_path.(lookup_path, [macro_context], name)

                    if Kernel.is_nil(macro_fun) do
                      raise Reflaxe.Elixir.HaxeThrow, [value: "Missing template macro " <> name]
                    end

                    rendered = apply(macro_fun, args) |> stringify.()
                    render_from.(render_from, close_pos + 1, acc <> rendered)
                end
            end
          end
        end
      end

      render_from.(render_from, 0, "")
    end

    render_segment.(render_segment, template, [root_context])

  end
end

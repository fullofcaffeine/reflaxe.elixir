defmodule EReg do
  defstruct regex: nil, global: false, cap_count: 0, ref: nil
  def new(pattern, options) do
    opts = if Kernel.is_nil(options), do: "", else: options
    global = String.contains?(opts, "g")
    compile_opts = String.replace(opts, "g", "")
    regex = Regex.compile!(pattern, compile_opts)
    cap_count = elem(regex.re_pattern, 1)
    %__MODULE__{regex: regex, global: global, cap_count: cap_count, ref: make_ref()}
  end
  def match(struct, s), do: match_sub(struct, s, 0, -1)
  def match_sub(struct, s, pos, len \\ -1) do
    subject = s
    pos_g = max(pos, 0)
    len_g = len
    total_g = String.length(subject)
    pos_g = if pos_g > total_g, do: total_g, else: pos_g
    end_g = if len_g < 0, do: total_g, else: min(pos_g + len_g, total_g)
    prefix = String.slice(subject, 0, end_g)
    offset_b = byte_size(String.slice(subject, 0, pos_g))
    indices = Regex.run(struct.regex, prefix, [return: :index, offset: offset_b])
    if indices == nil do
      Process.delete({:reflaxe_ereg, struct.ref})
      false
    else
      expected = struct.cap_count + 1
      missing = expected - length(indices)
      pad = if missing > 0, do: List.duplicate({-1, 0}, missing), else: []
      padded = indices ++ pad
      [{mpos_b, mlen_b} | _] = padded
      mpos_g = if mpos_b < 0, do: -1, else: String.length(binary_part(subject, 0, mpos_b))
      mlen_g = if mpos_b < 0, do: 0, else: String.length(binary_part(subject, mpos_b, mlen_b))
      matches =
        Enum.map(padded, fn
          {p, l} when is_integer(p) and p >= 0 -> binary_part(subject, p, l)
          _ -> nil
        end)
      Process.put({:reflaxe_ereg, struct.ref}, %{subject: subject, matches: matches, pos: mpos_g, len: mlen_g})
      true
    end
  end
  def matched(struct, n) do
    state = Process.get({:reflaxe_ereg, struct.ref})
    if state == nil, do: haxe_throw("EReg::matched")
    matches = state.matches
    if n >= 0 and n < length(matches), do: Enum.at(matches, n), else: haxe_throw("EReg::matched")
  end
  def matched_left(struct) do
    state = Process.get({:reflaxe_ereg, struct.ref})
    if state == nil, do: haxe_throw("No string matched")
    String.slice(state.subject, 0, state.pos)
  end
  def matched_right(struct) do
    state = Process.get({:reflaxe_ereg, struct.ref})
    if state == nil, do: haxe_throw("No string matched")
    start = state.pos + state.len
    String.slice(state.subject, start, String.length(state.subject) - start)
  end
  def matched_pos(struct) do
    state = Process.get({:reflaxe_ereg, struct.ref})
    if state == nil, do: haxe_throw("No string matched")
    %{pos: state.pos, len: state.len}
  end
  def split(struct, s) do
    if struct.global do
      Regex.split(struct.regex, s)
    else
      Regex.split(struct.regex, s, parts: 2)
    end
  end
  def replace(struct, s, by) do
    parts = String.split(by, "$", trim: false)
    buf = replace_loop(struct, s, parts, 0, String.length(s), true, [])
    IO.iodata_to_binary(buf)
  end
  defp replace_loop(struct, s, parts, pos, len, first, buf) do
    if not match_sub(struct, s, pos, len) do
      [buf, String.slice(s, pos, len)]
    else
      %{pos: mpos, len: mlen} = matched_pos(struct)
      {mpos, done} =
        cond do
          mlen == 0 and not first and mpos == String.length(s) -> {mpos, true}
          mlen == 0 and not first -> {mpos + 1, false}
          true -> {mpos, false}
        end
      if done do
        [buf, String.slice(s, pos, len)]
      else
        buf = [buf, String.slice(s, pos, mpos - pos), build_replacement(struct, parts)]
        tot = mpos + mlen - pos
        pos = pos + tot
        len = len - tot
        if struct.global, do: replace_loop(struct, s, parts, pos, len, false, buf), else: [buf, String.slice(s, pos, len)]
      end
    end
  end
  defp build_replacement(struct, parts) do
    case parts do
      [] -> ""
      [head | tail] ->
        state = Process.get({:reflaxe_ereg, struct.ref})
        matches = if state == nil, do: [], else: state.matches
        build_replace_tail(struct, matches, tail, [head])
    end
  end
  defp build_replace_tail(_struct, _matches, [], acc), do: acc
  defp build_replace_tail(struct, matches, [k | rest], acc) do
    if k == "" do
      case rest do
        [] -> build_replace_tail(struct, matches, [], [acc, "$"])
        [next | rest2] ->
          acc2 = if next == "", do: [acc, "$"], else: [acc, "$", next]
          build_replace_tail(struct, matches, rest2, acc2)
      end
    else
      <<c, tail::binary>> = k
      if c >= ?1 and c <= ?9 do
        group_index = c - ?0
        if group_index > struct.cap_count do
          build_replace_tail(struct, matches, rest, [acc, "$", k])
        else
          capture = Enum.at(matches, group_index)
          acc2 = if capture == nil, do: [acc, tail], else: [acc, capture, tail]
          build_replace_tail(struct, matches, rest, acc2)
        end
      else
        build_replace_tail(struct, matches, rest, [acc, "$", k])
      end
    end
  end
  def map(struct, s, f) do
    total = String.length(s)
    {buf, offset} = map_loop(struct, s, f, 0, total, [])
    buf = if not struct.global and offset > 0 and offset < total, do: [buf, String.slice(s, offset, total - offset)], else: buf
    IO.iodata_to_binary(buf)
  end
  defp map_loop(struct, s, f, offset, total, buf) do
    cond do
      offset >= total -> {buf, offset}
      not match_sub(struct, s, offset, -1) -> {[buf, String.slice(s, offset, total - offset)], total}
      true ->
        %{pos: mpos, len: mlen} = matched_pos(struct)
        buf = [buf, String.slice(s, offset, mpos - offset), f.(struct)]
        {buf, new_offset} =
          if mlen == 0 do
            {[buf, String.slice(s, mpos, 1)], mpos + 1}
          else
            {buf, mpos + mlen}
          end
        if struct.global, do: map_loop(struct, s, f, new_offset, total, buf), else: {buf, new_offset}
    end
  end
  def escape(s), do: Regex.escape(s)
  defp haxe_throw(value), do: raise(Reflaxe.Elixir.HaxeThrow, [value: value])
end

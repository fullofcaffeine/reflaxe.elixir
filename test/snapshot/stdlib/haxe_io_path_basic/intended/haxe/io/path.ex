defmodule Haxe.IO.Path do
  import Kernel, except: [to_string: 1], warn: false
  def new(path) do
    struct = %{:__reflaxe_class__ => Haxe.IO.Path, :dir => nil, :file => nil, :ext => nil, :backslash => nil}
    struct = %{struct | backslash: false}
    struct = if (path == "." or path == "..") do
      struct = %{struct | dir: path}
      struct = %{struct | file: ""}
      %{struct | ext: nil}
    else
      slash_index = (case String.split(String.slice(path, 0, String.length(path)), "/") do
        parts when Kernel.length(parts) > 1 ->
          String.length(Enum.join((fn -> Enum.slice(parts, 0..-2//1) end).(), "/"))
        _ -> -1
      end)
      backslash_index = (case String.split(String.slice(path, 0, String.length(path)), "\\") do
        parts when Kernel.length(parts) > 1 ->
          String.length(Enum.join((fn -> Enum.slice(parts, 0..-2//1) end).(), "\\"))
        _ -> -1
      end)
      {path, struct} = cond do
        slash_index < backslash_index ->
          struct = %{struct | dir: String.slice(path, 0, backslash_index)}
          path = String.slice(path, backslash_index + 1..-1//1)
          struct = %{struct | backslash: true}
          {path, struct}
        backslash_index < slash_index ->
          struct = %{struct | dir: String.slice(path, 0, slash_index)}
          path = String.slice(path, slash_index + 1..-1//1)
          {path, struct}
        :true ->
          struct = %{struct | dir: nil}
          {path, struct}
      end
      dot_index = (case String.split(String.slice(path, 0, String.length(path)), ".") do
        parts when Kernel.length(parts) > 1 ->
          String.length(Enum.join((fn -> Enum.slice(parts, 0..-2//1) end).(), "."))
        _ -> -1
      end)
      if (dot_index != -1) do
        struct = %{struct | ext: String.slice(path, dot_index + 1..-1//1)}
        %{struct | file: String.slice(path, 0, dot_index)}
      else
        struct = %{struct | ext: nil}
        %{struct | file: path}
      end
    end
    struct
  end
  def to_string(struct) do
    directory_prefix = if (Kernel.is_nil(struct.dir)) do
      ""
    else
      "#{Kernel.to_string(struct.dir)}#{if (struct.backslash), do: "\\", else: "/"}"
    end
    extension_suffix = if (Kernel.is_nil(struct.ext)) do
      ""
    else
      ".#{Kernel.to_string(struct.ext)}"
    end
    "#{directory_prefix}#{struct.file}#{extension_suffix}"
  end
  def without_extension(path) do
    parsed_path = Haxe.IO.Path.new(path)
    parsed_path = %{parsed_path | ext: nil}
    _ = apply(Map.get(parsed_path, :__reflaxe_class__) || Map.get(parsed_path, :__struct__), :to_string, [parsed_path])
  end
  def without_directory(path) do
    parsed_path = Haxe.IO.Path.new(path)
    parsed_path = %{parsed_path | dir: nil}
    _ = apply(Map.get(parsed_path, :__reflaxe_class__) || Map.get(parsed_path, :__struct__), :to_string, [parsed_path])
  end
  def directory(path) do
    parsed_path = Haxe.IO.Path.new(path)
    if (Kernel.is_nil(parsed_path.dir)), do: "", else: parsed_path.dir
  end
  def extension(path) do
    parsed_path = Haxe.IO.Path.new(path)
    if (Kernel.is_nil(parsed_path.ext)), do: "", else: parsed_path.ext
  end
  def with_extension(path, extension) do
    parsed_path = Haxe.IO.Path.new(path)
    parsed_path = %{parsed_path | ext: extension}
    _ = apply(Map.get(parsed_path, :__reflaxe_class__) || Map.get(parsed_path, :__struct__), :to_string, [parsed_path])
  end
  def join(paths) do
    filtered_paths = []
    _g = 0
    filtered_paths = Enum.reduce(paths, filtered_paths, fn path, filtered_paths_acc ->
      if (not Kernel.is_nil(path) and path != "") do
        filtered_paths_acc = Enum.concat(filtered_paths_acc, [path])
        filtered_paths_acc
      else
        filtered_paths_acc
      end
    end)
    if (length(filtered_paths) == 0) do
      ""
    else
      result = Enum.at(filtered_paths, 0)
      _g = 1
      filtered_paths_length = length(filtered_paths)
      result = Enum.reduce(1..(filtered_paths_length - 1)//1, result, fn index, result_acc -> add_trailing_slash(result_acc) <> Enum.at(filtered_paths, index) end)
      _ = normalize(result)
    end
  end
  def normalize(path) do
    slash = "/"
    path = Enum.join((fn ->
      if ("\\" == "") do
        String.graphemes(path)
      else
        String.split(path, "\\")
      end
    end).(), slash)
    if (path == slash) do
      slash
    else
      target = []
      _g = 0
      g_value = if (slash == "") do
        String.graphemes(path)
      else
        String.split(path, slash)
      end
      target = Enum.reduce(g_value, target, fn part, target_acc ->
        cond do
          part == ".." and length(target_acc) > 0 and Enum.at(target_acc, (length(target_acc) - 1)) != ".." ->
            target_acc = without_last_part(target_acc)
            target_acc
          part == "" ->
            cond_value = Enum.at(String.to_charlist(path), 0) == Enum.at(String.to_charlist(slash), 0)
            target_acc = if (length(target_acc) > 0 or cond_value) do
  Enum.concat(target_acc, [part])
else
  target_acc
end
            target_acc
          part != "." ->
            target_acc = Enum.concat(target_acc, [part])
            target_acc
          :true -> target_acc
        end
      end)
      collapsed = Enum.join(target, slash)
      result = ""
      colon = false
      slashes = false
      _g = 0
      collapsed_length = String.length(collapsed)
      {result, _colon, _slashes} = Enum.reduce(0..(collapsed_length - 1)//1, {result, colon, slashes}, fn index, {result_acc, colon_acc, slashes_acc} ->
        code = if (index < 0) do
          nil
        else
          Enum.at(String.to_charlist(collapsed), index)
        end
        {_code, colon_acc, result_acc, slashes_acc} = cond do
          code == 58 ->
            result_acc = result_acc <> ":"
            colon_acc = true
            {code, colon_acc, result_acc, slashes_acc}
          code == 47 and not colon_acc ->
            slashes_acc = true
            {code, colon_acc, result_acc, slashes_acc}
          :true ->
            colon_acc = false
            {result_acc, slashes_acc} = if (slashes_acc) do
              result_acc = result_acc <> "/"
              slashes_acc = false
              {result_acc, slashes_acc}
            else
              {result_acc, slashes_acc}
            end
            result_acc = result_acc <> (fn ->
  <<code::utf8>>
end).()
            {code, colon_acc, result_acc, slashes_acc}
        end
        {result_acc, colon_acc, slashes_acc}
      end)
      result
    end
  end
  defp without_last_part(parts) do
    result = []
    previous_part = ""
    has_previous_part = false
    _g = 0
    {result, _previous_part, _has_previous_part} = Enum.reduce(parts, {result, previous_part, has_previous_part}, fn part, {result_acc, previous_part_acc, has_previous_part_acc} ->
      result_acc = if (has_previous_part_acc), do: result_acc ++ [previous_part_acc], else: result_acc
      previous_part_acc = part
      has_previous_part_acc = true
      {result_acc, previous_part_acc, has_previous_part_acc}
    end)
    result
  end
  def add_trailing_slash(path) do
    if (String.length(path) == 0) do
      "/"
    else
      slash_index = (case String.split(String.slice(path, 0, String.length(path)), "/") do
        parts when Kernel.length(parts) > 1 ->
          String.length(Enum.join((fn -> Enum.slice(parts, 0..-2//1) end).(), "/"))
        _ -> -1
      end)
      backslash_index = (case String.split(String.slice(path, 0, String.length(path)), "\\") do
        parts when Kernel.length(parts) > 1 ->
          String.length(Enum.join((fn -> Enum.slice(parts, 0..-2//1) end).(), "\\"))
        _ -> -1
      end)
      if (slash_index < backslash_index) do
        if (backslash_index == (String.length(path) - 1)) do
          path
        else
          "#{path}\\"
        end
      else
        if (slash_index == (String.length(path) - 1)) do
          path
        else
          "#{path}/"
        end
      end
    end
  end
  def remove_trailing_slashes(path) do
    trimmed_length = String.length(path)
    trimming = true
    _g = 0
    path_length = String.length(path)
    {trimmed_length, _trimming} = Enum.reduce(0..(path_length - 1)//1, {trimmed_length, trimming}, fn offset, {trimmed_length_acc, trimming_acc} ->
      if (trimming_acc) do
        index = ((String.length(path) - 1) - offset)
        code = if (index < 0) do
          nil
        else
          Enum.at(String.to_charlist(path), index)
        end
        {trimmed_length_acc, trimming_acc} = if (code == 47 or code == 92) do
          trimmed_length_acc = index
          {trimmed_length_acc, trimming_acc}
        else
          trimming_acc = false
          {trimmed_length_acc, trimming_acc}
        end
        {trimmed_length_acc, trimming_acc}
      else
        {trimmed_length_acc, trimming_acc}
      end
    end)
    _ = String.slice(path, 0, trimmed_length)
  end
  def is_absolute(path) do
    if (StringTools.starts_with(path, "/")) do
      true
    else
      cond_value = (String.at(path, 1) || "")
      if (cond_value == ":") do
        true
      else
        StringTools.starts_with(path, "\\\\")
      end
    end
  end
end

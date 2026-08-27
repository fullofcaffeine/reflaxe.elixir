defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  defp clean(root) do
    nested = "#{root}/nested"
    link = "#{root}/nested-link"
    original = "#{nested}/original.txt"
    renamed = "#{nested}/renamed.txt"
    stream = "#{nested}/stream.bin"
    copied = "#{nested}/copied.bin"
    created_by_update = "#{nested}/created-by-update.txt"
    if (FileSystem.exists(link)) do
      FileSystem.delete_file(link)
    end
    if (FileSystem.exists(original)) do
      FileSystem.delete_file(original)
    end
    if (FileSystem.exists(renamed)) do
      FileSystem.delete_file(renamed)
    end
    if (FileSystem.exists(stream)) do
      FileSystem.delete_file(stream)
    end
    if (FileSystem.exists(copied)) do
      FileSystem.delete_file(copied)
    end
    if (FileSystem.exists(created_by_update)) do
      FileSystem.delete_file(created_by_update)
    end
    if (FileSystem.exists(nested)) do
      FileSystem.delete_directory(nested)
    end
    if (FileSystem.exists(root)) do
      FileSystem.delete_directory(root)
    end
  end
  defp assert_non_empty_delete_fails(path) do
    try do
      FileSystem.delete_directory(path)
      raise Reflaxe.Elixir.HaxeThrow, [value: "deleting a non-empty directory must fail"]
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {error, _} ->
            if (Std.is(error, String)) do
              raise Reflaxe.Elixir.HaxeThrow, [value: error]
            end
            assert_that(FileSystem.exists(path), "failed deletion must keep the non-empty directory")
        end)
    end
  end
  defp assert_stat(stat) do
    assert_that(stat.size == 5, "stat size must match the file content")
    integer_fields = [stat.gid, stat.uid, stat.dev, stat.ino, stat.nlink, stat.rdev, stat.mode]
    _g = 0
    Enum.each(integer_fields, fn value -> assert_that(Std.is(value, Int), "every integer FileStat field must be present") end)
    assert_that(stat.nlink >= 1, "stat must report at least one hard link")
    date_fields = [stat.atime, stat.mtime, stat.ctime]
    _g = 0
    Enum.each(date_fields, fn value ->
      assert_that(not Kernel.is_nil(value), "every Date FileStat field must be present")
      assert_that(Reflaxe.Elixir.HaxeFloat.gt(DateTime.to_unix(value, :millisecond), 0), "every FileStat date must be a usable Haxe Date")
    end)
  end
  def main() do
    root = "_tmp/reflaxe_filesystem_snapshot_contract"
    nested = "#{root}/nested"
    link = "#{root}/nested-link"
    original = "#{nested}/original.txt"
    renamed = "#{nested}/renamed.txt"
    stream = "#{nested}/stream.bin"
    copied = "#{nested}/copied.bin"
    created_by_update = "#{nested}/created-by-update.txt"
    clean(root)
    assert_that(not FileSystem.exists(root), "cleanup must remove the contract directory")
    FileSystem.create_directory(nested)
    assert_that(FileSystem.exists(nested), "recursive directory creation must succeed")
    assert_that(FileSystem.is_directory(nested), "the created path must be a directory")
    Sys.IO.File.save_content(original, "hello")
    assert_that(FileSystem.exists(original), "the created file must exist")
    assert_that(not FileSystem.is_directory(original), "a regular file must not be a directory")
    assert_that(Enum.join(FileSystem.read_directory(nested), ",") == "original.txt", "directory listing must contain the file name")
    assert_non_empty_delete_fails(nested)
    FileSystem.rename(original, renamed)
    assert_that(not FileSystem.exists(original), "rename must remove the old path")
    assert_that(FileSystem.exists(renamed), "rename must create the new path")
    assert_stat(FileSystem.stat(renamed))
    output = Sys.IO.File.write(stream, true)
    apply(Map.get(output, :__reflaxe_class__) || Map.get(output, :__struct__), :write_byte, [output, 97])
    assert_that(apply(Map.get(output, :__reflaxe_class__) || Map.get(output, :__struct__), :write_bytes, [output, Bytes.of_string("bcde", {:utf8}), 0, 4]) == 4, "writeBytes must report the written byte count")
    assert_that(apply(Map.get(output, :__reflaxe_class__) || Map.get(output, :__struct__), :tell, [output]) == 5, "tell must report the position after a write")
    apply(Map.get(output, :__reflaxe_class__) || Map.get(output, :__struct__), :seek, [output, 1, {:seek_begin}])
    assert_that(apply(Map.get(output, :__reflaxe_class__) || Map.get(output, :__struct__), :write_bytes, [output, Bytes.of_string("XY", {:utf8}), 0, 2]) == 2, "writeBytes must report the written byte count")
    assert_that(apply(Map.get(output, :__reflaxe_class__) || Map.get(output, :__struct__), :tell, [output]) == 3, "tell must follow an absolute output seek")
    apply(Map.get(output, :__reflaxe_class__) || Map.get(output, :__struct__), :close, [output])
    assert_that(Sys.IO.File.get_content(stream) == "aXYde", "write must support seeking and overwrite existing bytes")
    append = Sys.IO.File.append(stream, true)
    apply(Map.get(append, :__reflaxe_class__) || Map.get(append, :__struct__), :write_string, [append, "fg", nil])
    apply(Map.get(append, :__reflaxe_class__) || Map.get(append, :__struct__), :close, [append])
    assert_that(Sys.IO.File.get_content(stream) == "aXYdefg", "append must preserve existing content")
    update = Sys.IO.File.update(stream, true)
    apply(Map.get(update, :__reflaxe_class__) || Map.get(update, :__struct__), :seek, [update, -2, {:seek_end}])
    apply(Map.get(update, :__reflaxe_class__) || Map.get(update, :__struct__), :write_string, [update, "HI", nil])
    apply(Map.get(update, :__reflaxe_class__) || Map.get(update, :__struct__), :close, [update])
    assert_that(Sys.IO.File.get_content(stream) == "aXYdeHI", "update must overwrite without truncating the file")
    create_handle = Sys.IO.File.update(created_by_update, true)
    apply(Map.get(create_handle, :__reflaxe_class__) || Map.get(create_handle, :__struct__), :close, [create_handle])
    assert_that(FileSystem.exists(created_by_update), "update must create a missing file")
    input = Sys.IO.File.read(stream, true)
    assert_that(apply(Map.get(input, :__reflaxe_class__) || Map.get(input, :__struct__), :tell, [input]) == 0, "a new input must start at position zero")
    assert_that(not apply(Map.get(input, :__reflaxe_class__) || Map.get(input, :__struct__), :eof, [input]), "eof must be false before reading data")
    assert_that(apply(Map.get(input, :__reflaxe_class__) || Map.get(input, :__struct__), :tell, [input]) == 0, "eof must not consume input")
    assert_that(apply(Map.get(input, :__reflaxe_class__) || Map.get(input, :__struct__), :read_byte, [input]) == 97, "readByte must return the next byte")
    caller_buffer = Bytes.alloc(6)
    apply(Map.get(caller_buffer, :__reflaxe_class__) || Map.get(caller_buffer, :__struct__), :fill, [caller_buffer, 0, caller_buffer.length, 95])
    assert_that(apply(Map.get(input, :__reflaxe_class__) || Map.get(input, :__struct__), :read_bytes, [input, caller_buffer, 2, 3]) == 3, "readBytes must report the bytes copied into the caller buffer")
    assert_that(apply(Map.get(caller_buffer, :__reflaxe_class__) || Map.get(caller_buffer, :__struct__), :to_string, [caller_buffer]) == "__XYd_", "readBytes must mutate only the requested caller-buffer range")
    assert_that(apply(Map.get(input, :__reflaxe_class__) || Map.get(input, :__struct__), :tell, [input]) == 4, "tell must follow caller-buffer reads")
    apply(Map.get(input, :__reflaxe_class__) || Map.get(input, :__struct__), :seek, [input, -2, {:seek_end}])
    assert_that((fn ->
      reflaxe_dispatch_receiver = apply(Map.get(input, :__reflaxe_class__) || Map.get(input, :__struct__), :read, [input, 2])
      apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_string, [reflaxe_dispatch_receiver])
    end).() == "HI", "input seek must support positions relative to the end")
    assert_that(apply(Map.get(input, :__reflaxe_class__) || Map.get(input, :__struct__), :eof, [input]), "eof must be true after the last byte")
    apply(Map.get(input, :__reflaxe_class__) || Map.get(input, :__struct__), :close, [input])
    binary = Bytes.alloc(4)
    apply(Map.get(binary, :__reflaxe_class__) || Map.get(binary, :__struct__), :set, [binary, 0, 0])
    apply(Map.get(binary, :__reflaxe_class__) || Map.get(binary, :__struct__), :set, [binary, 1, 1])
    apply(Map.get(binary, :__reflaxe_class__) || Map.get(binary, :__struct__), :set, [binary, 2, 127])
    apply(Map.get(binary, :__reflaxe_class__) || Map.get(binary, :__struct__), :set, [binary, 3, 255])
    Sys.IO.File.save_bytes(copied, binary)
    assert_that((fn ->
      reflaxe_dispatch_receiver = Sys.IO.File.get_bytes(copied)
      apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :compare, [reflaxe_dispatch_receiver, binary])
    end).() == 0, "saveBytes and getBytes must preserve all byte values")
    Sys.IO.File.copy(copied, original)
    assert_that((fn ->
      reflaxe_dispatch_receiver = Sys.IO.File.get_bytes(original)
      apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :compare, [reflaxe_dispatch_receiver, binary])
    end).() == 0, "copy must preserve binary content")
    File.ln_s!("nested", link)
    assert_that(FileSystem.is_directory(link), "isDirectory must follow a directory symlink")
    assert_that(FileSystem.full_path("#{link}/renamed.txt") == FileSystem.full_path(renamed), "fullPath must resolve an intermediate relative symlink")
    absolute = FileSystem.absolute_path(root)
    resolved = FileSystem.full_path(root)
    assert_that(Haxe.IO.Path.is_absolute(absolute), "absolutePath must return an absolute path")
    assert_that(Haxe.IO.Path.is_absolute(resolved), "fullPath must return an absolute path")
    assert_that(StringTools.ends_with(absolute, root), "absolutePath must preserve the relative suffix")
    assert_that(StringTools.ends_with(resolved, root), "fullPath must preserve the resolved suffix")
    FileSystem.delete_file(link)
    FileSystem.delete_file(original)
    FileSystem.delete_file(renamed)
    FileSystem.delete_file(stream)
    FileSystem.delete_file(copied)
    FileSystem.delete_file(created_by_update)
    FileSystem.delete_directory(nested)
    FileSystem.delete_directory(root)
    assert_that(not FileSystem.exists(root), "explicit deletion must remove every owned path")
  end
end

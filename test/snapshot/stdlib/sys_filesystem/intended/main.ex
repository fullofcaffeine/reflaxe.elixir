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
    if (FileSystem.exists(link)) do
      FileSystem.delete_file(link)
    end
    if (FileSystem.exists(original)) do
      FileSystem.delete_file(original)
    end
    if (FileSystem.exists(renamed)) do
      FileSystem.delete_file(renamed)
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
    FileSystem.delete_file(renamed)
    FileSystem.delete_directory(nested)
    FileSystem.delete_directory(root)
    assert_that(not FileSystem.exists(root), "explicit deletion must remove every owned path")
  end
end

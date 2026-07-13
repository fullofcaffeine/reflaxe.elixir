defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  def main() do
    parsed = Haxe.IO.Path.new("/tmp/archive.tar.gz")
    assert_that(parsed.dir == "/tmp", "directory parse failed")
    assert_that(parsed.file == "archive.tar", "file parse failed")
    assert_that(parsed.ext == "gz", "extension parse failed")
    assert_that(apply(Map.get(parsed, :__reflaxe_class__) || Map.get(parsed, :__struct__), :to_string, [parsed]) == "/tmp/archive.tar.gz", "toString failed")
    assert_that(Haxe.IO.Path.without_extension("/tmp/file.txt") == "/tmp/file", "withoutExtension failed")
    assert_that(Haxe.IO.Path.without_directory("/tmp/file.txt") == "file.txt", "withoutDirectory failed")
    assert_that(Haxe.IO.Path.directory("/tmp/file.txt") == "/tmp", "directory helper failed")
    assert_that(Haxe.IO.Path.extension("/tmp/file.txt") == "txt", "extension helper failed")
    assert_that(Haxe.IO.Path.with_extension("/tmp/file", "log") == "/tmp/file.log", "withExtension failed")
    assert_that(Haxe.IO.Path.join(["/usr", "local", "../bin"]) == "/usr/bin", "join normalize failed")
    assert_that(Haxe.IO.Path.normalize("/usr//local/../bin/./tool") == "/usr/bin/tool", "normalize failed")
    assert_that(Haxe.IO.Path.normalize("http://haxe.org/downloads") == "http://haxe.org/downloads", "URL normalize failed")
    assert_that(Haxe.IO.Path.add_trailing_slash("foo\\bar") == "foo\\bar\\", "addTrailingSlash backslash failed")
    assert_that(Haxe.IO.Path.remove_trailing_slashes("foo///") == "foo", "removeTrailingSlashes failed")
    assert_that(Haxe.IO.Path.is_absolute("/tmp"), "unix absolute failed")
    assert_that(Haxe.IO.Path.is_absolute("C:/tmp"), "drive absolute failed")
    assert_that(Haxe.IO.Path.is_absolute("\\\\server\\share"), "unc absolute failed")
    assert_that(not Haxe.IO.Path.is_absolute("relative/path"), "relative path failed")
  end
end

defmodule FileSystem do
  def exists(path) do
    File.exists?(path)
  end
  def rename(path, new_path) do
    File.rename!(path, new_path)
  end
  def stat(path) do
    stat_struct = File.stat!(path)
    %{gid: Map.fetch!(stat_struct, :gid), uid: Map.fetch!(stat_struct, :uid), atime: to_utc_date(Map.fetch!(stat_struct, :atime)), mtime: to_utc_date(Map.fetch!(stat_struct, :mtime)), ctime: to_utc_date(Map.fetch!(stat_struct, :ctime)), size: Map.fetch!(stat_struct, :size), dev: Map.fetch!(stat_struct, :dev), ino: Map.fetch!(stat_struct, :ino), nlink: Map.fetch!(stat_struct, :nlink), rdev: Map.fetch!(stat_struct, :rdev), mode: Map.fetch!(stat_struct, :mode)}
  end
  def full_path(rel_path) do
    File.realpath!(rel_path)
  end
  def absolute_path(rel_path) do
    Path.expand(rel_path)
  end
  def is_directory(path) do
    stat_struct = File.stat!(path)
    Map.fetch!(stat_struct, :type) == :directory
  end
  def create_directory(path) do
    File.mkdir_p!(path)
  end
  def delete_file(path) do
    File.rm!(path)
  end
  def delete_directory(path) do
    File.rmdir!(path)
  end
  def read_directory(path) do
    File.ls!(path)
  end
  defp to_utc_date(erl_datetime) do
    naive = NaiveDateTime.from_erl!(erl_datetime, nil)
    _ = DateTime.from_naive!(naive, "Etc/UTC")
  end
end

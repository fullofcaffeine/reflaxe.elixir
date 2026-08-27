defmodule FileSystem do
  def exists(path) do
    File.exists?(path)
  end
  def rename(path, new_path) do
    File.rename!(path, new_path)
  end
  def stat(path) do
    stat_struct = File.stat!(path)
    %{gid: Map.fetch!(stat_struct, :gid), uid: Map.fetch!(stat_struct, :uid), atime: to_utc_date(Map.fetch!(stat_struct, :atime)), mtime: to_utc_date(Map.fetch!(stat_struct, :mtime)), ctime: to_utc_date(Map.fetch!(stat_struct, :ctime)), size: Map.fetch!(stat_struct, :size), dev: Map.fetch!(stat_struct, :major_device), ino: Map.fetch!(stat_struct, :inode), nlink: Map.fetch!(stat_struct, :links), rdev: Map.fetch!(stat_struct, :minor_device), mode: Map.fetch!(stat_struct, :mode)}
  end
  def full_path(rel_path) do
    resolve_existing_path(Path.expand(rel_path), 0)
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
    naive = NaiveDateTime.from_erl!(erl_datetime)
    DateTime.from_naive!(naive, "Etc/UTC")
  end
  defp resolve_existing_path(absolute_path, followed_links) do
    if (followed_links >= 40) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:custom, "Too many symbolic links while resolving " <> absolute_path}]
    end
    components = Path.split(absolute_path)
    resolve_component(components, 1, Enum.at(components, 0), followed_links)
  end
  defp resolve_component(components, index, current, followed_links) do
    if (index >= length(components)) do
      current
    else
      next = Path.join(current, Enum.at(components, index))
      stat_struct = File.lstat!(next)
      is_symlink = Map.fetch!(stat_struct, :type) == :symlink
      if (not is_symlink) do
        resolve_component(components, index + 1, next, followed_links)
      else
        target = File.read_link!(next)
        resolved = Path.expand(target, Path.dirname(next))
        append_remaining_components(components, index + 1, resolved, followed_links + 1)
      end
    end
  end
  defp append_remaining_components(components, index, resolved, followed_links) do
    if (index >= length(components)) do
      resolve_existing_path(resolved, followed_links)
    else
      append_remaining_components(components, index + 1, Path.join(resolved, Enum.at(components, index)), followed_links)
    end
  end
end

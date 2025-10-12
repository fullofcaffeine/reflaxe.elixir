defmodule Phoenix.ConnState do
  def unset() do
    {0}
  end
  def set() do
    {1}
  end
  def sent() do
    {2}
  end
  def chunked() do
    {3}
  end
  def file_chunked() do
    {4}
  end
end

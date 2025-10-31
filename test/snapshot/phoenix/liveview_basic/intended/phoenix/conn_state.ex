defmodule Phoenix.ConnState do
  def unset() do
    {:unset}
  end
  def set() do
    {:set}
  end
  def sent() do
    {:sent}
  end
  def chunked() do
    {:chunked}
  end
  def file_chunked() do
    {:file_chunked}
  end
end

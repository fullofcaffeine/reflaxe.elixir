defmodule ConnState do
  def unset() do
    {:Unset}
  end
  def set() do
    {:Set}
  end
  def sent() do
    {:Sent}
  end
  def chunked() do
    {:Chunked}
  end
  def file_chunked() do
    {:FileChunked}
  end
end
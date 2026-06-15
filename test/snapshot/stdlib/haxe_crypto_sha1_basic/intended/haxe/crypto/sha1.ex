defmodule Haxe.Crypto.Sha1 do
  def encode(s) do
    Base.encode16(:crypto.hash(:sha, s), case: :lower)
  end
  def make(b) do
    digest = :crypto.hash(:sha, apply(Map.get(b, :__reflaxe_class__) || Map.get(b, :__struct__), :get_data, [b]))
    _ = Bytes.of_data(digest)
  end
end

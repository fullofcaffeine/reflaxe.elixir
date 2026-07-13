defmodule Haxe.Crypto.Sha256 do
  def encode(s) do
    Base.encode16(:crypto.hash(:sha256, s), case: :lower)
  end
  def make(b) do
    digest = :crypto.hash(:sha256, apply(Map.get(b, :__reflaxe_class__) || Map.get(b, :__struct__), :get_data, [b]))
    Bytes.of_data(digest)
  end
end

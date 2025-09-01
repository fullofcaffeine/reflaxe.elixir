defmodule User do
  def main() do
    Log.trace("Testing complex metadata syntax", %{:fileName => "MetadataTest.hx", :lineNumber => 14, :className => "User", :methodName => "main"})
  end
end
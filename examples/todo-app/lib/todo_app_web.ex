defmodule TodoAppWeb do
  def static_paths() do
    fn -> ["assets", "fonts", "images", "favicon.ico", "robots.txt"] end
  end
end
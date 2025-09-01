defmodule User do
  def new(name, age) do
    %{:name => name, :age => age}
  end
end
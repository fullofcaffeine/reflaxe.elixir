defmodule User do
  def new(name_param, age_param) do
    struct = %{:name => nil, :age => nil}
    struct = %{struct | name: name_param}
    struct = %{struct | age: age_param}
    struct
  end
end

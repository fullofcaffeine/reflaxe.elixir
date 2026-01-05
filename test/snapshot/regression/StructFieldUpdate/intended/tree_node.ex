defmodule TreeNode do
  def new(key_param, value_param, left_param, right_param) do
    struct = %{:key => nil, :value => nil, :left => nil, :right => nil}
    struct = %{struct | key: key_param}
    struct = %{struct | value: value_param}
    struct = %{struct | left: left_param}
    struct = %{struct | right: right_param}
    struct
  end
end

defmodule TodoWorker do
  def new(initial_state) do
    struct = %{:state => nil}
    struct = %{struct | state: initial_state}
    struct
  end
  def handle_call(_, _, _, state_param) do
    state_param
  end
end

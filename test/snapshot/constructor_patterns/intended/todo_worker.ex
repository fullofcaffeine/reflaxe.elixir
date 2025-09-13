defmodule TodoWorker do
  @state nil
  def handle_call(struct, _msg, _from, state) do
    state
  end
end
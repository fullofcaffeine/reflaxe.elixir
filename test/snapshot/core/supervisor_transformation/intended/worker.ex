defmodule Worker do
  def start_link(_args) do
    {:ok, self()}
  end
  def child_spec(args) do
    %{
          id: Worker,
          start: {Worker, :start_link, [args]},
          restart: :permanent,
          type: :worker
        }
  end
end

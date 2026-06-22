defmodule DatabaseConnection do
  def start_link(_config) do
    {:ok, self()}
  end
  def child_spec(config) do
    %{
          id: DatabaseConnection,
          start: {DatabaseConnection, :start_link, [config]},
          restart: :permanent,
          shutdown: 5000,
          type: :worker
        }
  end
end

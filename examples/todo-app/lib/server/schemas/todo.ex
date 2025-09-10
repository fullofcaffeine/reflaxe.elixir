defmodule Todo do
  use Ecto.Schema
  import Ecto.Changeset
  schema "todos" do
    field(:title, :string)
    field(:description, :string)
    field(:completed, :boolean)
    field(:priority, :string)
    field(:due_date, :string)
    field(:tags, {:array, :string})
    field(:user_id, :integer)
    timestamps()
  end
  def changeset(todo, params) do
    this1 = nil
    this1 = Ecto.Changeset.change(todo, params)
    cs = this1
    atoms = Enum.join(Enum.map(["title", "userId"], fn f -> ":" <> f end), ", ")
    this1 = Ecto.Changeset.validate_required(cs, [__elixir__.call(atoms)])
    opts = %{:min => 3, :max => 200}
    elixir_opts = []
    elixir_opts = elixir_opts ++ ["min: " <> Kernel.to_string(opts.min)]
    elixir_opts = elixir_opts ++ ["max: " <> Kernel.to_string(opts.max)]
    elixir_opts = elixir_opts ++ ["is: " <> Kernel.to_string(opts.is)]
    opts_str = Enum.join(elixir_opts, ", ")
    this1 = this1
if Map.get(opts, :min) != nil, do: elixir_opts
if Map.get(opts, :max) != nil, do: elixir_opts
if Map.get(opts, :is) != nil, do: elixir_opts
Ecto.Changeset.validate_length(this1, :"title", [__elixir__.call(opts_str)])
    opts = %{:max => 1000}
    elixir_opts = []
    if (Map.get(opts, :min) != nil) do
      elixir_opts = elixir_opts ++ ["min: " <> Kernel.to_string(opts.min)]
    end
    if (Map.get(opts, :max) != nil) do
      elixir_opts = elixir_opts ++ ["max: " <> Kernel.to_string(opts.max)]
    end
    if (Map.get(opts, :is) != nil) do
      elixir_opts = elixir_opts ++ ["is: " <> Kernel.to_string(opts.is)]
    end
    opts_str = Enum.join(elixir_opts, ", ")
    Ecto.Changeset.validate_length(this1, :"description", [__elixir__.call(opts_str)])
  end
  def toggle_completed(todo) do
    changeset(todo, (%{:completed => not todo.completed}))
  end
  def update_priority(todo, priority) do
    changeset(todo, (%{:priority => priority}))
  end
  def add_tag(todo, tag) do
    tags = if (todo.tags != nil) do
  todo.tags
else
  []
end
    tags = tags ++ [tag]
    params = %{:tags => tags}
    changeset(todo, params)
  end
end
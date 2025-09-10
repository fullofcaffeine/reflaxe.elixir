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
  def changeset(_todo, _params) do
    this1 = nil
    this1 = Ecto.Changeset.change(todo, params)
    cs = this1
    this1 = Ecto.Changeset.validate_required(cs, Enum.map(["title", "userId"], &String.to_atom/1))
    opts = %{:min => 3, :max => 200}
    this1 = if Map.get(opts, :min) != nil && Map.get(opts, :max) != nil && Map.get(opts, :is) != nil do
  Ecto.Changeset.validate_length(this1, :"title", [min: opts.min, max: opts.max, is: opts.is])
else
  if Map.get(opts, :min) != nil && Map.get(opts, :max) != nil do
    Ecto.Changeset.validate_length(this1, :"title", [min: opts.min, max: opts.max])
  else
    if Map.get(opts, :min) != nil && Map.get(opts, :is) != nil do
      Ecto.Changeset.validate_length(this1, :"title", [min: opts.min, is: opts.is])
    else
      if Map.get(opts, :max) != nil && Map.get(opts, :is) != nil do
        Ecto.Changeset.validate_length(this1, :"title", [max: opts.max, is: opts.is])
      else
        if Map.get(opts, :min) != nil do
          Ecto.Changeset.validate_length(this1, :"title", [min: opts.min])
        else
          if Map.get(opts, :max) != nil do
            Ecto.Changeset.validate_length(this1, :"title", [max: opts.max])
          else
            if Map.get(opts, :is) != nil do
              Ecto.Changeset.validate_length(this1, :"title", [is: opts.is])
            else
              Ecto.Changeset.validate_length(this1, :"title", [])
            end
          end
        end
      end
    end
  end
end
    opts = %{:max => 1000}
    if (Map.get(opts, :min) != nil && Map.get(opts, :max) != nil && Map.get(opts, :is) != nil) do
      Ecto.Changeset.validate_length(this1, :"description", [min: opts.min, max: opts.max, is: opts.is])
    else
      if (Map.get(opts, :min) != nil && Map.get(opts, :max) != nil) do
        Ecto.Changeset.validate_length(this1, :"description", [min: opts.min, max: opts.max])
      else
        if (Map.get(opts, :min) != nil && Map.get(opts, :is) != nil) do
          Ecto.Changeset.validate_length(this1, :"description", [min: opts.min, is: opts.is])
        else
          if (Map.get(opts, :max) != nil && Map.get(opts, :is) != nil) do
            Ecto.Changeset.validate_length(this1, :"description", [max: opts.max, is: opts.is])
          else
            if (Map.get(opts, :min) != nil) do
              Ecto.Changeset.validate_length(this1, :"description", [min: opts.min])
            else
              if (Map.get(opts, :max) != nil) do
                Ecto.Changeset.validate_length(this1, :"description", [max: opts.max])
              else
                if (Map.get(opts, :is) != nil) do
                  Ecto.Changeset.validate_length(this1, :"description", [is: opts.is])
                else
                  Ecto.Changeset.validate_length(this1, :"description", [])
                end
              end
            end
          end
        end
      end
    end
  end
  def toggle_completed(todo) do
    changeset(todo, (%{:completed => not todo.completed}))
  end
  def update_priority(todo, _priority) do
    changeset(todo, (%{:priority => priority}))
  end
  def add_tag(todo, _tag) do
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
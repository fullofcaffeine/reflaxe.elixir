defmodule TodoApp.Todo do
  def changeset(todo, params) do
    temp_changeset = nil
    this1 = Ecto.Changeset.change(todo, params)
    temp_changeset = this1
    cs = tempChangeset
    temp_result = nil
    temp_changeset1 = nil
    this1 = Ecto.Changeset.validate_required(cs, Enum.map(["title", "userId"], &String.to_atom/1))
    opts = %{:min => 3, :max => 200}
    if (Map.get(opts, :min) != nil && Map.get(opts, :max) != nil && Map.get(opts, :is) != nil) do
      temp_changeset1 = Ecto.Changeset.validate_length(this1, :"title", [min: opts.min, max: opts.max, is: opts.is])
    else
      if (Map.get(opts, :min) != nil && Map.get(opts, :max) != nil) do
        temp_changeset1 = Ecto.Changeset.validate_length(this1, :"title", [min: opts.min, max: opts.max])
      else
        if (Map.get(opts, :min) != nil && Map.get(opts, :is) != nil) do
          temp_changeset1 = Ecto.Changeset.validate_length(this1, :"title", [min: opts.min, is: opts.is])
        else
          if (Map.get(opts, :max) != nil && Map.get(opts, :is) != nil) do
            temp_changeset1 = Ecto.Changeset.validate_length(this1, :"title", [max: opts.max, is: opts.is])
          else
            if (Map.get(opts, :min) != nil) do
              temp_changeset1 = Ecto.Changeset.validate_length(this1, :"title", [min: opts.min])
            else
              if (Map.get(opts, :max) != nil) do
                temp_changeset1 = Ecto.Changeset.validate_length(this1, :"title", [max: opts.max])
              else
                if (Map.get(opts, :is) != nil) do
                  temp_changeset1 = Ecto.Changeset.validate_length(this1, :"title", [is: opts.is])
                else
                  temp_changeset1 = Ecto.Changeset.validate_length(this1, :"title", [])
                end
              end
            end
          end
        end
      end
    end
    this1 = tempChangeset1
    opts = %{:max => 1000}
    if (Map.get(opts, :min) != nil && Map.get(opts, :max) != nil && Map.get(opts, :is) != nil) do
      temp_result = Ecto.Changeset.validate_length(this1, :"description", [min: opts.min, max: opts.max, is: opts.is])
    else
      if (Map.get(opts, :min) != nil && Map.get(opts, :max) != nil) do
        temp_result = Ecto.Changeset.validate_length(this1, :"description", [min: opts.min, max: opts.max])
      else
        if (Map.get(opts, :min) != nil && Map.get(opts, :is) != nil) do
          temp_result = Ecto.Changeset.validate_length(this1, :"description", [min: opts.min, is: opts.is])
        else
          if (Map.get(opts, :max) != nil && Map.get(opts, :is) != nil) do
            temp_result = Ecto.Changeset.validate_length(this1, :"description", [max: opts.max, is: opts.is])
          else
            if (Map.get(opts, :min) != nil) do
              temp_result = Ecto.Changeset.validate_length(this1, :"description", [min: opts.min])
            else
              if (Map.get(opts, :max) != nil) do
                temp_result = Ecto.Changeset.validate_length(this1, :"description", [max: opts.max])
              else
                if (Map.get(opts, :is) != nil) do
                  temp_result = Ecto.Changeset.validate_length(this1, :"description", [is: opts.is])
                else
                  temp_result = Ecto.Changeset.validate_length(this1, :"description", [])
                end
              end
            end
          end
        end
      end
    end
    tempResult
  end
  def toggle_completed(todo) do
    params = %{:completed => not todo.completed}
    TodoApp.Todo.changeset(todo, params)
  end
  def update_priority(todo, priority) do
    params = %{:priority => priority2}
    TodoApp.Todo.changeset(todo, params)
  end
  def add_tag(todo, tag) do
    temp_array = nil
    if (todo.tags != nil) do
      temp_array = todo.tags
    else
      temp_array = []
    end
    tempArray = tempArray ++ [tag]
    params = %{:tags => tempArray}
    TodoApp.Todo.changeset(todo, params)
  end
end
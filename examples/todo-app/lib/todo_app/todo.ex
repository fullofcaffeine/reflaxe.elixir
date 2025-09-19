defmodule TodoApp.Todo do
  def changeset(todo, params) do
    temp_changeset = nil
    this1 = Ecto.Changeset.change(todo, params)
    temp_changeset = this1
    cs = temp_changeset
    temp_result = nil
    temp_changeset1 = nil
    this1 = Ecto.Changeset.validate_required(cs, Enum.map(["title", "userId"], &String.to_atom/1))
    opts = %{:min => 3, :max => 200}
    if (opts.min != nil and opts.max != nil and opts.is != nil) do
      temp_changeset1 = Ecto.Changeset.validate_length(this1, :"title", [min: opts.min, max: opts.max, is: opts.is])
    else
      if (opts.min != nil and opts.max != nil) do
        temp_changeset1 = Ecto.Changeset.validate_length(this1, :"title", [min: opts.min, max: opts.max])
      else
        if (opts.min != nil and opts.is != nil) do
          temp_changeset1 = Ecto.Changeset.validate_length(this1, :"title", [min: opts.min, is: opts.is])
        else
          if (opts.max != nil and opts.is != nil) do
            temp_changeset1 = Ecto.Changeset.validate_length(this1, :"title", [max: opts.max, is: opts.is])
          else
            if (opts.min != nil) do
              temp_changeset1 = Ecto.Changeset.validate_length(this1, :"title", [min: opts.min])
            else
              if (opts.max != nil) do
                temp_changeset1 = Ecto.Changeset.validate_length(this1, :"title", [max: opts.max])
              else
                if (opts.is != nil) do
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
    this1 = temp_changeset1
    opts = %{:max => 1000}
    if (opts.min != nil and opts.max != nil and opts.is != nil) do
      temp_result = Ecto.Changeset.validate_length(this1, :"description", [min: opts.min, max: opts.max, is: opts.is])
    else
      if (opts.min != nil and opts.max != nil) do
        temp_result = Ecto.Changeset.validate_length(this1, :"description", [min: opts.min, max: opts.max])
      else
        if (opts.min != nil and opts.is != nil) do
          temp_result = Ecto.Changeset.validate_length(this1, :"description", [min: opts.min, is: opts.is])
        else
          if (opts.max != nil and opts.is != nil) do
            temp_result = Ecto.Changeset.validate_length(this1, :"description", [max: opts.max, is: opts.is])
          else
            if (opts.min != nil) do
              temp_result = Ecto.Changeset.validate_length(this1, :"description", [min: opts.min])
            else
              if (opts.max != nil) do
                temp_result = Ecto.Changeset.validate_length(this1, :"description", [max: opts.max])
              else
                if (opts.is != nil) do
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
    temp_result
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
    temp_array = temp_array ++ [tag]
    params = %{:tags => temp_array}
    TodoApp.Todo.changeset(todo, params)
  end
end
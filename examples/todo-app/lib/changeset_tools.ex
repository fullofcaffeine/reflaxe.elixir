defmodule ChangesetTools do
  def is_valid(changeset) do
    changeset.valid && changeset.errors.length == 0
  end
  def is_invalid(changeset) do
    not changeset.valid || changeset.errors.length > 0
  end
  def get_field_errors(changeset, field) do
    Enum.map(Enum.filter(changeset.errors, fn error -> error.field == field end), fn error -> error.message end)
  end
  def has_field_error(changeset, field) do
    Lambda.exists(changeset.errors, fn error -> error.field == field end)
  end
  def get_first_field_error(changeset, field) do
    errors = get_field_errors(changeset, field)
    if (errors.length > 0), do: {:Some, errors[0]}, else: :none
  end
  def get_errors_map(changeset) do
    error_map = %{}
    g = 0
    g1 = changeset.errors
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, :ok}, fn _, {acc_g, acc_state} ->
  g = acc_g
  if (g < g1.length) do
    error = g1[g]
    g = g + 1
    key = error.field
    if (not Map.has_key?(error_map, key)) do
      key = error.field
      Map.put(error_map, key, [])
    end
    key = error.field
    Map.get(error_map, key).push(error.message)
    {:cont, {g, acc_state}}
  else
    {:halt, {g, acc_state}}
  end
end)
    error_map
  end
  def to_option(result) do
    case (result.elem(0)) do
      0 ->
        g = result.elem(1)
        value = g
        {:Some, value}
      1 ->
        _g = result.elem(1)
        :none
    end
  end
  def unwrap(result) do
    case (result.elem(0)) do
      0 ->
        g = result.elem(1)
        value = g
        value
      1 ->
        g = result.elem(1)
        changeset = g
        errors = get_errors_map(changeset)
        throw("Changeset has errors: " <> (if (errors == nil), do: "null", else: errors.toString()))
    end
  end
  def unwrap_or(result, default_value) do
    case (result.elem(0)) do
      0 ->
        g = result.elem(1)
        value = g
        value
      1 ->
        _g = result.elem(1)
        default_value
    end
  end
end
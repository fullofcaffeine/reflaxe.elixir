defmodule ChangesetTools do
  def is_valid(changeset) do
    changeset.valid && length(changeset.errors) == 0
  end
  def is_invalid(changeset) do
    not changeset.valid || length(changeset.errors) > 0
  end
  def get_field_errors(changeset, _field) do
    Enum.map(Enum.filter(changeset.errors, fn error -> error.field == _field end), fn error -> error.message end)
  end
  def has_field_error(changeset, _field) do
    Lambda.exists(changeset.errors, fn error -> error.field == _field end)
  end
  def get_first_field_error(changeset, field) do
    errors = get_field_errors(changeset, field)
    if (length(errors) > 0) do
      errors[0]
    else
      :none
    end
  end
  def get_errors_map(changeset) do
    error_map = %{}
    g = 0
    g1 = changeset.errors
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, g1, :ok}, fn _, {acc_g, acc_g1, acc_state} ->
  if (acc_g < length(acc_g1)) do
    error = g1[g]
    acc_g = acc_g + 1
    key = error.field
    if (not Map.has_key?(error_map, key)) do
      key = error.field
      Map.put(error_map, key, [])
    end
    key = error.field
    Map.get(error_map, key).push(error.message)
    {:cont, {acc_g, acc_g1, acc_state}}
  else
    {:halt, {acc_g, acc_g1, acc_state}}
  end
end)
    error_map
  end
  def to_option(_result) do
    case (elem(_result, 0)) do
      0 ->
        g = elem(_result, 1)
        value = g
        value
      1 ->
        _g = elem(_result, 1)
        :none
    end
  end
  def unwrap(_result) do
    case (elem(_result, 0)) do
      0 ->
        g = elem(_result, 1)
        value = g
        value
      1 ->
        g = elem(_result, 1)
        changeset = g
        errors = get_errors_map(changeset)
        throw("Changeset has errors: " <> (if (errors == nil), do: "null", else: errors.to_string()))
    end
  end
  def unwrap_or(_result, default_value) do
    case (elem(_result, 0)) do
      0 ->
        g = elem(_result, 1)
        value = g
        value
      1 ->
        _g = elem(_result, 1)
        default_value
    end
  end
end
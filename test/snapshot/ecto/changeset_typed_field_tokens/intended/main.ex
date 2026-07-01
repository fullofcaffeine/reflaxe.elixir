defmodule Main do
  def main() do

  end
  def typed_tokens(user, params) do
    this1 =
          (fn data, params ->
             # Convert incoming keys to snake_case atoms
             snake_params = for {k, v} <- Map.to_list(params), into: %{} do
               key =
                 cond do
                   is_atom(k) -> k
                   true -> String.to_atom(Macro.underscore(to_string(k)))
                 end
               {key, v}
             end
             # Normalize values based on schema types when possible
             normalized_params = for {k, v} <- Map.to_list(snake_params), into: %{} do
               type = data.__struct__.__schema__(:type, k)
               v2 = case {type, v} do
                 # Comma-separated string -> {:array, :string}
                 {{:array, :string}, bin} when is_binary(bin) ->
                   bin
                   |> String.split(",", trim: true)
                   |> Enum.map(&String.trim/1)
                 # String -> integer (when field is :integer)
                 {:integer, bin} when is_binary(bin) ->
                   case Integer.parse(bin) do
                     {int, _} -> int
                     :error -> bin
                   end
                 # String -> boolean ("true"/"false")
                 {:boolean, bin} when is_binary(bin) ->
                   case String.downcase(String.trim(bin)) do
                     "true" -> true
                     "false" -> false
                     _ -> bin
                   end
                 # String -> NaiveDateTime
                 {:naive_datetime, bin} when is_binary(bin) ->
                   case NaiveDateTime.from_iso8601(bin) do
                     {:ok, ndt} -> ndt
                     {:error, _} ->
                       case Date.from_iso8601(bin) do
                         {:ok, d} ->
                           case NaiveDateTime.new(d, ~T[00:00:00]) do
                             {:ok, ndt2} -> ndt2
                             _ -> bin
                           end
                         _ -> bin
                       end
                   end
                 # Empty string -> nil for nullable fields (let validations handle required)
                 {_, bin} when is_binary(bin) and bin == "" -> nil
                 _ -> v
               end
               {k, v2}
             end
             Ecto.Changeset.cast(data, normalized_params, Map.keys(normalized_params))
           end).(user, params)

    this1 = _ = Ecto.Changeset.cast(this1, Map.get(this1, :params, %{}) || %{}, [:name, :email, :age, :role])
    this1 = Ecto.Changeset.validate_required(this1, [:name, :email])
    this1 = Ecto.Changeset.validate_length(this1, :name, Enum.filter([min: Map.get(%{min: 2, max: 80}, :min), max: Map.get(%{min: 2, max: 80}, :max), is: Map.get(%{min: 2, max: 80}, :is)], fn {_, v} -> v != nil end))
    field = :email
    pattern = EReg.new("@", "")
    message = nil
    this1 = if (not Kernel.is_nil(message)) do
      Ecto.Changeset.validate_format(this1, field, pattern, message: message)
    else
      Ecto.Changeset.validate_format(this1, field, pattern)
    end
    this1 = _ = Ecto.Changeset.validate_number(this1, :age,
          (fn opts ->
             greater_than_or_equal_to =
               case Map.fetch(opts, :greater_than_or_equal_to) do
                 {:ok, value} -> value
                 :error -> Map.get(opts, :min)
               end

             less_than_or_equal_to =
               case Map.fetch(opts, :less_than_or_equal_to) do
                 {:ok, value} -> value
                 :error -> Map.get(opts, :max)
               end

             [
               greater_than: Map.get(opts, :greater_than),
               greater_than_or_equal_to: greater_than_or_equal_to,
               less_than: Map.get(opts, :less_than),
               less_than_or_equal_to: less_than_or_equal_to,
               equal_to: Map.get(opts, :equal_to),
               not_equal_to: Map.get(opts, :not_equal_to)
             ]
             |> Enum.filter(fn {_, value} -> value != nil end)
           end).(%{min: 18, max: 120})
)
    cs = Ecto.Changeset.validate_inclusion(this1, :role, ["admin", "user"])
    cs = Ecto.Changeset.validate_exclusion(cs, :role, ["blocked"])
    cs
  end
  def literal_compatibility(user, params) do
    this1 =
          (fn data, params ->
             # Convert incoming keys to snake_case atoms
             snake_params = for {k, v} <- Map.to_list(params), into: %{} do
               key =
                 cond do
                   is_atom(k) -> k
                   true -> String.to_atom(Macro.underscore(to_string(k)))
                 end
               {key, v}
             end
             # Normalize values based on schema types when possible
             normalized_params = for {k, v} <- Map.to_list(snake_params), into: %{} do
               type = data.__struct__.__schema__(:type, k)
               v2 = case {type, v} do
                 # Comma-separated string -> {:array, :string}
                 {{:array, :string}, bin} when is_binary(bin) ->
                   bin
                   |> String.split(",", trim: true)
                   |> Enum.map(&String.trim/1)
                 # String -> integer (when field is :integer)
                 {:integer, bin} when is_binary(bin) ->
                   case Integer.parse(bin) do
                     {int, _} -> int
                     :error -> bin
                   end
                 # String -> boolean ("true"/"false")
                 {:boolean, bin} when is_binary(bin) ->
                   case String.downcase(String.trim(bin)) do
                     "true" -> true
                     "false" -> false
                     _ -> bin
                   end
                 # String -> NaiveDateTime
                 {:naive_datetime, bin} when is_binary(bin) ->
                   case NaiveDateTime.from_iso8601(bin) do
                     {:ok, ndt} -> ndt
                     {:error, _} ->
                       case Date.from_iso8601(bin) do
                         {:ok, d} ->
                           case NaiveDateTime.new(d, ~T[00:00:00]) do
                             {:ok, ndt2} -> ndt2
                             _ -> bin
                           end
                         _ -> bin
                       end
                   end
                 # Empty string -> nil for nullable fields (let validations handle required)
                 {_, bin} when is_binary(bin) and bin == "" -> nil
                 _ -> v
               end
               {k, v2}
             end
             Ecto.Changeset.cast(data, normalized_params, Map.keys(normalized_params))
           end).(user, params)

    this1 = _ = Ecto.Changeset.cast(this1, Map.get(this1, :params, %{}) || %{}, [:name, :email])
    cs = Ecto.Changeset.validate_required(this1, [:name])
    cs = Ecto.Changeset.validate_length(cs, :name, Enum.filter([min: Map.get(%{min: 2}, :min), max: Map.get(%{min: 2}, :max), is: Map.get(%{min: 2}, :is)], fn {_, v} -> v != nil end))
    cs
  end
end

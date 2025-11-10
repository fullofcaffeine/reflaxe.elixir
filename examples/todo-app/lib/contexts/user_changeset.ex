defmodule UserChangeset do
  def changeset(user, attrs) do
    _this1 = (

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
           end).(user, attrs)
        
)
  end
end

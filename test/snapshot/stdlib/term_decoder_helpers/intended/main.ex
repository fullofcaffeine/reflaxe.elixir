defmodule Main do
  defp decode_search_params(params) do
    ResultTools.flat_map(ResultTools.flat_map(TermDecoder.fetch_string_key(params, "query"), &TermDecoder.as_string/1), fn query -> ResultTools.map(TermDecoder.optional_string_key_as(params, "page", &TermDecoder.as_int/1), fn page -> %{query: query, page: page} end) end)
  end
  defp decode_changeset_field(changeset) do
    field = "email"
    ResultTools.flat_map(TermDecoder.fetch_atom_key(changeset, field), &TermDecoder.as_string/1)
  end
  defp decode_repo_result(result) do
    TermDecoder.ok_error(result, &TermDecoder.as_string/1, &TermDecoder.as_string/1)
  end
  def main() do
    params = %{"query" => "haxe", "page" => 2}
    changeset_fields = %{email: "user@example.com"}
    ok_tuple = {:ok, "created"}
    error_tuple = {:error, "invalid"}
    _decoded_params = decode_search_params(params)
    _decoded_field = decode_changeset_field(changeset_fields)
    _decoded_ok = decode_repo_result(ok_tuple)
    _decoded_error = decode_repo_result(error_tuple)
    nil
  end
end

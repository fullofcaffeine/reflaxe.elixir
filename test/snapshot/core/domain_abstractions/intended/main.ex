defmodule Main do
  defp build_user_profile(user_id_str, email_str, score_str) do
    MyApp.ResultTools.flat_map(ResultTools.map_error(UserId_Impl_.parse(user_id_str), fn e -> "Invalid UserId: " <> e end), fn user_id ->
      ResultTools.flat_map(ResultTools.map_error(Email_Impl_.parse(StringTools.ltrim(StringTools.rtrim(email_str))), fn e -> "Invalid Email: " <> e end), fn email ->
        score_int = String.to_integer(score_str)
        if (score_int == nil), do: {:error, "Invalid score: " <> score_str}
        ResultTools.map(ResultTools.map_error(PositiveInt_Impl_.parse(score_int), fn e -> "Invalid score: " <> e end), fn score -> %{:user_id => user_id, :email => email, :score => score} end)
      end)
    end)
  end
  defp create_user(user_id_str, email_str, name_str) do
    MyApp.ResultTools.flat_map(ResultTools.map_error(UserId_Impl_.parse(user_id_str), fn e -> "Invalid UserId: " <> e end), fn user_id -> ResultTools.flat_map(ResultTools.map_error(Email_Impl_.parse(email_str), fn e -> "Invalid Email: " <> e end), fn email -> ResultTools.map(ResultTools.map_error(NonEmptyString_Impl_.parse_and_trim(name_str), fn e -> "Invalid Name: " <> e end), fn display_name -> %{:user_id => user_id, :email => email, :display_name => display_name} end) end) end)
  end
  defp validate_configuration(timeout_str, retries_str, name_str) do
    timeout_int = String.to_integer(timeout_str)
    retries_int = String.to_integer(retries_str)
    if (Kernel.is_nil(timeout_int)), do: {:error, "Timeout must be a number: " <> timeout_str}
    if (Kernel.is_nil(retries_int)), do: {:error, "Retries must be a number: " <> retries_str}
    MyApp.ResultTools.flat_map(ResultTools.map_error(PositiveInt_Impl_.parse(timeout_int), fn e -> "Invalid timeout: " <> e end), fn timeout -> ResultTools.flat_map(ResultTools.map_error(PositiveInt_Impl_.parse(retries_int), fn e -> "Invalid retries: " <> e end), fn retries -> ResultTools.map(ResultTools.map_error(NonEmptyString_Impl_.parse_and_trim(name_str), fn e -> "Invalid name: " <> e end), fn name -> %{:timeout => timeout, :retries => retries, :name => name} end) end) end)
  end
end

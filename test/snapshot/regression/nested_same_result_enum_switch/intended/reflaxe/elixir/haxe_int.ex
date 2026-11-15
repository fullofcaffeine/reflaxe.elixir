defmodule Reflaxe.Elixir.HaxeInt do
  def parse(value) do

    trim_leading = fn trim_leading, input ->
      case input do
        <<char, rest::binary>> when char in [9, 10, 11, 12, 13, 32] ->
          trim_leading.(trim_leading, rest)
        _ ->
          input
      end
    end

    case value do
      nil ->
        nil

      input when is_binary(input) ->
        trimmed = trim_leading.(trim_leading, input)

        {sign, unsigned} =
          case trimmed do
            <<"+", rest::binary>> -> {1, rest}
            <<"-", rest::binary>> -> {-1, rest}
            _ -> {1, trimmed}
          end

          parsed =
            case unsigned do
              <<"0x", rest::binary>> -> Integer.parse(rest, 16)
              <<"0X", rest::binary>> -> Integer.parse(rest, 16)
              <<"+", _::binary>> -> :error
              <<"-", _::binary>> -> :error
              _ -> Integer.parse(unsigned, 10)
            end

        case parsed do
          {integer, _rest} -> sign * integer
          :error -> nil
        end

      _ ->
        nil
    end

  end
end

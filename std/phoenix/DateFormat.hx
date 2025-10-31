package phoenix;

@:native("TodoApp.DateFormat")

class DateFormat {
  public static function format(d: Dynamic): String {
    return untyped __elixir__(
      '
      case {0} do
        nil -> ""
        %NaiveDateTime{} = nd -> Calendar.strftime(nd, "%Y-%m-%d")
        %Date{} = date -> Calendar.strftime(date, "%Y-%m-%d")
        s when is_binary(s) -> s
        _ -> ""
      end
      ', d);
  }
}


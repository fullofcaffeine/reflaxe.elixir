defmodule TimeUnit do
  @moduledoc """
  TimeUnit enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :second |
    :minute |
    :hour |
    :day |
    :week

  @doc "Creates second enum value"
  @spec second() :: :second
  def second(), do: :second

  @doc "Creates minute enum value"
  @spec minute() :: :minute
  def minute(), do: :minute

  @doc "Creates hour enum value"
  @spec hour() :: :hour
  def hour(), do: :hour

  @doc "Creates day enum value"
  @spec day() :: :day
  def day(), do: :day

  @doc "Creates week enum value"
  @spec week() :: :week
  def week(), do: :week

  # Predicate functions for pattern matching
  @doc "Returns true if value is second variant"
  @spec is_second(t()) :: boolean()
  def is_second(:second), do: true
  def is_second(_), do: false

  @doc "Returns true if value is minute variant"
  @spec is_minute(t()) :: boolean()
  def is_minute(:minute), do: true
  def is_minute(_), do: false

  @doc "Returns true if value is hour variant"
  @spec is_hour(t()) :: boolean()
  def is_hour(:hour), do: true
  def is_hour(_), do: false

  @doc "Returns true if value is day variant"
  @spec is_day(t()) :: boolean()
  def is_day(:day), do: true
  def is_day(_), do: false

  @doc "Returns true if value is week variant"
  @spec is_week(t()) :: boolean()
  def is_week(:week), do: true
  def is_week(_), do: false

end


defmodule TimePrecision do
  @moduledoc """
  TimePrecision enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :second |
    :millisecond |
    :microsecond

  @doc "Creates second enum value"
  @spec second() :: :second
  def second(), do: :second

  @doc "Creates millisecond enum value"
  @spec millisecond() :: :millisecond
  def millisecond(), do: :millisecond

  @doc "Creates microsecond enum value"
  @spec microsecond() :: :microsecond
  def microsecond(), do: :microsecond

  # Predicate functions for pattern matching
  @doc "Returns true if value is second variant"
  @spec is_second(t()) :: boolean()
  def is_second(:second), do: true
  def is_second(_), do: false

  @doc "Returns true if value is millisecond variant"
  @spec is_millisecond(t()) :: boolean()
  def is_millisecond(:millisecond), do: true
  def is_millisecond(_), do: false

  @doc "Returns true if value is microsecond variant"
  @spec is_microsecond(t()) :: boolean()
  def is_microsecond(:microsecond), do: true
  def is_microsecond(_), do: false

end


defmodule ComparisonResult do
  @moduledoc """
  ComparisonResult enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :lt |
    :eq |
    :gt

  @doc "Creates lt enum value"
  @spec lt() :: :lt
  def lt(), do: :lt

  @doc "Creates eq enum value"
  @spec eq() :: :eq
  def eq(), do: :eq

  @doc "Creates gt enum value"
  @spec gt() :: :gt
  def gt(), do: :gt

  # Predicate functions for pattern matching
  @doc "Returns true if value is lt variant"
  @spec is_lt(t()) :: boolean()
  def is_lt(:lt), do: true
  def is_lt(_), do: false

  @doc "Returns true if value is eq variant"
  @spec is_eq(t()) :: boolean()
  def is_eq(:eq), do: true
  def is_eq(_), do: false

  @doc "Returns true if value is gt variant"
  @spec is_gt(t()) :: boolean()
  def is_gt(:gt), do: true
  def is_gt(_), do: false

end

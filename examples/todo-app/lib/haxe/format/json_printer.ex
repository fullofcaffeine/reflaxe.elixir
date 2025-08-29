defmodule JsonPrinter do
  @moduledoc """
    JsonPrinter struct generated from Haxe

     * JsonPrinter: Simplified implementation avoiding mutable patterns
     *
     * WHY: The Haxe standard library JsonPrinter uses mutable StringBuf patterns
     * that don't translate well to Elixir's immutable world. This implementation
     * avoids those patterns by building strings functionally.
     *
     * WHAT: Functional implementation of JsonPrinter that generates valid Elixir
     *
     * HOW: Uses recursive string building without mutable state
  """

  defstruct [:replacer, :space]

  @type t() :: %__MODULE__{
    replacer: Null.t() | nil,
    space: Null.t() | nil
  }

  @doc "Creates a new struct instance"
  @spec new(Null.t(), Null.t()) :: t()
  def new(arg0, arg1) do
    %__MODULE__{
      replacer: arg0,
      space: arg1
    }
  end

  @doc "Updates struct fields using a map of changes"
  @spec update(t(), map()) :: t()
  def update(struct, changes) when is_map(changes) do
    Map.merge(struct, changes) |> then(&struct(__MODULE__, &1))
  end

  # Static functions
  @doc "Generated from Haxe print"
  def print(o, replacer \\ nil, space \\ nil) do
    printer = %JsonPrinter{}
    printer.writeValue(o, "")
  end

  # Instance functions
  @doc "Generated from Haxe writeValue"
  def write_value(%__MODULE__{} = struct, v, key) do
    temp_result = nil

    if (self.replacer != nil) do
      v = self.replacer(key, v)
    end
    if (v == nil) do
      "null"
    end
    _g = :Type.typeof(v)
    case (_g.elem(0)) do
      0 ->
        "null"
      1 ->
        :Std.string(v)
      2 ->
        s = :Std.string(v)
        if (s == "NaN" || s == "Infinity" || s == "-Infinity") do
          "null"
        end
        s
      3 ->
        temp_result = nil
        if (v) do
          temp_result = "true"
        else
          temp_result = "false"
        end
        temp_result
      4 ->
        self.writeObject(v)
      5 ->
        "null"
      6 ->
        _g_2 = _g.elem(1)
        c = _g_2
        class_name = :Type.getClassName(c)
        if (class_name == "String") do
          self.quoteString(v)
        else
          if (class_name == "Array") do
            self.writeArray(v)
          else
            self.writeObject(v)
          end
        end
      7 ->
        _g_2 = _g.elem(1)
        "null"
      8 ->
        "null"
    end
  end

  @doc "Generated from Haxe writeArray"
  def write_array(%__MODULE__{} = struct, arr) do
    items = []
    _g = 0
    _g_1 = arr.length
    loop_3()
    if (self.space != nil && items.length > 0) do
      "[\n  " + items.join(",\n  ") + "\n]"
    else
      "[" + items.join(",") + "]"
    end
  end

  @doc "Generated from Haxe writeObject"
  def write_object(%__MODULE__{} = struct, obj) do
    fields = :Reflect.fields(obj)
    pairs = []
    _g = 0
    loop_4()
    if (self.space != nil && pairs.length > 0) do
      "{\n  " + pairs.join(",\n  ") + "\n}"
    else
      "{" + pairs.join(",") + "}"
    end
  end

  @doc "Generated from Haxe quoteString"
  def quote_string(%__MODULE__{} = struct, s) do
    result = "\""
    _g = 0
    _g_1 = s.length
    loop_5()
    result = result + "\""
    result
  end

  @doc "Generated from Haxe write"
  def write(%__MODULE__{} = struct, k, v) do
    self.writeValue(v, k)
  end


  # While loop helper functions
  # Generated automatically for tail-recursive loop patterns

  @doc false
  defp while_loop(condition_fn, body_fn) do
    if condition_fn.() do
      body_fn.()
      while_loop(condition_fn, body_fn)
    else
      nil
    end
  end

  @doc false
  defp do_while_loop(body_fn, condition_fn) do
    body_fn.()
    if condition_fn.() do
      do_while_loop(body_fn, condition_fn)
    else
      nil
    end
  end

end

defmodule Main do
  @moduledoc """
    Main module generated from Haxe

     * Dynamic type test case
     * Tests dynamic typing and runtime type checking
  """

  # Static functions
  @doc "Generated from Haxe dynamicVars"
  def dynamic_vars() do
    dyn = 42

    Log.trace(dyn, %{"fileName" => "Main.hx", "lineNumber" => 11, "className" => "Main", "methodName" => "dynamicVars"})

    dyn = "Hello"

    Log.trace(dyn, %{"fileName" => "Main.hx", "lineNumber" => 14, "className" => "Main", "methodName" => "dynamicVars"})

    dyn = [1, 2, 3]

    Log.trace(dyn, %{"fileName" => "Main.hx", "lineNumber" => 17, "className" => "Main", "methodName" => "dynamicVars"})

    dyn = %{"name" => "John", "age" => 30}

    Log.trace(dyn, %{"fileName" => "Main.hx", "lineNumber" => 20, "className" => "Main", "methodName" => "dynamicVars"})

    dyn = fn x -> (x * 2) end

    Log.trace(dyn(5), %{"fileName" => "Main.hx", "lineNumber" => 23, "className" => "Main", "methodName" => "dynamicVars"})
  end

  @doc "Generated from Haxe dynamicFieldAccess"
  def dynamic_field_access() do
    obj = %{"name" => "Alice", "age" => 25, "greet" => fn  -> "Hello!" end}

    Log.trace(obj.name, %{"fileName" => "Main.hx", "lineNumber" => 34, "className" => "Main", "methodName" => "dynamicFieldAccess"})

    Log.trace(obj.age, %{"fileName" => "Main.hx", "lineNumber" => 35, "className" => "Main", "methodName" => "dynamicFieldAccess"})

    Log.trace(obj.greet(), %{"fileName" => "Main.hx", "lineNumber" => 36, "className" => "Main", "methodName" => "dynamicFieldAccess"})

    %{obj | city: "New York"}

    Log.trace(obj.city, %{"fileName" => "Main.hx", "lineNumber" => 40, "className" => "Main", "methodName" => "dynamicFieldAccess"})

    Log.trace(obj.non_existent, %{"fileName" => "Main.hx", "lineNumber" => 43, "className" => "Main", "methodName" => "dynamicFieldAccess"})
  end

  @doc "Generated from Haxe dynamicFunctions"
  def dynamic_functions() do
    fn_ = fn a, b -> (a + b) end

    Log.trace(fn_(10, 20), %{"fileName" => "Main.hx", "lineNumber" => 49, "className" => "Main", "methodName" => "dynamicFunctions"})

    fn_ = fn s -> s.to_upper_case() end

    Log.trace(fn_("hello"), %{"fileName" => "Main.hx", "lineNumber" => 52, "className" => "Main", "methodName" => "dynamicFunctions"})

    var_args = fn args -> sum = 0
    g_counter = 0
    (fn loop ->
      if ((g_counter < args.length)) do
            arg = Enum.at(args, g_counter)
        g_counter + 1
        sum = sum + arg
        loop.()
      end
    end).()
    sum end

    Log.trace(var_args([1, 2, 3, 4, 5]), %{"fileName" => "Main.hx", "lineNumber" => 62, "className" => "Main", "methodName" => "dynamicFunctions"})
  end

  @doc "Generated from Haxe typeChecking"
  def type_checking() do
    value = 42

    if Std.is_of_type(value, Int), do: Log.trace("It's an Int: " <> Std.string(value), %{"fileName" => "Main.hx", "lineNumber" => 71, "className" => "Main", "methodName" => "typeChecking"}), else: nil

    value = "Hello"

    if Std.is_of_type(value, String), do: Log.trace("It's a String: " <> Std.string(value), %{"fileName" => "Main.hx", "lineNumber" => 76, "className" => "Main", "methodName" => "typeChecking"}), else: nil

    value = [1, 2, 3]

    if Std.is_of_type(value, Array), do: Log.trace("It's an Array with length: " <> Std.string(value.length), %{"fileName" => "Main.hx", "lineNumber" => 81, "className" => "Main", "methodName" => "typeChecking"}), else: nil

    num = "123"

    int_value = Std.parse_int(num)

    Log.trace("Parsed int: " <> to_string(int_value), %{"fileName" => "Main.hx", "lineNumber" => 87, "className" => "Main", "methodName" => "typeChecking"})

    float_value = Std.parse_float("3.14")

    Log.trace("Parsed float: " <> to_string(float_value), %{"fileName" => "Main.hx", "lineNumber" => 90, "className" => "Main", "methodName" => "typeChecking"})
  end

  @doc "Generated from Haxe dynamicGenerics"
  def dynamic_generics(value) do
    value
  end

  @doc "Generated from Haxe dynamicCollections"
  def dynamic_collections() do
    dyn_array = [1, "two", 3.0, true, %{"x" => 10}]

    g_counter = 0

    (fn loop ->
      if ((g_counter < dyn_array.length)) do
            item = Enum.at(dyn_array, g_counter)
        g_counter + 1
        Log.trace("Item: " <> Std.string(item), %{"fileName" => "Main.hx", "lineNumber" => 103, "className" => "Main", "methodName" => "dynamicCollections"})
        loop.()
      end
    end).()

    dyn_obj = %{}

    %{dyn_obj | field1: "value1"}

    %{dyn_obj | field2: 42}

    %{dyn_obj | field3: [1, 2, 3]}

    Log.trace(dyn_obj, %{"fileName" => "Main.hx", "lineNumber" => 113, "className" => "Main", "methodName" => "dynamicCollections"})
  end

  @doc "Generated from Haxe processDynamic"
  def process_dynamic(value) do
    if ((value == nil)) do
      "null"
    else
      if Std.is_of_type(value, Bool) do
        "Bool: " <> Std.string(value)
      else
        if Std.is_of_type(value, Int) do
          "Int: " <> Std.string(value)
        else
          if Std.is_of_type(value, Float) do
            "Float: " <> Std.string(value)
          else
            if Std.is_of_type(value, String) do
              "String: " <> Std.string(value)
            else
              if Std.is_of_type(value, Array) do
                "Array of length: " <> Std.string(value.length)
              else
                "Unknown type"
              end
            end
          end
        end
      end
    end
  end

  @doc "Generated from Haxe dynamicMethodCalls"
  def dynamic_method_calls() do
    obj = %{}

    %{obj | value: 10}

    %{obj | increment: fn  -> obj.value + 1 end}

    %{obj | get_value: fn  -> obj.value end}

    Log.trace("Initial value: " <> Std.string(obj.get_value()), %{"fileName" => "Main.hx", "lineNumber" => 146, "className" => "Main", "methodName" => "dynamicMethodCalls"})

    obj.increment()

    Log.trace("After increment: " <> Std.string(obj.get_value()), %{"fileName" => "Main.hx", "lineNumber" => 148, "className" => "Main", "methodName" => "dynamicMethodCalls"})

    method_name = "increment"

    Reflect.call_method(obj, Reflect.field(obj, method_name), [])

    Log.trace("After reflect call: " <> Std.string(obj.get_value()), %{"fileName" => "Main.hx", "lineNumber" => 153, "className" => "Main", "methodName" => "dynamicMethodCalls"})
  end

  @doc "Generated from Haxe main"
  def main() do
    Log.trace("=== Dynamic Variables ===", %{"fileName" => "Main.hx", "lineNumber" => 157, "className" => "Main", "methodName" => "main"})

    Main.dynamic_vars()

    Log.trace("\n=== Dynamic Field Access ===", %{"fileName" => "Main.hx", "lineNumber" => 160, "className" => "Main", "methodName" => "main"})

    Main.dynamic_field_access()

    Log.trace("\n=== Dynamic Functions ===", %{"fileName" => "Main.hx", "lineNumber" => 163, "className" => "Main", "methodName" => "main"})

    Main.dynamic_functions()

    Log.trace("\n=== Type Checking ===", %{"fileName" => "Main.hx", "lineNumber" => 166, "className" => "Main", "methodName" => "main"})

    Main.type_checking()

    Log.trace("\n=== Dynamic Collections ===", %{"fileName" => "Main.hx", "lineNumber" => 169, "className" => "Main", "methodName" => "main"})

    Main.dynamic_collections()

    Log.trace("\n=== Process Dynamic ===", %{"fileName" => "Main.hx", "lineNumber" => 172, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.process_dynamic(nil), %{"fileName" => "Main.hx", "lineNumber" => 173, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.process_dynamic(true), %{"fileName" => "Main.hx", "lineNumber" => 174, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.process_dynamic(42), %{"fileName" => "Main.hx", "lineNumber" => 175, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.process_dynamic(3.14), %{"fileName" => "Main.hx", "lineNumber" => 176, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.process_dynamic("Hello"), %{"fileName" => "Main.hx", "lineNumber" => 177, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.process_dynamic([1, 2, 3]), %{"fileName" => "Main.hx", "lineNumber" => 178, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.process_dynamic(%{"x" => 1, "y" => 2}), %{"fileName" => "Main.hx", "lineNumber" => 179, "className" => "Main", "methodName" => "main"})

    Log.trace("\n=== Dynamic Method Calls ===", %{"fileName" => "Main.hx", "lineNumber" => 181, "className" => "Main", "methodName" => "main"})

    Main.dynamic_method_calls()

    Log.trace("\n=== Dynamic Generics ===", %{"fileName" => "Main.hx", "lineNumber" => 184, "className" => "Main", "methodName" => "main"})

    str = Main.dynamic_generics("Hello from dynamic")

    Log.trace(str, %{"fileName" => "Main.hx", "lineNumber" => 186, "className" => "Main", "methodName" => "main"})
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

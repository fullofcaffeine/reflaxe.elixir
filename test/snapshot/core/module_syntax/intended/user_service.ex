defmodule UserService do
  @moduledoc """
    UserService module generated from Haxe

     * Module Syntax Sugar Test
     * Tests @:module annotation for simplified Elixir module generation
     * Converted from framework-based ModuleSyntaxTest.hx to snapshot test
  """

  # Module functions - generated with @:module syntax sugar

  @doc "Generated from Haxe createUser"
  def create_user(name, age) do
    name <> " is " <> to_string(age) <> " years old"
  end


  @doc "Generated from Haxe validateAge"
  def validate_age(age) do
    ((age >= 0) && (age <= 150))
  end


  @doc "Generated from Haxe processData"
  def process_data(data) do
    data
  end


  @doc "Generated from Haxe complexFunction"
  def complex_function(arg1, arg2, arg3, _arg4) do
    if arg3 do
      arg1 <> " " <> to_string(arg2)
    else
      nil
    end

    "default"
  end


end

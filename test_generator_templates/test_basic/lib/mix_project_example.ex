defmodule MixProjectExample do
  @moduledoc """
  MixProjectExample - Demonstrates Haxe→Elixir integration in a Mix project.

  This module serves as the main entry point and demonstrates how Haxe-compiled
  modules can be used seamlessly alongside hand-written Elixir code.
  """

  @doc """
  Example function showing integration between Haxe and Elixir code.
  
  This function uses modules compiled from Haxe source to perform operations,
  demonstrating the seamless integration between the two languages.
  """
  def run_example do
    # Use Haxe-compiled UserService
    user_data = %{name: "John Doe", email: "john@example.com", age: 30}
    
    case Services.UserService.create_user(user_data) do
      {:ok, user} ->
        IO.puts("✅ User created successfully!")
        IO.puts("📧 Email: #{user.email}")
        IO.puts("👤 Display name: #{Utils.StringUtils.format_display_name(user.name)}")
        
        # Use Haxe-compiled MathHelper for age calculations
        years_to_retirement = Utils.MathHelper.calculate_years_to_retirement(user.age)
        IO.puts("🎯 Years to retirement: #{years_to_retirement}")
        
        {:ok, user}
      
      {:error, reason} ->
        IO.puts("❌ Failed to create user: #{reason}")
        {:error, reason}
    end
  end
  
  @doc """
  Demonstrates string processing with Haxe-compiled utilities.
  """
  def string_processing_example do
    test_strings = [
      "  hello world  ",
      "UPPERCASE TEXT",
      "mixed CaSe StRiNg",
      "with@email.com",
      ""
    ]
    
    IO.puts("🔤 String Processing Examples:")
    
    Enum.each(test_strings, fn str ->
      processed = Utils.StringUtils.process_string(str)
      IO.puts("  '#{str}' -> '#{processed}'")
    end)
  end
  
  @doc """
  Shows mathematical operations using Haxe-compiled helpers.
  """
  def math_examples do
    IO.puts("🔢 Mathematical Operations:")
    
    # Test various mathematical operations
    test_cases = [
      {10.5, "Basic processing"},
      {-5.2, "Negative number"},
      {0.0, "Zero value"},
      {99.9, "Large number"}
    ]
    
    Enum.each(test_cases, fn {number, description} ->
      result = Utils.MathHelper.process_number(number)
      IO.puts("  #{description}: #{number} -> #{result}")
    end)
  end
  
  @doc """
  Comprehensive example showing all integrated functionality.
  """
  def comprehensive_example do
    IO.puts("🚀 Comprehensive Mix Project Example")
    IO.puts("===================================")
    
    run_example()
    IO.puts("")
    
    string_processing_example()
    IO.puts("")
    
    math_examples()
    IO.puts("")
    
    IO.puts("✨ All examples completed successfully!")
    IO.puts("This demonstrates seamless Haxe→Elixir integration in Mix projects.")
  end
end
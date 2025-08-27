defmodule MixProjectExampleTest do
  use ExUnit.Case
  doctest MixProjectExample
  
  import ExUnit.CaptureIO
  
  describe "run_example/0" do
    test "successfully creates and processes a user" do
      # Capture output to verify the integration works
      output = capture_io(fn ->
        result = MixProjectExample.run_example()
        assert {:ok, _user} = result
      end)
      
      # Verify expected output messages
      assert String.contains?(output, "✅ User created successfully!")
      assert String.contains?(output, "📧 Email:")
      assert String.contains?(output, "👤 Display name:")
      assert String.contains?(output, "🎯 Years to retirement:")
    end
  end
  
  describe "string_processing_example/0" do
    test "processes various string inputs" do
      output = capture_io(fn ->
        MixProjectExample.string_processing_example()
      end)
      
      assert String.contains?(output, "🔤 String Processing Examples:")
      assert String.contains?(output, "hello world")
      assert String.contains?(output, "UPPERCASE TEXT")
    end
  end
  
  describe "math_examples/0" do
    test "performs mathematical operations" do
      output = capture_io(fn ->
        MixProjectExample.math_examples()
      end)
      
      assert String.contains?(output, "🔢 Mathematical Operations:")
      assert String.contains?(output, "Basic processing:")
      assert String.contains?(output, "Negative number:")
      assert String.contains?(output, "Zero value:")
    end
  end
  
  describe "comprehensive_example/0" do
    test "runs all integrated examples successfully" do
      output = capture_io(fn ->
        MixProjectExample.comprehensive_example()
      end)
      
      # Verify all sections are present
      assert String.contains?(output, "🚀 Comprehensive Mix Project Example")
      assert String.contains?(output, "✅ User created successfully!")
      assert String.contains?(output, "🔤 String Processing Examples:")
      assert String.contains?(output, "🔢 Mathematical Operations:")
      assert String.contains?(output, "✨ All examples completed successfully!")
      assert String.contains?(output, "seamless Haxe→Elixir integration")
    end
  end
  
  describe "Integration between modules" do
    test "Haxe modules work together seamlessly" do
      # Test that modules compiled from Haxe can call each other
      user_data = %{name: "jane doe", email: "jane@test.com", age: 25}
      
      # Create user using UserService
      result = Services.UserService.create_user(user_data)
      assert {:ok, user} = result
      
      # Format display name using StringUtils
      display_name = Utils.StringUtils.format_display_name(user.name)
      assert display_name == "Jane Doe"
      
      # Calculate retirement years using MathHelper
      retirement_years = Utils.MathHelper.calculate_years_to_retirement(user.age)
      assert retirement_years == 40
      
      # Validate email using ValidationHelper
      email_validation = Utils.ValidationHelper.validate_email(user.email)
      assert email_validation.valid == true
    end
    
    test "Error handling works across modules" do
      # Test error propagation between Haxe modules
      
      # Invalid user data
      invalid_result = Services.UserService.create_user(%{name: "", email: "invalid"})
      assert {:error, _reason} = invalid_result
      
      # Invalid email validation
      email_result = Utils.ValidationHelper.validate_email("not-an-email")
      assert email_result.valid == false
      
      # Invalid number validation
      number_result = Utils.MathHelper.validate_number("not-a-number")
      assert number_result.valid == false
    end
  end
  
  describe "Performance characteristics" do
    test "Haxe modules perform efficiently" do
      # Test that compiled modules have reasonable performance
      {time_ms, _result} = measure_time(fn ->
        # Run multiple operations to test performance
        Enum.each(1..100, fn i ->
          user_data = %{name: "User #{i}", email: "user#{i}@test.com", age: 20 + i}
          {:ok, user} = Services.UserService.create_user(user_data)
          
          _display_name = Utils.StringUtils.format_display_name(user.name)
          _retirement = Utils.MathHelper.calculate_years_to_retirement(user.age)
          _validation = Utils.ValidationHelper.validate_email(user.email)
        end)
      end)
      
      # Should complete 100 operations in reasonable time (less than 100ms)
      assert time_ms < 100, "Performance test took #{time_ms}ms, expected < 100ms"
    end
  end
  
  describe "Type safety and data integrity" do
    test "Haxe type safety is preserved in compiled modules" do
      # Test that type checking and validation work as expected
      
      # Test with proper types
      valid_user = Services.UserService.create_user(%{
        name: "Test User",
        email: "test@example.com",
        age: 30
      })
      assert {:ok, _user} = valid_user
      
      # Test with missing required fields
      invalid_user = Services.UserService.create_user(%{name: "Test"})
      assert {:error, _reason} = invalid_user
    end
    
    test "Data transformations maintain integrity" do
      original_name = "  john DOE  "
      formatted = Utils.StringUtils.format_display_name(original_name)
      assert formatted == "John Doe"
      
      original_email = "  TEST@EXAMPLE.COM  "
      email_result = Utils.StringUtils.process_email(original_email)
      assert email_result.valid == true
      assert email_result.email == "test@example.com"
    end
  end
end
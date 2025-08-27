defmodule StringUtilsTest do
  use ExUnit.Case
  doctest Utils.StringUtils
  
  describe "process_string/1" do
    test "processes normal strings correctly" do
      result = Utils.StringUtils.process_string("  hello world  ")
      assert result == "Hello world"
    end
    
    test "handles empty and null strings" do
      assert Utils.StringUtils.process_string("") == "[empty]"
      assert Utils.StringUtils.process_string("   ") == "[empty]"
      assert Utils.StringUtils.process_string(nil) == ""
    end
    
    test "removes excess whitespace" do
      result = Utils.StringUtils.process_string("hello    world    test")
      assert result == "Hello world test"
    end
  end
  
  describe "format_display_name/1" do
    test "formats names correctly" do
      assert Utils.StringUtils.format_display_name("john doe") == "John Doe"
      assert Utils.StringUtils.format_display_name("JANE SMITH") == "Jane Smith"
      assert Utils.StringUtils.format_display_name("bob") == "Bob"
    end
    
    test "handles edge cases" do
      assert Utils.StringUtils.format_display_name(nil) == "Anonymous User"
      assert Utils.StringUtils.format_display_name("") == "Anonymous User"
      assert Utils.StringUtils.format_display_name("   ") == "Anonymous User"
    end
    
    test "handles multiple spaces correctly" do
      result = Utils.StringUtils.format_display_name("john   middle   doe")
      assert result == "John Middle Doe"
    end
  end
  
  describe "process_email/1" do
    test "validates and processes correct emails" do
      result = Utils.StringUtils.process_email("  JOHN@EXAMPLE.COM  ")
      
      assert result.valid == true
      assert result.email == "john@example.com"
      assert result.domain == "example.com"
      assert result.username == "john"
    end
    
    test "rejects invalid emails" do
      # Null email
      result1 = Utils.StringUtils.process_email(nil)
      assert result1.valid == false
      assert result1.error == "Email is required"
      
      # Empty email
      result2 = Utils.StringUtils.process_email("")
      assert result2.valid == false
      assert result2.error == "Email cannot be empty"
      
      # Invalid format
      result3 = Utils.StringUtils.process_email("invalid-email")
      assert result3.valid == false
      assert result3.error == "Invalid email format"
      
      # Missing @ symbol
      result4 = Utils.StringUtils.process_email("userexample.com")
      assert result4.valid == false
      assert result4.error == "Invalid email format"
    end
  end
  
  describe "create_slug/1" do
    test "creates URL-friendly slugs" do
      assert Utils.StringUtils.create_slug("Hello World") == "hello-world"
      assert Utils.StringUtils.create_slug("My Awesome Blog Post!") == "my-awesome-blog-post"
      assert Utils.StringUtils.create_slug("Special@Characters#Removed$") == "specialcharactersremoved"
    end
    
    test "handles edge cases" do
      assert Utils.StringUtils.create_slug(nil) == ""
      assert Utils.StringUtils.create_slug("") == ""
      assert Utils.StringUtils.create_slug("   ") == ""
      assert Utils.StringUtils.create_slug("---") == ""
    end
    
    test "collapses multiple spaces and hyphens" do
      assert Utils.StringUtils.create_slug("hello    world") == "hello-world"
      assert Utils.StringUtils.create_slug("multiple---hyphens") == "multiple-hyphens"
    end
  end
  
  describe "truncate/2" do
    test "truncates long text correctly" do
      long_text = "This is a very long text that should be truncated at some point to prevent it from being too long"
      
      result = Utils.StringUtils.truncate(long_text, 50)
      
      assert String.length(result) <= 50
      assert String.ends_with?(result, "...")
    end
    
    test "leaves short text unchanged" do
      short_text = "Short text"
      result = Utils.StringUtils.truncate(short_text, 50)
      assert result == short_text
    end
    
    test "handles null and empty strings" do
      assert Utils.StringUtils.truncate(nil, 50) == ""
      assert Utils.StringUtils.truncate("", 50) == ""
    end
    
    test "tries to break at word boundaries" do
      text = "This is a test string with multiple words for boundary testing"
      result = Utils.StringUtils.truncate(text, 30)
      
      # Should not break in the middle of a word if possible
      refute String.contains?(result, " wo...")  # Shouldn't break "words" in the middle
    end
  end
  
  describe "mask_sensitive_info/2" do
    test "masks information correctly" do
      assert Utils.StringUtils.mask_sensitive_info("password123", 2) == "pa*********"
      assert Utils.StringUtils.mask_sensitive_info("secret", 3) == "sec***"
    end
    
    test "handles short strings" do
      assert Utils.StringUtils.mask_sensitive_info("ab", 2) == "ab"
      assert Utils.StringUtils.mask_sensitive_info("a", 2) == "*"
    end
    
    test "handles null strings" do
      result = Utils.StringUtils.mask_sensitive_info(nil, 2)
      assert String.length(result) == 4  # Default mask length
      assert String.contains?(result, "*")
    end
  end
end
defmodule MathHelperTest do
  use ExUnit.Case
  doctest MathHelper
  
  describe "process_number/1" do
    test "processes numbers through transformation pipeline" do
      # Input: 5.0 -> *2 = 10.0 -> +10 = 20.0 -> bounded [0,100] = 20.0 -> rounded = 20
      result = MathHelper.process_number(5.0)
      assert result == 20.0
    end
    
    test "applies bounds correctly" do
      # Large number should be bounded to max (100)
      result = MathHelper.process_number(50.0)  # 50*2+10 = 110, bounded to 100
      assert result == 100.0
    end
    
    test "handles negative numbers" do
      result = MathHelper.process_number(-10.0)  # -10*2+10 = -10, bounded to 0
      assert result == 0.0
    end
  end
  
  describe "calculate_years_to_retirement/1" do
    test "calculates years correctly for working age" do
      assert MathHelper.calculate_years_to_retirement(30) == 35
      assert MathHelper.calculate_years_to_retirement(64) == 1
      assert MathHelper.calculate_years_to_retirement(40) == 25
    end
    
    test "returns zero for retirement age or older" do
      assert MathHelper.calculate_years_to_retirement(65) == 0
      assert MathHelper.calculate_years_to_retirement(70) == 0
      assert MathHelper.calculate_years_to_retirement(80) == 0
    end
    
    test "handles edge cases" do
      assert MathHelper.calculate_years_to_retirement(0) == 65
      assert MathHelper.calculate_years_to_retirement(1) == 64
    end
  end
  
  describe "calculate_discount/3" do
    test "applies customer type discounts" do
      result_premium = MathHelper.calculate_discount(100.0, "premium", 1)
      assert result_premium.discount == 0.15  # 15% for premium
      
      result_regular = MathHelper.calculate_discount(100.0, "regular", 1)
      assert result_regular.discount == 0.05  # 5% for regular
      
      result_new = MathHelper.calculate_discount(100.0, "new", 1)
      assert result_new.discount == 0.10  # 10% for new customers
    end
    
    test "applies volume discounts" do
      result_10 = MathHelper.calculate_discount(100.0, "regular", 10)
      assert result_10.discount == 0.10  # 5% base + 5% volume
      
      result_50 = MathHelper.calculate_discount(100.0, "regular", 50)
      assert result_50.discount == 0.20  # 5% base + 5% + 10% volume

      result_100 = MathHelper.calculate_discount(100.0, "regular", 100)
      assert result_100.discount == 0.30  # 5% base + 5% + 10% + 15% volume, capped
    end
    
    test "caps discount at 30%" do
      result = MathHelper.calculate_discount(100.0, "premium", 100)
      # Premium (15%) + volume discounts (20%) = 35%, but capped at 30%
      assert result.discount == 0.30
    end
    
    test "calculates final prices correctly" do
      result = MathHelper.calculate_discount(100.0, "regular", 1)
      
      assert result.base_price == 100.0
      assert result.discount == 0.05
      assert result.discount_amount == 5.0
      assert result.final_price == 95.0
      assert result.savings == 5.0
    end
  end
  
  describe "calculate_compound_interest/4" do
    test "calculates compound interest correctly" do
      assert {:ok, result} = MathHelper.calculate_compound_interest(1000.0, 5.0, 2, 1)
      
      assert result.principal == 1000.0
      assert result.rate == 5.0
      assert result.time == 2
      assert result.compound == 1
      assert result.amount == 1102.5  # 1000 * (1.05)^2 = 1102.5
      assert result.interest == 102.5
    end
    
    test "handles different compounding frequencies" do
      # Quarterly compounding (compound = 4)
      assert {:ok, result} = MathHelper.calculate_compound_interest(1000.0, 4.0, 1, 4)
      
      assert result.compound == 4
      # Amount should be 1000 * (1 + 0.04/4)^(4*1) = 1000 * (1.01)^4 ≈ 1040.60
      assert result.amount > 1040.0
      assert result.amount < 1041.0
    end
    
    test "rejects invalid parameters" do
      result1 = MathHelper.calculate_compound_interest(0.0, 5.0, 2, 1)
      assert {:error, _reason} = result1

      result2 = MathHelper.calculate_compound_interest(1000.0, -5.0, 2, 1)
      assert {:error, _reason} = result2

      result3 = MathHelper.calculate_compound_interest(1000.0, 5.0, -2, 1)
      assert {:error, _reason} = result3
    end
  end
  
  describe "validate_number/1" do
    test "validates correct numbers" do
      assert {:ok, result} = MathHelper.validate_number("42")

      assert result.number == 42.0
      assert result.is_integer == true
      assert result.is_positive == true
      assert result.is_negative == false
      assert result.absolute_value == 42.0
    end
    
    test "validates float numbers" do
      assert {:ok, result} = MathHelper.validate_number("3.14")

      assert result.number == 3.14
      assert result.is_integer == false
      assert result.is_positive == true
    end
    
    test "validates negative numbers" do
      assert {:ok, result} = MathHelper.validate_number("-10")

      assert result.is_positive == false
      assert result.is_negative == true
      assert result.absolute_value == 10.0
    end
    
    test "rejects invalid inputs" do
      result1 = MathHelper.validate_number(nil)
      assert {:error, "Input is null"} = result1

      result2 = MathHelper.validate_number("not-a-number")
      assert {:error, reason} = result2
      assert String.contains?(reason, "number")
    end
  end
  
  describe "calculate_stats/1" do
    test "calculates statistics correctly" do
      numbers = [1.0, 2.0, 3.0, 4.0, 5.0]
      assert {:ok, result} = MathHelper.calculate_stats(numbers)
      
      assert result.count == 5
      assert result.sum == 15.0
      assert result.mean == 3.0
      assert result.median == 3.0
      assert result.min == 1.0
      assert result.max == 5.0
      assert result.range == 4.0
    end
    
    test "handles even number of elements for median" do
      numbers = [1.0, 2.0, 3.0, 4.0]
      assert {:ok, result} = MathHelper.calculate_stats(numbers)
      
      assert result.median == 2.5  # Average of 2.0 and 3.0
    end
    
    test "handles single element array" do
      numbers = [42.0]
      assert {:ok, result} = MathHelper.calculate_stats(numbers)
      
      assert result.count == 1
      assert result.sum == 42.0
      assert result.mean == 42.0
      assert result.median == 42.0
      assert result.min == 42.0
      assert result.max == 42.0
      assert result.range == 0.0
    end
    
    test "rejects invalid inputs" do
      result1 = MathHelper.calculate_stats(nil)
      assert {:error, _reason} = result1

      result2 = MathHelper.calculate_stats([])
      assert {:error, _reason} = result2
    end
  end
end

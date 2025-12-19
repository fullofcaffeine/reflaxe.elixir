package utils;

import elixir.types.Result;

/**
 * MathHelper - Mathematical operations and calculations for Mix project
 * 
 * This module provides mathematical utilities that demonstrate
 * numerical processing within a Mix project context.
 */
@:module
class MathHelper {
    
    /**
     * Processes a number through a series of transformations
     * Demonstrates functional composition in a Mix context
     */
    public static function processNumber(x: Float): Float {
        var step1 = multiplyByFactor(x, 2.0);
        var step2 = addOffset(step1, 10.0);
        var step3 = applyBounds(step2, 0.0, 100.0);
        return Math.round(step3);
    }
    
    /**
     * Calculates years until retirement age (65)
     * Useful for user profile calculations
     */
    public static function calculateYearsToRetirement(currentAge: Int): Int {
        var retirementAge = 65;
        var yearsLeft = retirementAge - currentAge;
        return Std.int(Math.max(0, yearsLeft));
    }
    
    /**
     * Calculates discount based on various factors
     * Demonstrates business logic calculations
     */
    public static function calculateDiscount(basePrice: Float, customerType: String, quantity: Int): DiscountResult {
        var discount = 0.0;
        
        // Base discount by customer type
        switch (customerType) {
            case "premium": discount += 0.15;
            case "regular": discount += 0.05;
            case "new": discount += 0.10;
            case _: discount += 0.0;
        }
        
        // Volume discount
        if (quantity >= 10) discount += 0.05;
        if (quantity >= 50) discount += 0.10;
        if (quantity >= 100) discount += 0.15;
        
        // Cap discount at 30%
        discount = Math.min(discount, 0.30);
        
        var discountAmount = basePrice * discount;
        var finalPrice = basePrice - discountAmount;
        
        return {
            basePrice: basePrice,
            discount: discount,
            discountAmount: discountAmount,
            finalPrice: finalPrice,
            savings: discountAmount
        };
    }
    
    /**
     * Calculates compound interest
     * Useful for financial calculations in applications
     */
    public static function calculateCompoundInterest(principal: Float, rate: Float, time: Int, compound: Int = 1): Result<CompoundInterestResult, String> {
        if (principal <= 0 || rate <= 0 || time <= 0 || compound <= 0) {
            return Error("Invalid parameters for compound interest calculation");
        }
        
        var rateDecimal = rate / 100.0;
        var amount = principal * Math.pow(1 + (rateDecimal / compound), compound * time);
        var interest = amount - principal;
        
        return Ok({
            principal: principal,
            rate: rate,
            time: time,
            compound: compound,
            amount: Math.round(amount * 100) / 100,
            interest: Math.round(interest * 100) / 100
        });
    }
    
    /**
     * Validates numerical input and provides error information
     */
    public static function validateNumber(input: String): Result<ValidatedNumber, String> {
        if (input == null) {
            return Error("Input is null");
        }
        
        // Try to convert to number
        var number = Std.parseFloat(input);
        
        if (Math.isNaN(number)) {
            return Error("Input is not a valid number");
        }
        
        if (!Math.isFinite(number)) {
            return Error("Input is not finite");
        }
        
        return Ok({
            number: number,
            isInteger: number == Math.floor(number),
            isPositive: number > 0,
            isNegative: number < 0,
            absoluteValue: Math.abs(number)
        });
    }
    
    /**
     * Performs statistical calculations on an array of numbers
     */
    public static function calculateStats(numbers: Array<Float>): Result<StatsResult, String> {
        if (numbers == null || numbers.length == 0) {
            return Error("Empty or null array provided");
        }
        
        var sum = 0.0;
        var min = numbers[0];
        var max = numbers[0];
        
        for (num in numbers) {
            sum += num;
            if (num < min) min = num;
            if (num > max) max = num;
        }
        
        var mean = sum / numbers.length;
        
        // Calculate median
        var sorted = numbers.copy();
        sorted.sort(function(a, b) return a < b ? -1 : (a > b ? 1 : 0));
        var median: Float;
        var midIndex = Std.int(sorted.length / 2);
        
        if (sorted.length % 2 == 0) {
            median = (sorted[midIndex - 1] + sorted[midIndex]) / 2;
        } else {
            median = sorted[midIndex];
        }
        
        return Ok({
            count: numbers.length,
            sum: sum,
            mean: mean,
            median: median,
            min: min,
            max: max,
            range: max - min
        });
    }
    
    // Private helper functions
    
    static function multiplyByFactor(value: Float, factor: Float): Float {
        return value * factor;
    }
    
    static function addOffset(value: Float, offset: Float): Float {
        return value + offset;
    }
    
    static function applyBounds(value: Float, min: Float, max: Float): Float {
        if (value < min) return min;
        if (value > max) return max;
        return value;
    }
    
    /**
     * Main function for compilation testing
     */
    public static function main(): Void {
        trace("MathHelper compiled successfully for Mix project!");
    }
}

typedef DiscountResult = {
    var basePrice: Float;
    var discount: Float;
    var discountAmount: Float;
    var finalPrice: Float;
    var savings: Float;
}

typedef CompoundInterestResult = {
    var principal: Float;
    var rate: Float;
    var time: Int;
    var compound: Int;
    var amount: Float;
    var interest: Float;
}

typedef ValidatedNumber = {
    var number: Float;
    var isInteger: Bool;
    var isPositive: Bool;
    var isNegative: Bool;
    var absoluteValue: Float;
}

typedef StatsResult = {
    var count: Int;
    var sum: Float;
    var mean: Float;
    var median: Float;
    var min: Float;
    var max: Float;
    var range: Float;
}

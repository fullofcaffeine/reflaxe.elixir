package utils;

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
    function processNumber(x: Float): Float {
        var step1 = multiplyByFactor(x, 2.0);
        var step2 = addOffset(step1, 10.0);
        var step3 = applyBounds(step2, 0.0, 100.0);
        return Math.round(step3);
    }
    
    /**
     * Calculates years until retirement age (65)
     * Useful for user profile calculations
     */
    function calculateYearsToRetirement(currentAge: Int): Int {
        var retirementAge = 65;
        var yearsLeft = retirementAge - currentAge;
        return Std.int(Math.max(0, yearsLeft));
    }
    
    /**
     * Calculates discount based on various factors
     * Demonstrates business logic calculations
     */
    function calculateDiscount(basePrice: Float, customerType: String, quantity: Int): Dynamic {
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
    function calculateCompoundInterest(principal: Float, rate: Float, time: Int, compound: Int = 1): Dynamic {
        if (principal <= 0 || rate <= 0 || time <= 0 || compound <= 0) {
            return {error: "Invalid parameters for compound interest calculation"};
        }
        
        var rateDecimal = rate / 100.0;
        var amount = principal * Math.pow(1 + (rateDecimal / compound), compound * time);
        var interest = amount - principal;
        
        return {
            principal: principal,
            rate: rate,
            time: time,
            compound: compound,
            amount: Math.round(amount * 100) / 100,
            interest: Math.round(interest * 100) / 100
        };
    }
    
    /**
     * Validates numerical input and provides error information
     */
    function validateNumber(input: Dynamic): Dynamic {
        if (input == null) {
            return {valid: false, error: "Input is null"};
        }
        
        // Try to convert to number
        var number: Float;
        try {
            number = Std.parseFloat(Std.string(input));
        } catch (e: Dynamic) {
            return {valid: false, error: "Cannot convert to number"};
        }
        
        if (Math.isNaN(number)) {
            return {valid: false, error: "Input is not a valid number"};
        }
        
        if (!Math.isFinite(number)) {
            return {valid: false, error: "Input is not finite"};
        }
        
        return {
            valid: true,
            number: number,
            isInteger: number == Math.floor(number),
            isPositive: number > 0,
            isNegative: number < 0,
            absoluteValue: Math.abs(number)
        };
    }
    
    /**
     * Performs statistical calculations on an array of numbers
     */
    function calculateStats(numbers: Array<Float>): Dynamic {
        if (numbers == null || numbers.length == 0) {
            return {error: "Empty or null array provided"};
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
        
        return {
            count: numbers.length,
            sum: sum,
            mean: mean,
            median: median,
            min: min,
            max: max,
            range: max - min
        };
    }
    
    // Private helper functions
    
    @:private
    function multiplyByFactor(value: Float, factor: Float): Float {
        return value * factor;
    }
    
    @:private
    function addOffset(value: Float, offset: Float): Float {
        return value + offset;
    }
    
    @:private
    function applyBounds(value: Float, min: Float, max: Float): Float {
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
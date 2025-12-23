package utils;

using StringTools;
import haxe.functional.Result;

typedef UserInput = {
    var name: String;
    var email: String;
    var ?age: Int;
}

typedef SanitizedUserInput = {
    var name: String;
    var email: String;
    var ?age: Int;
}

typedef EmailValidation = {
    var email: String;
    var domain: String;
}

enum AgeCategory {
    Child;
    Teenager;
    Adult;
    Senior;
}

typedef AgeValidation = {
    var age: Int;
    var category: AgeCategory;
}

typedef PasswordStrength = {
    var score: Int;
    var hasLowercase: Bool;
    var hasUppercase: Bool;
    var hasNumbers: Bool;
    var hasSpecialChars: Bool;
    var length: Int;
}

typedef UrlValidation = {
    var url: String;
    var protocol: String;
    var domain: String;
}

/**
 * ValidationHelper - Input validation utilities for Mix project
 * 
 * This module provides comprehensive validation functions that can be
 * used throughout a Mix project for data integrity and security.
 */
@:module
class ValidationHelper {
    
    /**
     * Validates user input data comprehensively
     * Returns validation result with detailed error information
     */
    public static function validateUserInput(data: UserInput): Result<SanitizedUserInput, Array<String>> {
        var errors: Array<String> = [];
        
        // Validate name
        if (data.name.trim().length == 0) {
            errors.push("Name is required");
        } else if (data.name.trim().length < 2) {
            errors.push("Name must be at least 2 characters");
        } else if (data.name.trim().length > 50) {
            errors.push("Name must not exceed 50 characters");
        }
        
        // Validate email
        var validatedEmail: Null<EmailValidation> = null;
        switch (validateEmail(data.email)) {
            case Ok(result):
                validatedEmail = result;
            case Error(reason):
                errors.push("Email: " + reason);
        }
        
        // Validate age if provided
        if (data.age != null) {
            switch (validateAge(data.age)) {
                case Ok(_):
                case Error(reason):
                    errors.push("Age: " + reason);
            }
        }

        if (errors.length > 0 || validatedEmail == null) {
            return Error(errors);
        }

        return Ok({
            name: sanitizeText(data.name),
            email: validatedEmail.email,
            age: data.age
        });
    }
    
    /**
     * Validates email address format and domain
     */
    public static function validateEmail(email: String): Result<EmailValidation, String> {
        var emailStr = email.trim();

        if (emailStr.length == 0) {
            return Error("Email is required");
        }
        
        if (emailStr.length > 254) {
            return Error("Email is too long");
        }
        
        // Basic format validation
        if (!isValidEmailFormat(emailStr)) {
            return Error("Invalid email format");
        }
        
        // Check for valid domain
        var domain = extractDomain(emailStr);
        if (!isValidDomain(domain)) {
            return Error("Invalid email domain");
        }
        
        return Ok({
            email: emailStr.toLowerCase(),
            domain: domain
        });
    }
    
    /**
     * Validates age input
     */
    public static function validateAge(age: Int): Result<AgeValidation, String> {
        if (age < 0) {
            return Error("Age cannot be negative");
        }
        
        if (age > 150) {
            return Error("Age seems unrealistic");
        }
        
        return Ok({
            age: age,
            category: categorizeAge(age)
        });
    }
    
    /**
     * Validates password strength
     */
    public static function validatePassword(password: String): Result<PasswordStrength, Array<String>> {
        if (password.length < 8) {
            return Error(["Password must be at least 8 characters"]);
        }
        
        var strength = calculatePasswordStrength(password);
        var errors: Array<String> = [];
        
        if (strength.score < 3) {
            if (!strength.hasLowercase) errors.push("Must contain lowercase letters");
            if (!strength.hasUppercase) errors.push("Must contain uppercase letters");
            if (!strength.hasNumbers) errors.push("Must contain numbers");
            if (!strength.hasSpecialChars) errors.push("Must contain special characters");
        }

        if (errors.length > 0) {
            return Error(errors);
        }

        return Ok(strength);
    }
    
    /**
     * Validates and sanitizes text input
     */
    public static function validateAndSanitizeText(text: Null<String>, minLength: Int = 0, maxLength: Int = 1000): Result<String, String> {
        if (text == null) {
            return minLength == 0 ? Ok("") : Error("Text is required");
        }
        
        var sanitized = sanitizeText(text);
        
        if (sanitized.length < minLength) {
            return Error("Text must be at least " + minLength + " characters");
        }
        
        if (sanitized.length > maxLength) {
            return Error("Text must not exceed " + maxLength + " characters");
        }
        
        return Ok(sanitized);
    }
    
    /**
     * Validates URL format
     */
    public static function validateUrl(url: String): Result<UrlValidation, String> {
        if (url.trim().length == 0) {
            return Error("URL is required");
        }
        
        var trimmed = url.trim();
        
        // Basic URL validation
        if (!isValidUrlFormat(trimmed)) {
            return Error("Invalid URL format");
        }
        
        return Ok({
            url: trimmed,
            protocol: extractProtocol(trimmed),
            domain: extractUrlDomain(trimmed)
        });
    }
    
    // Private helper functions
    
    @:private
    static function isValidEmailFormat(email: String): Bool {
        // Basic email regex pattern
        var pattern = new EReg("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", "");
        return pattern.match(email);
    }
    
    @:private
    static function extractDomain(email: String): String {
        var atIndex = email.indexOf("@");
        return atIndex > 0 ? email.substr(atIndex + 1) : "";
    }
    
    @:private
    static function isValidDomain(domain: String): Bool {
        if (domain.length < 4) return false; // Minimum: a.co
        if (domain.indexOf(".") == -1) return false;
        return true;
    }
    
    @:private
    static function categorizeAge(age: Int): AgeCategory {
        if (age < 13) return Child;
        if (age < 20) return Teenager;
        if (age < 65) return Adult;
        return Senior;
    }
    
    @:private
    static function calculatePasswordStrength(password: String): PasswordStrength {
        var hasLowercase = new EReg("[a-z]", "").match(password);
        var hasUppercase = new EReg("[A-Z]", "").match(password);
        var hasNumbers = new EReg("[0-9]", "").match(password);
        var hasSpecialChars = new EReg("[^a-zA-Z0-9]", "").match(password);
        
        var score = 0;
        if (password.length >= 8) score++;
        if (hasLowercase) score++;
        if (hasUppercase) score++;
        if (hasNumbers) score++;
        if (hasSpecialChars) score++;
        
        return {
            score: score,
            hasLowercase: hasLowercase,
            hasUppercase: hasUppercase,
            hasNumbers: hasNumbers,
            hasSpecialChars: hasSpecialChars,
            length: password.length
        };
    }
    
    @:private
    static function sanitizeText(text: String): String {
        // Basic text sanitization - remove potentially dangerous characters
        var sanitized = text.trim();
        sanitized = StringTools.replace(sanitized, "<", "&lt;");
        sanitized = StringTools.replace(sanitized, ">", "&gt;");
        sanitized = StringTools.replace(sanitized, "\"", "&quot;");
        sanitized = StringTools.replace(sanitized, "'", "&#39;");
        return sanitized;
    }
    
    @:private
    @:private
    static function isValidUrlFormat(url: String): Bool {
        var pattern = new EReg("^https?://[^\\s/$.?#].[^\\s]*$", "i");
        return pattern.match(url);
    }
    
    @:private
    static function extractProtocol(url: String): String {
        var colonIndex = url.indexOf("://");
        return colonIndex > 0 ? url.substr(0, colonIndex) : "";
    }
    
    @:private
    static function extractUrlDomain(url: String): String {
        var protocolEnd = url.indexOf("://") + 3;
        var pathStart = url.indexOf("/", protocolEnd);
        var domain = pathStart > 0 ? url.substr(protocolEnd, pathStart - protocolEnd) : url.substr(protocolEnd);
        return domain;
    }
    
    /**
     * Main function for compilation testing
     */
    public static function main(): Void {
        trace("ValidationHelper compiled successfully for Mix project!");
    }
}

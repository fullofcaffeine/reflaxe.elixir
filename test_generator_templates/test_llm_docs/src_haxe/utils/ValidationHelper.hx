package utils;

using StringTools;

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
    public static function validateUserInput(data: Dynamic): Dynamic {
        var errors = [];
        
        // Validate name
        if (data.name == null || data.name.trim().length == 0) {
            errors.push("Name is required");
        } else if (data.name.trim().length < 2) {
            errors.push("Name must be at least 2 characters");
        } else if (data.name.trim().length > 50) {
            errors.push("Name must not exceed 50 characters");
        }
        
        // Validate email
        var emailResult = validateEmail(data.email);
        if (!emailResult.valid) {
            errors.push("Email: " + emailResult.error);
        }
        
        // Validate age if provided
        if (data.age != null) {
            var ageResult = validateAge(data.age);
            if (!ageResult.valid) {
                errors.push("Age: " + ageResult.error);
            }
        }
        
        return {
            valid: errors.length == 0,
            errors: errors,
            data: errors.length == 0 ? sanitizeUserData(data) : null
        };
    }
    
    /**
     * Validates email address format and domain
     */
    public static function validateEmail(email: Dynamic): Dynamic {
        if (email == null) {
            return {valid: false, error: "Email is required"};
        }
        
        var emailStr = Std.string(email).trim();
        
        if (emailStr.length == 0) {
            return {valid: false, error: "Email cannot be empty"};
        }
        
        if (emailStr.length > 254) {
            return {valid: false, error: "Email is too long"};
        }
        
        // Basic format validation
        if (!isValidEmailFormat(emailStr)) {
            return {valid: false, error: "Invalid email format"};
        }
        
        // Check for valid domain
        var domain = extractDomain(emailStr);
        if (!isValidDomain(domain)) {
            return {valid: false, error: "Invalid email domain"};
        }
        
        return {
            valid: true,
            email: emailStr.toLowerCase(),
            domain: domain
        };
    }
    
    /**
     * Validates age input
     */
    public static function validateAge(age: Dynamic): Dynamic {
        if (age == null) {
            return {valid: false, error: "Age is required"};
        }
        
        var ageNum: Null<Int>;
        try {
            ageNum = Std.parseInt(Std.string(age));
            if (ageNum == null) throw "Invalid number";
        } catch (e: Dynamic) {
            return {valid: false, error: "Age must be a valid number"};
        }
        
        if (ageNum < 0) {
            return {valid: false, error: "Age cannot be negative"};
        }
        
        if (ageNum > 150) {
            return {valid: false, error: "Age seems unrealistic"};
        }
        
        return {
            valid: true,
            age: ageNum,
            category: categorizeAge(ageNum)
        };
    }
    
    /**
     * Validates password strength
     */
    public static function validatePassword(password: String): Dynamic {
        if (password == null) {
            return {valid: false, error: "Password is required", strength: 0};
        }
        
        if (password.length < 8) {
            return {valid: false, error: "Password must be at least 8 characters", strength: 1};
        }
        
        var strength = calculatePasswordStrength(password);
        var errors = [];
        
        if (strength.score < 3) {
            if (!strength.hasLowercase) errors.push("Must contain lowercase letters");
            if (!strength.hasUppercase) errors.push("Must contain uppercase letters");
            if (!strength.hasNumbers) errors.push("Must contain numbers");
            if (!strength.hasSpecialChars) errors.push("Must contain special characters");
        }
        
        return {
            valid: strength.score >= 3,
            error: errors.length > 0 ? errors.join(", ") : null,
            strength: strength.score,
            details: strength
        };
    }
    
    /**
     * Validates and sanitizes text input
     */
    public static function validateAndSanitizeText(text: String, minLength: Int = 0, maxLength: Int = 1000): Dynamic {
        if (text == null) {
            return {
                valid: minLength == 0,
                error: minLength > 0 ? "Text is required" : null,
                sanitized: ""
            };
        }
        
        var sanitized = sanitizeText(text);
        
        if (sanitized.length < minLength) {
            return {
                valid: false,
                error: "Text must be at least " + minLength + " characters",
                sanitized: sanitized
            };
        }
        
        if (sanitized.length > maxLength) {
            return {
                valid: false,
                error: "Text must not exceed " + maxLength + " characters",
                sanitized: sanitized
            };
        }
        
        return {
            valid: true,
            error: null,
            sanitized: sanitized
        };
    }
    
    /**
     * Validates URL format
     */
    public static function validateUrl(url: String): Dynamic {
        if (url == null || url.trim().length == 0) {
            return {valid: false, error: "URL is required"};
        }
        
        var trimmed = url.trim();
        
        // Basic URL validation
        if (!isValidUrlFormat(trimmed)) {
            return {valid: false, error: "Invalid URL format"};
        }
        
        return {
            valid: true,
            url: trimmed,
            protocol: extractProtocol(trimmed),
            domain: extractUrlDomain(trimmed)
        };
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
    static function categorizeAge(age: Int): String {
        if (age < 13) return "child";
        if (age < 20) return "teenager";
        if (age < 65) return "adult";
        return "senior";
    }
    
    @:private
    static function calculatePasswordStrength(password: String): Dynamic {
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
    static function sanitizeUserData(data: Dynamic): Dynamic {
        return {
            name: data.name != null ? sanitizeText(Std.string(data.name)) : null,
            email: data.email != null ? Std.string(data.email).trim().toLowerCase() : null,
            age: data.age
        };
    }
    
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
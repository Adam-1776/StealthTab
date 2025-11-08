//
//  Utils.swift
//  StealthTab
//
//  General utilities for the browser
//

import Foundation

struct Utils {
    
    // MARK: - URL Processing
    
    /// Process user input and return a valid URL string
    /// - Parameter input: User input from the URL bar
    /// - Returns: A properly formatted URL string or search URL
    static func processInput(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        
        // If already has protocol, use as-is
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return trimmed
        }
        
        // Check if it's a URL or search query
        if isLikelyURL(trimmed) {
            return "https://" + trimmed
        } else {
            return constructSearchURL(query: trimmed)
        }
    }
    
    /// Determine if input string is likely a URL or a search query
    /// - Parameter input: The string to analyze
    /// - Returns: True if input appears to be a URL, false if it's likely a search query
    static func isLikelyURL(_ input: String) -> Bool {
        // Contains spaces -> definitely a search query
        if input.contains(" ") {
            return false
        }
        
        // localhost or IP address patterns
        if input.hasPrefix("localhost") || 
           input.hasPrefix("127.0.0.1") ||
           isIPAddress(input) {
            return true
        }
        
        // Check for common TLDs
        if hasCommonTLD(input) {
            return true
        }
        
        // Check for domain pattern (word.word)
        if matchesDomainPattern(input) {
            return true
        }
        
        return false
    }
    
    // MARK: - Private Helpers
    
    /// Check if string has a common top-level domain
    private static func hasCommonTLD(_ input: String) -> Bool {
        let commonTLDs = [
            ".com", ".org", ".net", ".edu", ".gov", ".mil",
            ".co", ".uk", ".us", ".ca", ".au", ".de", ".fr",
            ".io", ".ai", ".app", ".dev", ".tech", ".info",
            ".biz", ".tv", ".me", ".xyz", ".online", ".store",
            ".jp", ".cn", ".in", ".br", ".ru", ".it", ".es"
        ]
        
        let lowercased = input.lowercased()
        for tld in commonTLDs {
            if lowercased.hasSuffix(tld) || 
               lowercased.contains(tld + "/") || 
               lowercased.contains(tld + ":") {
                return true
            }
        }
        
        return false
    }
    
    /// Check if string matches domain pattern using regex
    private static func matchesDomainPattern(_ input: String) -> Bool {
        let domainPattern = #"^[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)+(/.*)?$"#
        
        guard let regex = try? NSRegularExpression(pattern: domainPattern) else {
            return false
        }
        
        let range = NSRange(input.startIndex..., in: input)
        return regex.firstMatch(in: input, range: range) != nil
    }
    
    /// Check if string is an IP address
    private static func isIPAddress(_ input: String) -> Bool {
        // Simple IPv4 pattern check
        let components = input.components(separatedBy: ":")
        let ipPart = components[0]
        let octets = ipPart.components(separatedBy: ".")
        
        guard octets.count == 4 else { return false }
        
        return octets.allSatisfy { octet in
            guard let number = Int(octet) else { return false }
            return number >= 0 && number <= 255
        }
    }
    
    /// Construct a search URL from a query string
    private static func constructSearchURL(query: String) -> String {
        let searchQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return BrowserConfig.searchEngineURL + searchQuery
    }
}


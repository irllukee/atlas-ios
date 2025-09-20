import Foundation
import SwiftUI

class RecipeImportService: ObservableObject {
    private let recipesService: RecipesService
    
    init(recipesService: RecipesService) {
        self.recipesService = recipesService
    }
    
    // MARK: - URL Import
    
    func importRecipeFromURL(_ urlString: String) async -> RecipeImportResult {
        guard let url = URL(string: urlString), url.host != nil else {
            return .failure("Invalid URL format")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return .failure("Failed to fetch URL content")
            }
            
            guard let htmlContent = String(data: data, encoding: .utf8) else {
                return .failure("Unable to parse webpage content")
            }
            
            return parseHTMLContent(htmlContent, sourceURL: urlString)
            
        } catch {
            return .failure("Network error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Manual Text Import
    
    func importRecipeFromText(_ text: String, sourceURL: String? = nil) -> RecipeImportResult {
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            return .failure("No content found in text")
        }
        
        return parseTextContent(lines, sourceURL: sourceURL)
    }
    
    // MARK: - HTML Parsing
    
    private func parseHTMLContent(_ html: String, sourceURL: String) -> RecipeImportResult {
        // Try to find structured data (JSON-LD)
        if let jsonLD = extractJSONLD(from: html) {
            return parseJSONLDRecipe(jsonLD, sourceURL: sourceURL)
        }
        
        // Try to find microdata
        if let microdata = extractMicrodata(from: html) {
            return parseMicrodataRecipe(microdata, sourceURL: sourceURL)
        }
        
        // Fallback to text parsing
        let textContent = extractTextFromHTML(html)
        let lines = textContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
        return parseTextContent(lines, sourceURL: sourceURL)
    }
    
    private func extractJSONLD(from html: String) -> [String: Any]? {
        let pattern = #"<script[^>]*type=["']application/ld\+json["'][^>]*>(.*?)</script>"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        
        guard let regex = regex else { return nil }
        
        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, range: range)
        
        for match in matches {
            let jsonRange = match.range(at: 1)
            if let swiftRange = Range(jsonRange, in: html) {
                let jsonString = String(html[swiftRange])
                if let data = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    return json
                }
            }
        }
        
        return nil
    }
    
    private func extractMicrodata(from html: String) -> [String: String]? {
        // Simplified microdata extraction
        let patterns = [
            "itemprop=\"name\"": #"itemprop="name"[^>]*>([^<]+)"#,
            "itemprop=\"description\"": #"itemprop="description"[^>]*>([^<]+)"#,
            "itemprop=\"prepTime\"": #"itemprop="prepTime"[^>]*>([^<]+)"#,
            "itemprop=\"cookTime\"": #"itemprop="cookTime"[^>]*>([^<]+)"#,
            "itemprop=\"recipeYield\"": #"itemprop="recipeYield"[^>]*>([^<]+)"#
        ]
        
        var microdata: [String: String] = [:]
        
        for (_, pattern) in patterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            if let regex = regex {
                let range = NSRange(html.startIndex..., in: html)
                if let match = regex.firstMatch(in: html, range: range),
                   let swiftRange = Range(match.range(at: 1), in: html) {
                    let value = String(html[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !value.isEmpty {
                        microdata[pattern] = value
                    }
                }
            }
        }
        
        return microdata.isEmpty ? nil : microdata
    }
    
    private func extractTextFromHTML(_ html: String) -> String {
        // Remove HTML tags and decode entities
        let htmlWithoutTags = html.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
        let decoded = htmlWithoutTags
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
        
        return decoded
    }
    
    // MARK: - JSON-LD Parsing
    
    private func parseJSONLDRecipe(_ json: [String: Any], sourceURL: String) -> RecipeImportResult {
        guard let type = json["@type"] as? String,
              type.contains("Recipe") else {
            return .failure("No recipe data found in structured format")
        }
        
        let title = json["name"] as? String ?? "Imported Recipe"
        let description = json["description"] as? String
        let prepTime = parseDuration(json["prepTime"] as? String)
        let cookTime = parseDuration(json["cookTime"] as? String)
        let servings = parseServings(json["recipeYield"] as? Any)
        
        var ingredients: [String] = []
        if let ingredientList = json["recipeIngredient"] as? [String] {
            ingredients = ingredientList
        }
        
        var instructions: [String] = []
        if let instructionList = json["recipeInstructions"] as? [[String: Any]] {
            instructions = instructionList.compactMap { $0["text"] as? String }
        } else if let instructionText = json["recipeInstructions"] as? String {
            instructions = [instructionText]
        }
        
        return createRecipeFromParsedData(
            title: title,
            recipeDescription: description,
            prepTime: prepTime,
            cookTime: cookTime,
            servings: servings,
            ingredients: ingredients,
            instructions: instructions,
            sourceURL: sourceURL
        )
    }
    
    private func parseMicrodataRecipe(_ microdata: [String: String], sourceURL: String) -> RecipeImportResult {
        let title = microdata["name"] ?? "Imported Recipe"
        let description = microdata["description"]
        let prepTime = parseDuration(microdata["prepTime"])
        let cookTime = parseDuration(microdata["cookTime"])
        let servings = parseServings(microdata["recipeYield"])
        
        // For microdata, we'll need to extract ingredients and instructions from the HTML
        // This is a simplified implementation
        return createRecipeFromParsedData(
            title: title,
            recipeDescription: description,
            prepTime: prepTime,
            cookTime: cookTime,
            servings: servings,
            ingredients: [],
            instructions: [],
            sourceURL: sourceURL
        )
    }
    
    // MARK: - Text Parsing
    
    private func parseTextContent(_ lines: [String], sourceURL: String?) -> RecipeImportResult {
        var title = "Imported Recipe"
        var description: String?
        var ingredients: [String] = []
        var instructions: [String] = []
        var prepTime = 0
        var cookTime = 0
        var servings = 1
        
        var currentSection = ""
        
        for line in lines {
            let lowercasedLine = line.lowercased()
            
            // Detect sections
            if lowercasedLine.contains("ingredients") || lowercasedLine.contains("ingredient") {
                currentSection = "ingredients"
                continue
            } else if lowercasedLine.contains("instructions") || lowercasedLine.contains("directions") || lowercasedLine.contains("method") {
                currentSection = "instructions"
                continue
            } else if lowercasedLine.contains("prep") || lowercasedLine.contains("preparation") {
                currentSection = "prep"
                continue
            } else if lowercasedLine.contains("cook") || lowercasedLine.contains("cooking") {
                currentSection = "cook"
                continue
            }
            
            // Parse content based on current section
            switch currentSection {
            case "ingredients":
                if !line.isEmpty && !lowercasedLine.contains("ingredients") {
                    ingredients.append(line)
                }
            case "instructions":
                if !line.isEmpty && !lowercasedLine.contains("instructions") && !lowercasedLine.contains("directions") {
                    instructions.append(line)
                }
            case "prep":
                prepTime = extractMinutes(from: line)
            case "cook":
                cookTime = extractMinutes(from: line)
            default:
                // First non-empty line is likely the title
                if title == "Imported Recipe" && !line.isEmpty {
                    title = line
                } else if description == nil && !line.isEmpty && !lowercasedLine.contains("ingredients") && !lowercasedLine.contains("instructions") {
                    description = line
                }
                
                // Try to extract timing and serving info from any line
                if lowercasedLine.contains("serves") || lowercasedLine.contains("servings") {
                    servings = extractServings(from: line)
                }
            }
        }
        
        return createRecipeFromParsedData(
            title: title,
            recipeDescription: description,
            prepTime: prepTime,
            cookTime: cookTime,
            servings: servings,
            ingredients: ingredients,
            instructions: instructions,
            sourceURL: sourceURL
        )
    }
    
    // MARK: - Helper Methods
    
    private func createRecipeFromParsedData(
        title: String,
        recipeDescription: String?,
        prepTime: Int,
        cookTime: Int,
        servings: Int,
        ingredients: [String],
        instructions: [String],
        sourceURL: String?
    ) -> RecipeImportResult {
        let categories = recipesService.fetchCategories()
        let category = categories.first { $0.name?.lowercased() == "dinner" } ?? categories.first ?? RecipeCategory()
        
        let recipe = recipesService.createRecipe(
            title: title,
            recipeDescription: recipeDescription,
            category: category,
            prepTime: Int16(prepTime),
            cookingTime: Int16(cookTime),
            servings: Int16(servings),
            difficulty: 3, // Default to medium
            sourceURL: sourceURL
        )
        
        // Add ingredients
        for (index, ingredientText) in ingredients.enumerated() {
            let (name, amount, unit) = parseIngredientText(ingredientText)
            _ = recipesService.addIngredient(
                to: recipe,
                name: name,
                amount: amount,
                unit: unit,
                order: Int16(index)
            )
        }
        
        // Add instructions
        for (index, instructionText) in instructions.enumerated() {
            _ = recipesService.addStep(
                to: recipe,
                content: instructionText,
                order: Int16(index)
            )
        }
        
        return .success(recipe)
    }
    
    private func parseIngredientText(_ text: String) -> (name: String, amount: Double, unit: String?) {
        let words = text.components(separatedBy: .whitespaces)
        var name = ""
        var amount = 0.0
        var unit: String?
        
        // Common units
        let units = ["cup", "cups", "tbsp", "tbsp", "tsp", "tsp", "oz", "lb", "g", "kg", "ml", "l", "pieces", "cloves", "slices"]
        
        for (_, word) in words.enumerated() {
            // Try to parse amount
            if let parsedAmount = Double(word.replacingOccurrences(of: "/", with: ".")) {
                amount = parsedAmount
                continue
            }
            
            // Check if it's a unit
            if units.contains(word.lowercased()) {
                unit = word
                continue
            }
            
            // Everything else is part of the ingredient name
            name += (name.isEmpty ? "" : " ") + word
        }
        
        return (name.isEmpty ? text : name, amount, unit)
    }
    
    private func parseDuration(_ durationString: String?) -> Int {
        guard let duration = durationString else { return 0 }
        
        // Parse ISO 8601 duration format (PT15M, PT1H30M, etc.)
        if duration.hasPrefix("PT") {
            let timeString = String(duration.dropFirst(2))
            var totalMinutes = 0
            
            if let hoursRange = timeString.range(of: "H") {
                let hoursString = String(timeString[..<hoursRange.lowerBound])
                if let hours = Int(hoursString) {
                    totalMinutes += hours * 60
                }
            }
            
            if let minutesRange = timeString.range(of: "M") {
                let minutesString = String(timeString[..<minutesRange.lowerBound])
                if let minutes = Int(minutesString) {
                    totalMinutes += minutes
                }
            }
            
            return totalMinutes
        }
        
        // Parse simple formats like "15 minutes", "1 hour", "1h 30m"
        return extractMinutes(from: duration)
    }
    
    private func extractMinutes(from text: String) -> Int {
        let lowercasedText = text.lowercased()
        var totalMinutes = 0
        
        // Extract hours
        if let hoursRange = lowercasedText.range(of: "hour") {
            let beforeHour = String(lowercasedText[..<hoursRange.lowerBound])
            if let hours = Int(beforeHour.components(separatedBy: .whitespaces).last ?? "") {
                totalMinutes += hours * 60
            }
        } else if let hoursRange = lowercasedText.range(of: "h") {
            let beforeHour = String(lowercasedText[..<hoursRange.lowerBound])
            if let hours = Int(beforeHour.components(separatedBy: .whitespaces).last ?? "") {
                totalMinutes += hours * 60
            }
        }
        
        // Extract minutes
        if let minutesRange = lowercasedText.range(of: "minute") {
            let beforeMinute = String(lowercasedText[..<minutesRange.lowerBound])
            if let minutes = Int(beforeMinute.components(separatedBy: .whitespaces).last ?? "") {
                totalMinutes += minutes
            }
        } else if let minutesRange = lowercasedText.range(of: "m") {
            let beforeMinute = String(lowercasedText[..<minutesRange.lowerBound])
            if let minutes = Int(beforeMinute.components(separatedBy: .whitespaces).last ?? "") {
                totalMinutes += minutes
            }
        }
        
        return totalMinutes
    }
    
    private func parseServings(_ servingsData: Any?) -> Int {
        if let servingsString = servingsData as? String {
            return extractServings(from: servingsString)
        } else if let servingsInt = servingsData as? Int {
            return servingsInt
        }
        return 1
    }
    
    private func extractServings(from text: String) -> Int {
        let numbers = text.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
        return numbers.first ?? 1
    }
}

// MARK: - Recipe Import Result

enum RecipeImportResult {
    case success(Recipe)
    case failure(String)
    
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    var recipe: Recipe? {
        if case .success(let recipe) = self { return recipe }
        return nil
    }
    
    var errorMessage: String? {
        if case .failure(let message) = self { return message }
        return nil
    }
}


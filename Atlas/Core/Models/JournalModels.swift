import Foundation

// MARK: - Journal Entry Types
enum JournalEntryType: String, CaseIterable {
    case daily = "daily"
    case dream = "dream"
    case gratitude = "gratitude"
    case reflection = "reflection"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily Journal"
        case .dream: return "Dream Journal"
        case .gratitude: return "Gratitude Journal"
        case .reflection: return "Reflection Journal"
        }
    }
    
    var emoji: String {
        switch self {
        case .daily: return "📝"
        case .dream: return "🌙"
        case .gratitude: return "🙏"
        case .reflection: return "🤔"
        }
    }
    
    var color: String {
        switch self {
        case .daily: return "blue"
        case .dream: return "purple"
        case .gratitude: return "green"
        case .reflection: return "orange"
        }
    }
}

// MARK: - Mood Scale
enum MoodScale: String, CaseIterable {
    case fivePoint = "5-point"
    case tenPoint = "10-point"
    
    var range: ClosedRange<Int> {
        switch self {
        case .fivePoint: return 1...5
        case .tenPoint: return 1...10
        }
    }
    
    func emoji(for level: Int) -> String {
        switch self {
        case .fivePoint:
            switch level {
            case 1: return "😢"
            case 2: return "😕"
            case 3: return "😐"
            case 4: return "😊"
            case 5: return "😍"
            default: return "😐"
            }
        case .tenPoint:
            switch level {
            case 1...2: return "😢"
            case 3...4: return "😕"
            case 5...6: return "😐"
            case 7...8: return "😊"
            case 9...10: return "😍"
            default: return "😐"
            }
        }
    }
    
    func description(for level: Int) -> String {
        switch self {
        case .fivePoint:
            switch level {
            case 1: return "Very Low"
            case 2: return "Low"
            case 3: return "Neutral"
            case 4: return "Good"
            case 5: return "Excellent"
            default: return "Unknown"
            }
        case .tenPoint:
            switch level {
            case 1: return "Terrible"
            case 2: return "Very Bad"
            case 3: return "Bad"
            case 4: return "Poor"
            case 5: return "Below Average"
            case 6: return "Average"
            case 7: return "Good"
            case 8: return "Very Good"
            case 9: return "Great"
            case 10: return "Perfect"
            default: return "Unknown"
            }
        }
    }
}

// MARK: - Built-in Templates
extension JournalTemplate {
    static var builtInTemplates: [JournalTemplateData] {
        [
            // Daily Journal Templates
            JournalTemplateData(
                name: "Daily Reflection",
                type: .daily,
                content: """
                **Today's Date:** \(Date().formatted(date: .complete, time: .omitted))
                
                **How was my day overall?**
                
                
                **What went well today?**
                
                
                **What could have been better?**
                
                
                **What did I learn today?**
                
                
                **Tomorrow I want to focus on:**
                
                """
            ),
            
            // Dream Journal Template
            JournalTemplateData(
                name: "Dream Journal",
                type: .dream,
                content: """
                **Dream Date:** \(Date().formatted(date: .complete, time: .omitted))
                
                **Dream Summary:**
                
                
                **Key Characters/People:**
                
                
                **Setting/Location:**
                
                
                **Emotions Felt:**
                
                
                **Possible Meaning/Interpretation:**
                
                
                **Recurring Themes:**
                
                """
            ),
            
            // Gratitude Template
            JournalTemplateData(
                name: "Gratitude Practice",
                type: .gratitude,
                content: """
                **Today I am grateful for:**
                
                1. 
                2. 
                3. 
                
                **Someone who made my day better:**
                
                
                **A small moment that brought me joy:**
                
                
                **What I appreciate about myself today:**
                
                
                **Looking forward to:**
                
                """
            ),
            
            // Reflection Template
            JournalTemplateData(
                name: "Deep Reflection",
                type: .reflection,
                content: """
                **What's on my mind today?**
                
                
                **What patterns am I noticing in my life?**
                
                
                **What challenges am I facing?**
                
                
                **How am I growing?**
                
                
                **What do I need more of in my life?**
                
                
                **What am I ready to let go of?**
                
                """
            )
        ]
    }
}

struct JournalTemplateData {
    let name: String
    let type: JournalEntryType
    let content: String
}

// MARK: - Built-in Prompts
extension JournalPrompt {
    struct BuiltInPrompt {
        let text: String
        let type: JournalEntryType
    }
    
    static var builtInPrompts: [BuiltInPrompt] {
        return [
            // Daily Journal Prompts
            BuiltInPrompt(text: "What made me smile today?", type: .daily),
            BuiltInPrompt(text: "What was the highlight of my day?", type: .daily),
            BuiltInPrompt(text: "What challenged me today and how did I handle it?", type: .daily),
            BuiltInPrompt(text: "What did I accomplish today that I'm proud of?", type: .daily),
            BuiltInPrompt(text: "How did I take care of myself today?", type: .daily),
            BuiltInPrompt(text: "What would I do differently if I could relive today?", type: .daily),
            BuiltInPrompt(text: "What am I looking forward to tomorrow?", type: .daily),
            
            // Dream Journal Prompts
            BuiltInPrompt(text: "What emotions did I feel most strongly in this dream?", type: .dream),
            BuiltInPrompt(text: "Were there any recurring symbols or themes?", type: .dream),
            BuiltInPrompt(text: "How did the dream make me feel when I woke up?", type: .dream),
            BuiltInPrompt(text: "Does this dream remind me of anything from my waking life?", type: .dream),
            BuiltInPrompt(text: "What was the most vivid part of the dream?", type: .dream),
            BuiltInPrompt(text: "If I could ask a character from my dream one question, what would it be?", type: .dream),
            
            // Gratitude Prompts
            BuiltInPrompt(text: "What small thing am I grateful for that I usually take for granted?", type: .gratitude),
            BuiltInPrompt(text: "Who in my life am I most grateful for and why?", type: .gratitude),
            BuiltInPrompt(text: "What ability or skill of mine am I thankful for?", type: .gratitude),
            BuiltInPrompt(text: "What made me feel loved or appreciated recently?", type: .gratitude),
            BuiltInPrompt(text: "What aspect of nature am I grateful for today?", type: .gratitude),
            BuiltInPrompt(text: "What lesson from a difficult experience am I now grateful for?", type: .gratitude),
            BuiltInPrompt(text: "What comfort or luxury in my life do I appreciate?", type: .gratitude),
            
            // Reflection Prompts
            BuiltInPrompt(text: "What pattern in my thoughts or behavior am I noticing lately?", type: .reflection),
            BuiltInPrompt(text: "How have I grown in the past month?", type: .reflection),
            BuiltInPrompt(text: "What belief about myself is no longer serving me?", type: .reflection),
            BuiltInPrompt(text: "What would I tell my younger self if I could?", type: .reflection),
            BuiltInPrompt(text: "What am I avoiding and why?", type: .reflection),
            BuiltInPrompt(text: "How do I want to be remembered?", type: .reflection),
            BuiltInPrompt(text: "What gives my life meaning?", type: .reflection),
            BuiltInPrompt(text: "What boundary do I need to set for myself?", type: .reflection)
        ]
    }
}

// MARK: - Mood Timeframe
enum MoodTimeframe: String, CaseIterable {
    case week = "week"
    case month = "month"
    case year = "year"
    
    var displayName: String {
        switch self {
        case .week: return "This Week"
        case .month: return "This Month"
        case .year: return "This Year"
        }
    }
    
    var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .week:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
            return startOfWeek...endOfWeek
        case .month:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
            return startOfMonth...endOfMonth
        case .year:
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            let endOfYear = calendar.dateInterval(of: .year, for: now)?.end ?? now
            return startOfYear...endOfYear
        }
    }
}

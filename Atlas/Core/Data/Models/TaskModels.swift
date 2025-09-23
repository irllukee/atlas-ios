import Foundation
import SwiftUI

// MARK: - Task Statistics

struct TaskStatistics {
    let totalTasks: Int
    let completedTasks: Int
    let pendingTasks: Int
    let overdueTasks: Int
    let dueTodayTasks: Int
    let highPriorityTasks: Int
    
    var completionRate: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(completedTasks) / Double(totalTasks) * 100
    }
}

// MARK: - Task Templates

struct TaskTemplate {
    let id: UUID = UUID()
    let name: String
    let description: String
    let tasks: [TaskTemplateItem]
    let category: String
    let icon: String
}

struct TaskTemplateItem {
    let title: String
    let notes: String?
    let priority: TaskPriority
    let estimatedDuration: TimeInterval?
}

class TaskTemplateService {
    static let templates: [TaskTemplate] = [
        TaskTemplate(
            name: "Daily Standup",
            description: "Team meeting preparation",
            tasks: [
                TaskTemplateItem(title: "Review yesterday's progress", notes: "Check completed tasks and blockers", priority: .medium, estimatedDuration: 300),
                TaskTemplateItem(title: "Plan today's priorities", notes: "Identify top 3 tasks for today", priority: .high, estimatedDuration: 300),
                TaskTemplateItem(title: "Prepare standup notes", notes: "What did I do, what will I do, any blockers", priority: .medium, estimatedDuration: 600)
            ],
            category: "Work",
            icon: "person.3.fill"
        ),
        
        TaskTemplate(
            name: "Weekly Review",
            description: "Progress reflection",
            tasks: [
                TaskTemplateItem(title: "Review completed goals", notes: "Assess what was accomplished this week", priority: .medium, estimatedDuration: 900),
                TaskTemplateItem(title: "Identify lessons learned", notes: "What went well, what could be improved", priority: .medium, estimatedDuration: 600),
                TaskTemplateItem(title: "Plan next week's priorities", notes: "Set goals and priorities for upcoming week", priority: .high, estimatedDuration: 1200)
            ],
            category: "Personal",
            icon: "calendar.badge.clock"
        ),
        
        TaskTemplate(
            name: "Project Planning",
            description: "Project management",
            tasks: [
                TaskTemplateItem(title: "Define project scope", notes: "Clear objectives and deliverables", priority: .urgent, estimatedDuration: 1800),
                TaskTemplateItem(title: "Create timeline", notes: "Milestones and deadlines", priority: .high, estimatedDuration: 1200),
                TaskTemplateItem(title: "Identify resources needed", notes: "Team, tools, budget requirements", priority: .high, estimatedDuration: 900),
                TaskTemplateItem(title: "Risk assessment", notes: "Potential challenges and mitigation strategies", priority: .medium, estimatedDuration: 600)
            ],
            category: "Work",
            icon: "chart.bar.doc.horizontal"
        ),
        
        TaskTemplate(
            name: "Meeting Preparation",
            description: "Meeting organization",
            tasks: [
                TaskTemplateItem(title: "Create agenda", notes: "Key topics and time allocations", priority: .high, estimatedDuration: 600),
                TaskTemplateItem(title: "Send invitations", notes: "Include agenda and relevant documents", priority: .medium, estimatedDuration: 300),
                TaskTemplateItem(title: "Prepare materials", notes: "Slides, handouts, reports", priority: .medium, estimatedDuration: 900),
                TaskTemplateItem(title: "Book meeting room", notes: "Ensure AV equipment is available", priority: .low, estimatedDuration: 180)
            ],
            category: "Work",
            icon: "person.2.badge.gearshape"
        ),
        
        TaskTemplate(
            name: "Learning & Development",
            description: "Skill building",
            tasks: [
                TaskTemplateItem(title: "Choose learning topic", notes: "Select skill to develop", priority: .medium, estimatedDuration: 300),
                TaskTemplateItem(title: "Find learning resources", notes: "Books, courses, tutorials", priority: .medium, estimatedDuration: 600),
                TaskTemplateItem(title: "Create study schedule", notes: "Allocate regular time slots", priority: .high, estimatedDuration: 300),
                TaskTemplateItem(title: "Practice exercises", notes: "Apply what you've learned", priority: .high, estimatedDuration: 1800)
            ],
            category: "Personal",
            icon: "book.fill"
        ),
        
        TaskTemplate(
            name: "Health & Wellness",
            description: "Personal care",
            tasks: [
                TaskTemplateItem(title: "Schedule health checkup", notes: "Annual physical or specialist visit", priority: .medium, estimatedDuration: 300),
                TaskTemplateItem(title: "Plan workout routine", notes: "Exercise schedule for the week", priority: .medium, estimatedDuration: 600),
                TaskTemplateItem(title: "Meal prep planning", notes: "Healthy meals for the week", priority: .medium, estimatedDuration: 900),
                TaskTemplateItem(title: "Meditation session", notes: "Daily mindfulness practice", priority: .low, estimatedDuration: 1200)
            ],
            category: "Health",
            icon: "heart.fill"
        ),
        
        TaskTemplate(
            name: "Financial Review",
            description: "Money management",
            tasks: [
                TaskTemplateItem(title: "Review monthly expenses", notes: "Check bank statements and receipts", priority: .high, estimatedDuration: 1200),
                TaskTemplateItem(title: "Update budget", notes: "Adjust categories based on spending", priority: .medium, estimatedDuration: 900),
                TaskTemplateItem(title: "Review investments", notes: "Check portfolio performance", priority: .medium, estimatedDuration: 600),
                TaskTemplateItem(title: "Plan next month's budget", notes: "Set spending limits and goals", priority: .high, estimatedDuration: 900)
            ],
            category: "Finance",
            icon: "dollarsign.circle.fill"
        ),
        
        TaskTemplate(
            name: "Home Maintenance",
            description: "Household tasks",
            tasks: [
                TaskTemplateItem(title: "Check smoke detectors", notes: "Test batteries and functionality", priority: .high, estimatedDuration: 600),
                TaskTemplateItem(title: "Deep clean kitchen", notes: "Appliances, cabinets, and counters", priority: .medium, estimatedDuration: 3600),
                TaskTemplateItem(title: "Inspect HVAC system", notes: "Change filters and check settings", priority: .medium, estimatedDuration: 1200),
                TaskTemplateItem(title: "Organize storage areas", notes: "Declutter closets and garage", priority: .low, estimatedDuration: 7200)
            ],
            category: "Home",
            icon: "house.fill"
        )
    ]
}

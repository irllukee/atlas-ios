import Foundation

enum AppView: CaseIterable {
    case dashboard
    case notes
    case journal
    case tasks
    case watchlist
    case recipes
    case eatDo
    case mindMapping
    case profile
    
    var title: String {
        switch self {
        case .dashboard:
            return "Dashboard"
        case .notes:
            return "Notes"
        case .journal:
            return "Journal"
        case .tasks:
            return "Tasks"
        case .watchlist:
            return "Watchlist"
        case .recipes:
            return "Recipes"
        case .eatDo:
            return "Eat & Do"
        case .mindMapping:
            return "Mind Mapping"
        case .profile:
            return "Profile"
        }
    }
    
    var iconName: String {
        switch self {
        case .dashboard:
            return "house.fill"
        case .notes:
            return "note.text"
        case .journal:
            return "book.fill"
        case .tasks:
            return "checklist"
        case .watchlist:
            return "tv.fill"
        case .recipes:
            return "fork.knife"
        case .eatDo:
            return "location.fill"
        case .mindMapping:
            return "brain.head.profile"
        case .profile:
            return "person.fill"
        }
    }
}


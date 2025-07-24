import Foundation
import CoreData
import SwiftUI

@objc(SceneTag)
public class SceneTag: NSManagedObject {
    
    // MARK: - Computed Properties
    
    /// Returns the color as a SwiftUI Color
    var swiftUIColor: Color {
        return Color(hex: color) ?? Color.blue
    }
    
    /// Returns the total usage time for this tag by querying AppUsageSession
    func totalUsageTime(in context: NSManagedObjectContext) -> TimeInterval {
        let request: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        request.predicate = NSPredicate(format: "sceneTag == %@", name)
        
        do {
            let sessions = try context.fetch(request)
            return sessions.reduce(0) { $0 + $1.duration }
        } catch {
            print("Failed to fetch usage sessions for tag: \(error)")
            return 0
        }
    }
    
    /// Returns the formatted total usage time
    func formattedTotalUsageTime(in context: NSManagedObjectContext) -> String {
        let totalTime = totalUsageTime(in: context)
        let hours = Int(totalTime) / 3600
        let minutes = Int(totalTime.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Returns the number of associated usage sessions
    func sessionCount(in context: NSManagedObjectContext) -> Int {
        let request: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        request.predicate = NSPredicate(format: "sceneTag == %@", name)
        
        do {
            return try context.count(for: request)
        } catch {
            print("Failed to count usage sessions for tag: \(error)")
            return 0
        }
    }
    
    // MARK: - Associated Apps Helper Properties
    
    /// Returns the associated apps as a Set<String>
    var associatedAppsSet: Set<String> {
        get {
            guard let appsString = associatedApps, !appsString.isEmpty else {
                return Set<String>()
            }
            return Set(appsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) })
        }
        set {
            associatedApps = newValue.isEmpty ? nil : Array(newValue).joined(separator: ",")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Increments the usage count for this tag
    func incrementUsageCount() {
        usageCount += 1
    }
    
    /// Adds an app identifier to the associated apps set
    func addAssociatedApp(_ appIdentifier: String) {
        var apps = associatedAppsSet
        apps.insert(appIdentifier)
        associatedAppsSet = apps
    }
    
    /// Removes an app identifier from the associated apps set
    func removeAssociatedApp(_ appIdentifier: String) {
        var apps = associatedAppsSet
        apps.remove(appIdentifier)
        associatedAppsSet = apps
    }
    
    /// Checks if an app is associated with this tag
    func isAppAssociated(_ appIdentifier: String) -> Bool {
        return associatedAppsSet.contains(appIdentifier)
    }
    
    /// Creates a new scene tag
    static func createTag(
        name: String,
        color: String = "#007AFF",
        isDefault: Bool = false,
        in context: NSManagedObjectContext
    ) -> SceneTag {
        let tag = SceneTag(context: context)
        tag.tagID = UUID().uuidString
        tag.name = name
        tag.color = color
        tag.isDefault = isDefault
        tag.createdAt = Date()
        tag.usageCount = 0
        tag.associatedAppsSet = Set<String>()
        
        return tag
    }
    
    /// Creates default scene tags
    static func createDefaultTags(in context: NSManagedObjectContext) -> [SceneTag] {
        let defaultTags = [
            ("工作", "#007AFF"),
            ("学习", "#34C759"),
            ("娱乐", "#FF9500"),
            ("社交", "#FF2D92"),
            ("健康", "#30D158"),
            ("购物", "#AC39FF"),
            ("出行", "#64D2FF")
        ]
        
        return defaultTags.map { name, color in
            createTag(name: name, color: color, isDefault: true, in: context)
        }
    }
    
    /// Returns suggested apps for this tag based on name
    func getSuggestedApps() -> [String] {
        switch name {
        case "工作":
            return ["com.microsoft.Office.Word", "com.microsoft.Office.Excel", "com.microsoft.Office.PowerPoint", 
                   "com.apple.mail", "com.slack.Slack", "com.microsoft.teams"]
        case "学习":
            return ["com.apple.iBooks", "com.duolingo.DuolingoMobile", "com.khanacademy.Khan-Academy",
                   "com.apple.Keynote", "com.apple.Pages"]
        case "娱乐":
            return ["com.netflix.Netflix", "com.tencent.QQMusic", "com.apple.tv",
                   "com.spotify.client", "com.youku.YouKu"]
        case "社交":
            return ["com.tencent.xin", "com.sina.weibo", "com.zhihu.ios",
                   "com.tencent.mqq", "com.facebook.Facebook"]
        case "健康":
            return ["com.apple.Health", "com.nike.nikeplus-gps", "com.myfitnesspal.MyFitnessPal",
                   "com.apple.Fitness", "com.strava.stravarun"]
        case "购物":
            return ["com.taobao.taobao4iphone", "com.tmall.tmall", "com.jingdong.app.mall",
                   "com.apple.AppStore", "com.amazon.Amazon"]
        case "出行":
            return ["com.autonavi.amap", "com.baidu.map", "com.didi.passenger",
                   "com.uber.Uber", "com.apple.Maps"]
        default:
            return []
        }
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
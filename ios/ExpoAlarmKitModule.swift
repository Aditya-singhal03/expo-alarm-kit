import ExpoModulesCore
import AlarmKit
import ActivityKit
import AppIntents
import SwiftUI

// MARK: - Storage Keys
private let alarmKeyPrefix = "ExpoAlarmKit.alarm:"
private let launchAppKeyPrefix = "ExpoAlarmKit.launchApp:"
private let alarmConfigKeyPrefix = "ExpoAlarmKit.config:"
private let missionCompleteKeyPrefix = "ExpoAlarmKit.missionComplete:"
private let appGroupIdKey = "ExpoAlarmKit.appGroupIdentifier"
private let debugLogKey = "ExpoAlarmKit.debugLog"

// MARK: - App Group Storage Manager
@available(iOS 26.0, *)
public class ExpoAlarmKitStorage {
    public static var appGroupIdentifier: String? = nil

    /// Ensures appGroupIdentifier is available, restoring from UserDefaults.standard if needed.
    /// This is critical for LiveActivityIntents which may run when the static var is not set.
    public static func ensureAppGroupIdentifier() {
        if appGroupIdentifier == nil {
            appGroupIdentifier = UserDefaults.standard.string(forKey: appGroupIdKey)
            if appGroupIdentifier != nil {
                print("[ExpoAlarmKit] Restored App Group ID from UserDefaults.standard: \(appGroupIdentifier!)")
            }
        }
    }

    /// Persists the app group ID to UserDefaults.standard so intents can recover it.
    public static func persistAppGroupIdentifier(_ identifier: String) {
        appGroupIdentifier = identifier
        UserDefaults.standard.set(identifier, forKey: appGroupIdKey)
        UserDefaults.standard.synchronize()
    }

    public static var sharedDefaults: UserDefaults? {
        ensureAppGroupIdentifier()
        guard let groupId = appGroupIdentifier else {
            print("[ExpoAlarmKit] Warning: App Group not configured. Call configure() first.")
            return nil
        }
        return UserDefaults(suiteName: groupId)
    }
    
    public static func setAlarm(id: String, value: Double) {
        sharedDefaults?.set(value, forKey: alarmKeyPrefix + id)
    }
    
    public static func removeAlarm(id: String) {
        sharedDefaults?.removeObject(forKey: alarmKeyPrefix + id)
    }
    
    public static func getAllAlarmIds() -> [String] {
        guard let defaults = sharedDefaults?.dictionaryRepresentation() else { return [] }
        var alarmIds: [String] = []
        for key in defaults.keys {
            if key.hasPrefix(alarmKeyPrefix) {
                let alarmId = String(key.dropFirst(alarmKeyPrefix.count))
                alarmIds.append(alarmId)
            }
        }
        return alarmIds
    }
    
    public static func clearAllAlarms() {
        guard let defaults = sharedDefaults?.dictionaryRepresentation() else { return }
        for key in defaults.keys {
            if key.hasPrefix(alarmKeyPrefix) {
                sharedDefaults?.removeObject(forKey: key)
            }
        }
    }
    
    public static func setLaunchAppOnDismiss(alarmId: String, value: Bool) {
        sharedDefaults?.set(value, forKey: launchAppKeyPrefix + alarmId)
    }
    
    public static func getLaunchAppOnDismiss(alarmId: String) -> Bool {
        return sharedDefaults?.bool(forKey: launchAppKeyPrefix + alarmId) ?? false
    }
    
    public static func removeLaunchAppOnDismiss(alarmId: String) {
        sharedDefaults?.removeObject(forKey: launchAppKeyPrefix + alarmId)
    }

    // MARK: - Alarm Config Storage (for reschedule-on-stop)

    public static func setAlarmConfig(id: String, config: [String: Any]) {
        if let data = try? JSONSerialization.data(withJSONObject: config) {
            sharedDefaults?.set(data, forKey: alarmConfigKeyPrefix + id)
        }
    }

    public static func getAlarmConfig(id: String) -> [String: Any]? {
        guard let data = sharedDefaults?.data(forKey: alarmConfigKeyPrefix + id),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return dict
    }

    public static func removeAlarmConfig(id: String) {
        sharedDefaults?.removeObject(forKey: alarmConfigKeyPrefix + id)
    }

    // MARK: - Mission Complete Flag

    public static func setMissionComplete(id: String, value: Bool) {
        sharedDefaults?.set(value, forKey: missionCompleteKeyPrefix + id)
    }

    public static func isMissionComplete(id: String) -> Bool {
        return sharedDefaults?.bool(forKey: missionCompleteKeyPrefix + id) ?? false
    }

    public static func removeMissionComplete(id: String) {
        sharedDefaults?.removeObject(forKey: missionCompleteKeyPrefix + id)
    }

    // MARK: - Debug Log (writes to UserDefaults.standard so it ALWAYS works)
    // We use UserDefaults.standard, NOT App Group — because if App Group is broken,
    // we still want to see the logs. Both the intent and the main app share the same
    // UserDefaults.standard when the intent runs in-process.

    public static func appendDebugLog(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let entry = "[\(timestamp)] \(message)"
        var logs = UserDefaults.standard.stringArray(forKey: debugLogKey) ?? []
        logs.append(entry)
        // Keep last 50 entries
        if logs.count > 50 { logs = Array(logs.suffix(50)) }
        UserDefaults.standard.set(logs, forKey: debugLogKey)
        UserDefaults.standard.synchronize()
    }

    public static func getDebugLog() -> [String] {
        return UserDefaults.standard.stringArray(forKey: debugLogKey) ?? []
    }

    public static func clearDebugLog() {
        UserDefaults.standard.removeObject(forKey: debugLogKey)
        UserDefaults.standard.synchronize()
    }
}

// MARK: - Record Structs for Expo Module
@available(iOS 26.0, *)
struct ScheduleAlarmOptions: Record {
    @Field var id: String
    @Field var epochSeconds: Double
    @Field var title: String
    @Field var soundName: String?
    @Field var launchAppOnDismiss: Bool?
    @Field var doSnoozeIntent: Bool?
    @Field var launchAppOnSnooze: Bool?
    @Field var dismissPayload: String?
    @Field var snoozePayload: String?
    @Field var stopButtonLabel: String?
    @Field var snoozeButtonLabel: String?
    @Field var stopButtonColor: String?
    @Field var snoozeButtonColor: String?
    @Field var tintColor: String?
    @Field var snoozeDuration: Int?
    @Field var rescheduleOnStop: Bool?
    @Field var rescheduleDelay: Int?
}

@available(iOS 26.0, *)
struct ScheduleRepeatingAlarmOptions: Record {
    @Field var id: String
    @Field var hour: Int
    @Field var minute: Int
    @Field var weekdays: [Int]
    @Field var title: String
    @Field var soundName: String?
    @Field var launchAppOnDismiss: Bool?
    @Field var doSnoozeIntent: Bool?
    @Field var launchAppOnSnooze: Bool?
    @Field var dismissPayload: String?
    @Field var snoozePayload: String?
    @Field var stopButtonLabel: String?
    @Field var snoozeButtonLabel: String?
    @Field var stopButtonColor: String?
    @Field var snoozeButtonColor: String?
    @Field var tintColor: String?
    @Field var snoozeDuration: Int?
    @Field var rescheduleOnStop: Bool?
    @Field var rescheduleDelay: Int?
}

// MARK: - Helper Functions
private func colorFromHex(_ hex: String) -> Color {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
    
    var rgb: UInt64 = 0
    Scanner(string: hexSanitized).scanHexInt64(&rgb)
    
    let r = Double((rgb & 0xFF0000) >> 16) / 255.0
    let g = Double((rgb & 0x00FF00) >> 8) / 255.0
    let b = Double(rgb & 0x0000FF) / 255.0
    
    return Color(red: r, green: g, blue: b)
}

private func buildLaunchPayload(alarmId: String, payload: String?) -> [String: Any] {
    return [
        "alarmId": alarmId,
        "payload": payload ?? NSNull()
    ]
}

// MARK: - App Intent for Alarm Dismissal (No App Launch)
@available(iOS 26.0, *)
public struct AlarmDismissIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Dismiss Alarm"
    public static var description = IntentDescription("Handles alarm dismissal")
    public static var openAppWhenRun: Bool = false

    @Parameter(title: "alarmId")
    public var alarmId: String

    @Parameter(title: "payload")
    public var payload: String?

    public init() {}

    public init(alarmId: String, payload: String? = nil) {
        self.alarmId = alarmId
        self.payload = payload
    }

    public func perform() async throws -> some IntentResult {
        // Store payload for JS to retrieve
        ExpoAlarmKitModule.launchPayload = buildLaunchPayload(alarmId: self.alarmId, payload: self.payload)

        // Clean up App Group storage
        ExpoAlarmKitStorage.removeAlarm(id: self.alarmId)
        ExpoAlarmKitStorage.removeLaunchAppOnDismiss(alarmId: self.alarmId)

        return .result()
    }
}

// MARK: - App Intent for Alarm Dismissal (With App Launch)
@available(iOS 26.0, *)
public struct AlarmDismissIntentWithLaunch: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Dismiss Alarm"
    public static var description = IntentDescription("Handles alarm dismissal and opens app")
    public static var openAppWhenRun: Bool = true

    @Parameter(title: "alarmId")
    public var alarmId: String

    @Parameter(title: "payload")
    public var payload: String?

    public init() {}

    public init(alarmId: String, payload: String? = nil) {
        self.alarmId = alarmId
        self.payload = payload
    }

    public func perform() async throws -> some IntentResult {
        // Store payload for JS to retrieve
        ExpoAlarmKitModule.launchPayload = buildLaunchPayload(alarmId: self.alarmId, payload: self.payload)

        // Clean up App Group storage
        ExpoAlarmKitStorage.removeAlarm(id: self.alarmId)
        ExpoAlarmKitStorage.removeLaunchAppOnDismiss(alarmId: self.alarmId)

        return .result()
    }
}

// MARK: - Reschedule Stop Intent (re-rings alarm until mission complete)
// This is the KEY intent: runs natively on lock screen without JS bridge.
// When user taps Stop, it checks if mission is done. If not, schedules a
// new alarm to fire in rescheduleDelay seconds — creating an infinite loop
// until the mission-complete flag is set from JS.
@available(iOS 26.0, *)
public struct AlarmRescheduleStopIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Stop Alarm"
    public static var description = IntentDescription("Checks mission and reschedules alarm if not complete")
    public static var openAppWhenRun: Bool = true

    @Parameter(title: "alarmId")
    public var alarmId: String

    @Parameter(title: "baseAlarmId")
    public var baseAlarmId: String

    @Parameter(title: "payload")
    public var payload: String?

    public init() {}

    public init(alarmId: String, baseAlarmId: String, payload: String? = nil) {
        self.alarmId = alarmId
        self.baseAlarmId = baseAlarmId
        self.payload = payload
    }

    public func perform() async throws -> some IntentResult {
        ExpoAlarmKitStorage.appendDebugLog("perform() START | alarm=\(self.alarmId) base=\(self.baseAlarmId)")

        // Ensure App Group is accessible (static var may be nil if process restarted)
        ExpoAlarmKitStorage.ensureAppGroupIdentifier()
        let appGroup = ExpoAlarmKitStorage.appGroupIdentifier ?? "NIL"
        let sharedDefaultsOk = ExpoAlarmKitStorage.sharedDefaults != nil
        ExpoAlarmKitStorage.appendDebugLog("appGroup=\(appGroup) sharedDefaults=\(sharedDefaultsOk)")

        // Store payload so JS can read it when app opens
        ExpoAlarmKitModule.launchPayload = buildLaunchPayload(alarmId: self.baseAlarmId, payload: self.payload)

        let missionDone = ExpoAlarmKitStorage.isMissionComplete(id: self.baseAlarmId)
        ExpoAlarmKitStorage.appendDebugLog("missionDone=\(missionDone)")

        if missionDone {
            ExpoAlarmKitStorage.removeAlarm(id: self.alarmId)
            ExpoAlarmKitStorage.removeMissionComplete(id: self.baseAlarmId)
            ExpoAlarmKitStorage.removeAlarmConfig(id: self.baseAlarmId)
            ExpoAlarmKitStorage.appendDebugLog("STOPPED — mission complete")
            return .result()
        }

        // Mission NOT complete — reschedule a new alarm
        guard let config = ExpoAlarmKitStorage.getAlarmConfig(id: self.baseAlarmId) else {
            ExpoAlarmKitStorage.appendDebugLog("FAILED — no config found for base=\(self.baseAlarmId)")
            return .result()
        }

        let rescheduleDelay = config["rescheduleDelay"] as? Int ?? 30
        let newId = UUID()
        let fireDate = Date().addingTimeInterval(TimeInterval(rescheduleDelay))
        ExpoAlarmKitStorage.appendDebugLog("scheduling newId=\(newId) fireIn=\(rescheduleDelay)s")

        do {
            try await Self.scheduleRescheduleAlarm(
                id: newId,
                baseAlarmId: self.baseAlarmId,
                fireDate: fireDate,
                config: config
            )
            ExpoAlarmKitStorage.setAlarm(id: newId.uuidString, value: fireDate.timeIntervalSince1970)
            ExpoAlarmKitStorage.appendDebugLog("SUCCESS — rescheduled \(newId) at \(fireDate)")
        } catch {
            ExpoAlarmKitStorage.appendDebugLog("FAILED — schedule error: \(error.localizedDescription)")
        }

        return .result()
    }

    // Builds and schedules a new one-shot alarm using stored config
    static func scheduleRescheduleAlarm(
        id: UUID,
        baseAlarmId: String,
        fireDate: Date,
        config: [String: Any]
    ) async throws {
        struct Meta: AlarmMetadata {}

        let title = config["title"] as? String ?? "Alarm"
        let rawSoundName = config["soundName"] as? String
        let soundName = (rawSoundName?.isEmpty == true) ? nil : rawSoundName
        let rawTintColor = config["tintColor"] as? String
        let tintColorHex = (rawTintColor?.isEmpty == true) ? nil : rawTintColor
        let stopLabel = config["stopButtonLabel"] as? String ?? "Stop"
        let snoozeLabel = config["snoozeButtonLabel"] as? String ?? "Snooze"
        let rawStopColor = config["stopButtonColor"] as? String
        let stopColorHex = (rawStopColor?.isEmpty == true) ? nil : rawStopColor
        let rawSnoozeColor = config["snoozeButtonColor"] as? String
        let snoozeColorHex = (rawSnoozeColor?.isEmpty == true) ? nil : rawSnoozeColor
        let snoozeDuration = config["snoozeDuration"] as? Int ?? (9 * 60)
        let rawDismissPayload = config["dismissPayload"] as? String
        let dismissPayload = (rawDismissPayload?.isEmpty == true) ? nil : rawDismissPayload
        let rawSnoozePayload = config["snoozePayload"] as? String
        let snoozePayload = (rawSnoozePayload?.isEmpty == true) ? nil : rawSnoozePayload
        let launchAppOnSnooze = config["launchAppOnSnooze"] as? Bool ?? false

        let stopColor = stopColorHex != nil ? colorFromHex(stopColorHex!) : Color.white
        let snoozeColor = snoozeColorHex != nil ? colorFromHex(snoozeColorHex!) : Color.white
        let alarmTintColor = tintColorHex != nil ? colorFromHex(tintColorHex!) : Color.blue

        let stopButton = AlarmButton(
            text: LocalizedStringResource(stringLiteral: stopLabel),
            textColor: stopColor,
            systemImageName: "stop.circle"
        )
        let snoozeButton = AlarmButton(
            text: LocalizedStringResource(stringLiteral: snoozeLabel),
            textColor: snoozeColor,
            systemImageName: "clock.badge.checkmark"
        )

        let alertPresentation = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: title),
            stopButton: stopButton,
            secondaryButton: snoozeButton,
            secondaryButtonBehavior: .countdown
        )
        let presentation = AlarmPresentation(alert: alertPresentation)

        let countdownDuration = Alarm.CountdownDuration(
            preAlert: nil,
            postAlert: TimeInterval(snoozeDuration)
        )

        let attributes = AlarmAttributes<Meta>(
            presentation: presentation,
            metadata: Meta(),
            tintColor: alarmTintColor
        )

        let alarmSound: AlertConfiguration.AlertSound
        if let sn = soundName, !sn.isEmpty {
            alarmSound = .named(sn)
        } else {
            alarmSound = .default
        }

        // Stop intent: another RescheduleStopIntent (keeps the loop going)
        let stopIntent = AlarmRescheduleStopIntent(
            alarmId: id.uuidString,
            baseAlarmId: baseAlarmId,
            payload: dismissPayload
        )

        // Snooze intent
        let secondaryIntent: (any LiveActivityIntent)? = launchAppOnSnooze
            ? AlarmSnoozeIntentWithLaunch(alarmId: id.uuidString, payload: snoozePayload)
            : AlarmSnoozeIntent(alarmId: id.uuidString, payload: snoozePayload)

        let alarmConfig = AlarmManager.AlarmConfiguration<Meta>(
            countdownDuration: countdownDuration,
            schedule: .fixed(fireDate),
            attributes: attributes,
            stopIntent: stopIntent,
            secondaryIntent: secondaryIntent,
            sound: alarmSound
        )

        try await AlarmManager.shared.schedule(id: id, configuration: alarmConfig)
    }
}

// MARK: - App Intent for Alarm Snooze (No App Launch)
@available(iOS 26.0, *)
public struct AlarmSnoozeIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Snooze Alarm"
    public static var description = IntentDescription("Handles alarm snooze")
    public static var openAppWhenRun: Bool = false
    
    @Parameter(title: "alarmId")
    public var alarmId: String
    
    @Parameter(title: "payload")
    public var payload: String?
    
    public init() {}
    
    public init(alarmId: String, payload: String? = nil) {
        self.alarmId = alarmId
        self.payload = payload
    }
    
    public func perform() async throws -> some IntentResult {
        ExpoAlarmKitModule.launchPayload = buildLaunchPayload(alarmId: self.alarmId, payload: self.payload)
        return .result()
    }
}

// MARK: - App Intent for Alarm Snooze (With App Launch)
@available(iOS 26.0, *)
public struct AlarmSnoozeIntentWithLaunch: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Snooze Alarm"
    public static var description = IntentDescription("Handles alarm snooze and opens app")
    public static var openAppWhenRun: Bool = true
    
    @Parameter(title: "alarmId")
    public var alarmId: String
    
    @Parameter(title: "payload")
    public var payload: String?
    
    public init() {}
    
    public init(alarmId: String, payload: String? = nil) {
        self.alarmId = alarmId
        self.payload = payload
    }
    
    public func perform() async throws -> some IntentResult {
        ExpoAlarmKitModule.launchPayload = buildLaunchPayload(alarmId: self.alarmId, payload: self.payload)
        return .result()
    }
}

// MARK: - Expo Module
@available(iOS 26.0, *)
public class ExpoAlarmKitModule: Module {
    // Static payload for app launch detection
    public static var launchPayload: [String: Any]? = nil
    
    public func definition() -> ModuleDefinition {
        Name("ExpoAlarmKit")
        
        // MARK: - Configure App Group
        Function("configure") { (appGroupIdentifier: String) -> Bool in
            ExpoAlarmKitStorage.persistAppGroupIdentifier(appGroupIdentifier)
            // Verify the app group is accessible
            if ExpoAlarmKitStorage.sharedDefaults != nil {
                print("[ExpoAlarmKit] Configured with App Group: \(appGroupIdentifier)")
                return true
            } else {
                print("[ExpoAlarmKit] Failed to configure App Group: \(appGroupIdentifier)")
                return false
            }
        }
        
        // MARK: - Request Authorization
        AsyncFunction("requestAuthorization") { () -> String in
            let status = AlarmManager.shared.authorizationState
            switch status {
            case .authorized:
                return "authorized"
            case .denied:
                do {
                    let newStatus = try await AlarmManager.shared.requestAuthorization()
                    switch newStatus {
                    case .authorized:
                        return "authorized"
                    case .denied:
                        return "denied"
                    case .notDetermined:
                        return "notDetermined"
                    @unknown default:
                        return "notDetermined"
                    }
                } catch {
                    return "denied"
                }
            case .notDetermined:
                do {
                    let newStatus = try await AlarmManager.shared.requestAuthorization()
                    switch newStatus {
                    case .authorized:
                        return "authorized"
                    case .denied:
                        return "denied"
                    case .notDetermined:
                        return "notDetermined"
                    @unknown default:
                        return "notDetermined"
                    }
                } catch {
                    return "denied"
                }
            @unknown default:
                return "notDetermined"
            }
        }
        
        // MARK: - Generate UUID
        Function("generateUUID") { () -> String in
            return UUID().uuidString
        }
        
        // MARK: - Schedule One-Time Alarm
        AsyncFunction("scheduleAlarm") { (options: ScheduleAlarmOptions) async throws -> Bool in
            struct Meta: AlarmMetadata {}
            
            let date = Date(timeIntervalSince1970: options.epochSeconds)
            guard let uuid = UUID(uuidString: options.id) else {
                print("[ExpoAlarmKit] Invalid UUID string: \(options.id)")
                return false
            }
            let launchAppOnDismiss = options.launchAppOnDismiss ?? false
            let doSnoozeIntent = options.doSnoozeIntent ?? false
            let launchAppOnSnooze = options.launchAppOnSnooze ?? false
            
            // Create stop button
            let stopLabel = options.stopButtonLabel ?? "Stop"
            let stopColor = options.stopButtonColor != nil ? colorFromHex(options.stopButtonColor!) : Color.white
            let stopButton = AlarmButton(
                text: LocalizedStringResource(stringLiteral: stopLabel),
                textColor: stopColor,
                systemImageName: "stop.circle"
            )
            
            // Create snooze button
            let snoozeLabel = options.snoozeButtonLabel ?? "Snooze"
            let snoozeColor = options.snoozeButtonColor != nil ? colorFromHex(options.snoozeButtonColor!) : Color.white
            let snoozeButton = AlarmButton(
                text: LocalizedStringResource(stringLiteral: snoozeLabel),
                textColor: snoozeColor,
                systemImageName: "clock.badge.checkmark"
            )
            
            // Create alert presentation with intent if needed
            let alertPresentation = AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: options.title),
                stopButton: stopButton,
                secondaryButton: snoozeButton,
                secondaryButtonBehavior: .countdown
            )
            
            let presentation = AlarmPresentation(alert: alertPresentation)
            
            // Create countdown duration for snooze
            let countdownDuration = Alarm.CountdownDuration(
                preAlert: nil,
                postAlert: TimeInterval(options.snoozeDuration ?? (9 * 60))
            )
            
            // Create attributes
            let alarmTintColor = options.tintColor != nil ? colorFromHex(options.tintColor!) : Color.blue
            let attributes = AlarmAttributes<Meta>(
                presentation: presentation,
                metadata: Meta(),
                tintColor: alarmTintColor
            )
            
            // Determine sound
            let alarmSound: AlertConfiguration.AlertSound
            if let soundName = options.soundName, !soundName.isEmpty {
                alarmSound = .named(soundName)
            } else {
                alarmSound = .default
            }
            
            let rescheduleOnStop = options.rescheduleOnStop ?? false

            // Choose stop intent based on rescheduleOnStop mode
            let stopIntent: any LiveActivityIntent
            if rescheduleOnStop {
                // Native reschedule: alarm re-rings until mission complete flag is set
                stopIntent = AlarmRescheduleStopIntent(
                    alarmId: options.id,
                    baseAlarmId: options.id,
                    payload: options.dismissPayload
                )
            } else if launchAppOnDismiss {
                stopIntent = AlarmDismissIntentWithLaunch(alarmId: options.id, payload: options.dismissPayload)
            } else {
                stopIntent = AlarmDismissIntent(alarmId: options.id, payload: options.dismissPayload)
            }

            let secondaryIntent: (any LiveActivityIntent)?
            if doSnoozeIntent {
                if launchAppOnSnooze {
                    secondaryIntent = AlarmSnoozeIntentWithLaunch(alarmId: options.id, payload: options.snoozePayload)
                } else {
                    secondaryIntent = AlarmSnoozeIntent(alarmId: options.id, payload: options.snoozePayload)
                }
            } else {
                secondaryIntent = nil
            }

            // Create configuration
            let config = AlarmManager.AlarmConfiguration<Meta>(
                countdownDuration: countdownDuration,
                schedule: .fixed(date),
                attributes: attributes,
                stopIntent: stopIntent,
                secondaryIntent: secondaryIntent,
                sound: alarmSound
            )

            do {
                try await AlarmManager.shared.schedule(id: uuid, configuration: config)
                // Store alarm metadata in App Group
                ExpoAlarmKitStorage.setAlarm(id: options.id, value: options.epochSeconds)

                // If rescheduleOnStop, store config so the intent can rebuild the alarm
                if rescheduleOnStop {
                    let storedConfig: [String: Any] = [
                        "title": options.title,
                        "soundName": options.soundName ?? "",
                        "tintColor": options.tintColor ?? "",
                        "stopButtonLabel": options.stopButtonLabel ?? "Stop",
                        "snoozeButtonLabel": options.snoozeButtonLabel ?? "Snooze",
                        "stopButtonColor": options.stopButtonColor ?? "",
                        "snoozeButtonColor": options.snoozeButtonColor ?? "",
                        "snoozeDuration": options.snoozeDuration ?? (9 * 60),
                        "dismissPayload": options.dismissPayload ?? "",
                        "snoozePayload": options.snoozePayload ?? "",
                        "launchAppOnSnooze": launchAppOnSnooze,
                        "rescheduleDelay": options.rescheduleDelay ?? 30,
                    ]
                    ExpoAlarmKitStorage.setAlarmConfig(id: options.id, config: storedConfig)
                }

                return true
            } catch {
                print("[ExpoAlarmKit] Failed to schedule alarm: \(error)")
                return false
            }
        }
        
        // MARK: - Schedule Repeating Alarm
        AsyncFunction("scheduleRepeatingAlarm") { ( options: ScheduleRepeatingAlarmOptions) async throws -> Bool in
            struct Meta: AlarmMetadata {}
            
            guard let uuid = UUID(uuidString: options.id) else {
                print("[ExpoAlarmKit] Invalid UUID string: \(options.id)")
                return false
            }
            let launchAppOnDismiss = options.launchAppOnDismiss ?? false
            let doSnoozeIntent = options.doSnoozeIntent ?? false
            let launchAppOnSnooze = options.launchAppOnSnooze ?? false
            
            // Convert weekday ints to Locale.Weekday
            // JS passes 1=Sunday, 2=Monday, etc. (matching iOS Calendar weekday)
            let weekdayArray: [Locale.Weekday] = Array(Set(options.weekdays.compactMap { day -> Locale.Weekday? in
                switch day {
                case 1: return .sunday
                case 2: return .monday
                case 3: return .tuesday
                case 4: return .wednesday
                case 5: return .thursday
                case 6: return .friday
                case 7: return .saturday
                default: return nil
                }
            }))
            
            // Create relative schedule with time and recurrence
            let time = Alarm.Schedule.Relative.Time(hour: options.hour, minute: options.minute)
            let recurrence = Alarm.Schedule.Relative.Recurrence.weekly(weekdayArray)
            let schedule = Alarm.Schedule.relative(Alarm.Schedule.Relative(time: time, repeats: recurrence))
            
            // Create stop button
            let stopLabel = options.stopButtonLabel ?? "Stop"
            let stopColor = options.stopButtonColor != nil ? colorFromHex(options.stopButtonColor!) : Color.white
            let stopButton = AlarmButton(
                text: LocalizedStringResource(stringLiteral: stopLabel),
                textColor: stopColor,
                systemImageName: "stop.circle"
            )
            
            // Create snooze button
            let snoozeLabel = options.snoozeButtonLabel ?? "Snooze"
            let snoozeColor = options.snoozeButtonColor != nil ? colorFromHex(options.snoozeButtonColor!) : Color.white
            let snoozeButton = AlarmButton(
                text: LocalizedStringResource(stringLiteral: snoozeLabel),
                textColor: snoozeColor,
                systemImageName: "clock.badge.checkmark"
            )
            
            // Create alert presentation
            let alertPresentation = AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: options.title),
                stopButton: stopButton,
                secondaryButton: snoozeButton,
                secondaryButtonBehavior: .countdown
            )
            
            let presentation = AlarmPresentation(alert: alertPresentation)
            
            // Create countdown duration for snooze
            let countdownDuration = Alarm.CountdownDuration(
                preAlert: nil,
                postAlert: TimeInterval(options.snoozeDuration ?? (9 * 60))
            )
            
            // Create attributes
            let alarmTintColor = options.tintColor != nil ? colorFromHex(options.tintColor!) : Color.blue
            let attributes = AlarmAttributes<Meta>(
                presentation: presentation,
                metadata: Meta(),
                tintColor: alarmTintColor
            )
            
            // Determine sound
            let alarmSound: AlertConfiguration.AlertSound
            if let soundName = options.soundName, !soundName.isEmpty {
                alarmSound = .named(soundName)
            } else {
                alarmSound = .default
            }
            
            let rescheduleOnStop = options.rescheduleOnStop ?? false

            // Choose stop intent based on rescheduleOnStop mode
            let stopIntent: any LiveActivityIntent
            if rescheduleOnStop {
                stopIntent = AlarmRescheduleStopIntent(
                    alarmId: options.id,
                    baseAlarmId: options.id,
                    payload: options.dismissPayload
                )
            } else if launchAppOnDismiss {
                stopIntent = AlarmDismissIntentWithLaunch(alarmId: options.id, payload: options.dismissPayload)
            } else {
                stopIntent = AlarmDismissIntent(alarmId: options.id, payload: options.dismissPayload)
            }

            let secondaryIntent: (any LiveActivityIntent)?
            if doSnoozeIntent {
                if launchAppOnSnooze {
                    secondaryIntent = AlarmSnoozeIntentWithLaunch(alarmId: options.id, payload: options.snoozePayload)
                } else {
                    secondaryIntent = AlarmSnoozeIntent(alarmId: options.id, payload: options.snoozePayload)
                }
            } else {
                secondaryIntent = nil
            }

            // Create configuration with relative schedule
            let config = AlarmManager.AlarmConfiguration<Meta>(
                countdownDuration: countdownDuration,
                schedule: schedule,
                attributes: attributes,
                stopIntent: stopIntent,
                secondaryIntent: secondaryIntent,
                sound: alarmSound
            )

            do {
                try await AlarmManager.shared.schedule(id: uuid, configuration: config)
                // Store alarm metadata in App Group (store -1 for repeating to indicate repeating type)
                ExpoAlarmKitStorage.setAlarm(id: options.id, value: -1)

                // If rescheduleOnStop, store config so the intent can rebuild the alarm
                if rescheduleOnStop {
                    let storedConfig: [String: Any] = [
                        "title": options.title,
                        "soundName": options.soundName ?? "",
                        "tintColor": options.tintColor ?? "",
                        "stopButtonLabel": options.stopButtonLabel ?? "Stop",
                        "snoozeButtonLabel": options.snoozeButtonLabel ?? "Snooze",
                        "stopButtonColor": options.stopButtonColor ?? "",
                        "snoozeButtonColor": options.snoozeButtonColor ?? "",
                        "snoozeDuration": options.snoozeDuration ?? (9 * 60),
                        "dismissPayload": options.dismissPayload ?? "",
                        "snoozePayload": options.snoozePayload ?? "",
                        "launchAppOnSnooze": launchAppOnSnooze,
                        "rescheduleDelay": options.rescheduleDelay ?? 30,
                    ]
                    ExpoAlarmKitStorage.setAlarmConfig(id: options.id, config: storedConfig)
                }

                return true
            } catch {
                print("[ExpoAlarmKit] Failed to schedule repeating alarm: \(error)")
                return false
            }
        }
        
        // MARK: - Cancel Alarm
        AsyncFunction("cancelAlarm") { (id: String) -> Bool in
            guard let uuid = UUID(uuidString: id) else {
                print("[ExpoAlarmKit] Invalid UUID string: \(id)")
                return false
            }
            
            do {
                try AlarmManager.shared.cancel(id: uuid)
                // Clean up App Group storage
                ExpoAlarmKitStorage.removeAlarm(id: id)
                ExpoAlarmKitStorage.removeLaunchAppOnDismiss(alarmId: id)
                ExpoAlarmKitStorage.removeAlarmConfig(id: id)
                ExpoAlarmKitStorage.removeMissionComplete(id: id)
                return true
            } catch {
                print("[ExpoAlarmKit] Failed to cancel alarm: \(error)")
                return false
            }
        }
        
        // MARK: - Get All Alarms
        Function("getAllAlarms") { () -> [String] in
            return ExpoAlarmKitStorage.getAllAlarmIds()
        }

        
        // MARK: - Remove Alarm (from App Group storage only)
        Function("removeAlarm") { (id: String) in
            ExpoAlarmKitStorage.removeAlarm(id: id)
            ExpoAlarmKitStorage.removeLaunchAppOnDismiss(alarmId: id)
        }
        
        // MARK: - Clear All Alarms (from App Group storage only)
        Function("clearAllAlarms") { () in
            ExpoAlarmKitStorage.clearAllAlarms()
        }
        
        // MARK: - Mission Complete Flag
        Function("setMissionComplete") { (alarmId: String) in
            ExpoAlarmKitStorage.setMissionComplete(id: alarmId, value: true)
            print("[ExpoAlarmKit] Mission marked complete for \(alarmId)")
        }

        Function("clearMissionComplete") { (alarmId: String) in
            ExpoAlarmKitStorage.removeMissionComplete(id: alarmId)
            print("[ExpoAlarmKit] Mission complete flag cleared for \(alarmId)")
        }

        // MARK: - Debug Log
        Function("getDebugLog") { () -> [String] in
            return ExpoAlarmKitStorage.getDebugLog()
        }

        Function("clearDebugLog") { () in
            ExpoAlarmKitStorage.clearDebugLog()
        }

        // MARK: - Get Launch Payload
        Function("getLaunchPayload") { () -> [String: Any]? in
            let payload = ExpoAlarmKitModule.launchPayload
            // Clear after retrieval
            ExpoAlarmKitModule.launchPayload = nil
            return payload
        }
    }
}

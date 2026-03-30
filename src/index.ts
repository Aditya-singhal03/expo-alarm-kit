import ExpoAlarmKitModule, {
  AuthorizationStatus,
  LaunchPayload,
} from './ExpoAlarmKitModule';

export { AuthorizationStatus, LaunchPayload };

/**
 * Configure the module with an App Group identifier.
 * This MUST be called before any other methods to enable shared storage
 * between your app and the alarm dismiss intent.
 * 
 * @param appGroupIdentifier - The App Group identifier (e.g., "group.com.yourapp.alarms")
 * @returns True if configuration succeeded.
 * 
 * @example
 * ```typescript
 * import { configure } from 'expo-alarm-kit';
 * 
 * // Call this early in your app initialization
 * const success = configure('group.com.yourcompany.yourapp');
 * if (!success) {
 *   console.error('Failed to configure ExpoAlarmKit');
 * }
 * ```
 */
export function configure(appGroupIdentifier: string): boolean {
  return ExpoAlarmKitModule.configure(appGroupIdentifier);
}

/**
 * Request authorization to schedule alarms.
 * On first call, this will prompt the user for permission.
 * @returns The current authorization status.
 */
export async function requestAuthorization(): Promise<AuthorizationStatus> {
  return ExpoAlarmKitModule.requestAuthorization();
}

/**
 * Generate a valid UUID string for use as an alarm ID.
 * Call this before scheduling an alarm to get a unique identifier.
 * @returns A new UUID string.
 */
export function generateUUID(): string {
  return ExpoAlarmKitModule.generateUUID();
}

export interface ScheduleAlarmOptions {
  /** Unique identifier for the alarm */
  id: string;
  /** Unix timestamp in seconds for when the alarm should fire. Provide either this or date. */
  epochSeconds?: number;
  /** JavaScript Date object for when the alarm should fire. Provide either this or epochSeconds. */
  date?: Date;
  /** Title displayed for the alarm */
  title: string;
  /** Optional custom sound name (must exist in app bundle) */
  soundName?: string;
  /** Whether to launch the app when the alarm stop button is pressed. Defaults to false. Ignored when rescheduleOnStop is true. */
  launchAppOnDismiss?: boolean;
  /** Whether to run a custom snooze intent when the snooze button is pressed. Defaults to false. */
  doSnoozeIntent?: boolean;
  /** Whether to launch the app when the custom snooze intent runs. Defaults to false. */
  launchAppOnSnooze?: boolean;
  /** Optional payload string returned by getLaunchPayload when dismissed. Defaults to null. */
  dismissPayload?: string;
  /** Optional payload string returned by getLaunchPayload when snoozed. Defaults to null. */
  snoozePayload?: string;
  /** Custom label for the stop button (default: 'Stop') */
  stopButtonLabel?: string;
  /** Custom label for the snooze button (default: 'Snooze') */
  snoozeButtonLabel?: string;
  /** Hex color for the stop button text (default: '#FFFFFF') */
  stopButtonColor?: string;
  /** Hex color for the snooze button text (default: '#FFFFFF') */
  snoozeButtonColor?: string;
  /** Hex color for the overall alarm tint (default: '#0000FF') */
  tintColor?: string;
  /** Snooze duration in seconds (default: 540 = 9 minutes) */
  snoozeDuration?: number;
  /** When true, tapping Stop schedules a new alarm natively (works on lock screen). Call setMissionComplete() to break the loop. */
  rescheduleOnStop?: boolean;
  /** Delay in seconds before the re-ring alarm fires (default: 30). Only used when rescheduleOnStop is true. */
  rescheduleDelay?: number;
}

/**
 * Schedule a one-time alarm.
 * @param options - Alarm configuration options. Provide either epochSeconds or date.
 * @returns True if the alarm was scheduled successfully.
 */
export async function scheduleAlarm(options: ScheduleAlarmOptions): Promise<boolean> {
  // Convert Date to epochSeconds if provided
  let epochSeconds: number;
  
  if (options.date !== undefined && options.epochSeconds !== undefined) {
    throw new Error('Provide either epochSeconds or date, not both');
  }
  
  if (options.date !== undefined) {
    epochSeconds = Math.floor(options.date.getTime() / 1000);
  } else if (options.epochSeconds !== undefined) {
    epochSeconds = options.epochSeconds;
  } else {
    throw new Error('Must provide either epochSeconds or date');
  }
  
  // Pass to native module with epochSeconds
  return ExpoAlarmKitModule.scheduleAlarm({
    ...options,
    epochSeconds,
  });
}

export interface ScheduleRepeatingAlarmOptions {
  /** Unique identifier for the alarm */
  id: string;
  /** Hour (0-23) for the alarm */
  hour: number;
  /** Minute (0-59) for the alarm */
  minute: number;
  /** Array of weekday numbers: 1=Sunday, 2=Monday, 3=Tuesday, 4=Wednesday, 5=Thursday, 6=Friday, 7=Saturday */
  weekdays: number[];
  /** Title displayed for the alarm */
  title: string;
  /** Optional custom sound name (must exist in app bundle) */
  soundName?: string;
  /** Whether to launch the app when the alarm stop button is pressed. Defaults to false. Ignored when rescheduleOnStop is true. */
  launchAppOnDismiss?: boolean;
  /** Whether to run a custom snooze intent when the snooze button is pressed. Defaults to false. */
  doSnoozeIntent?: boolean;
  /** Whether to launch the app when the custom snooze intent runs. Defaults to false. */
  launchAppOnSnooze?: boolean;
  /** Optional payload string returned by getLaunchPayload when dismissed. Defaults to null. */
  dismissPayload?: string;
  /** Optional payload string returned by getLaunchPayload when snoozed. Defaults to null. */
  snoozePayload?: string;
  /** Custom label for the stop button (default: 'Stop') */
  stopButtonLabel?: string;
  /** Custom label for the snooze button (default: 'Snooze') */
  snoozeButtonLabel?: string;
  /** Hex color for the stop button text (default: '#FFFFFF') */
  stopButtonColor?: string;
  /** Hex color for the snooze button text (default: '#FFFFFF') */
  snoozeButtonColor?: string;
  /** Hex color for the overall alarm tint (default: '#0000FF') */
  tintColor?: string;
  /** Snooze duration in seconds (default: 540 = 9 minutes) */
  snoozeDuration?: number;
  /** When true, tapping Stop schedules a new alarm natively (works on lock screen). Call setMissionComplete() to break the loop. */
  rescheduleOnStop?: boolean;
  /** Delay in seconds before the re-ring alarm fires (default: 30). Only used when rescheduleOnStop is true. */
  rescheduleDelay?: number;
}

/**
 * Schedule a weekly repeating alarm.
 * @param options - Alarm configuration options.
 * @returns True if the alarm was scheduled successfully.
 */
export async function scheduleRepeatingAlarm(options: ScheduleRepeatingAlarmOptions): Promise<boolean> {
  return ExpoAlarmKitModule.scheduleRepeatingAlarm(options);
}

/**
 * Cancel a scheduled alarm.
 * This removes the alarm from both AlarmKit and App Group storage.
 * @param id - The alarm ID to cancel.
 * @returns True if the alarm was cancelled successfully.
 */
export async function cancelAlarm(id: string): Promise<boolean> {
  return ExpoAlarmKitModule.cancelAlarm(id);
}

/**
 * Get all currently scheduled alarm IDs.
 * @returns Array of alarm IDs.
 */
export function getAllAlarms(): string[] {
  return ExpoAlarmKitModule.getAllAlarms();
}

export function clearAllAlarms(): void {
  ExpoAlarmKitModule.clearAllAlarms();
}

/**
 * Remove an alarm from App Group storage.
 * Note: This does NOT cancel the native alarm. Use cancelAlarm() to fully cancel an alarm.
 * @param id - The alarm ID to remove from storage.
 */
export function removeAlarm(id: string): void {
  ExpoAlarmKitModule.removeAlarm(id);
}

/**
 * Mark a mission as complete so the native reschedule-on-stop loop ends.
 * Call this when the user finishes their mission. The next time the stop intent
 * fires, it will NOT reschedule — the alarm stays dead.
 * @param alarmId - The base alarm ID (the original alarm's ID passed to schedule).
 */
export function setMissionComplete(alarmId: string): void {
  ExpoAlarmKitModule.setMissionComplete(alarmId);
}

/**
 * Clear the mission-complete flag. Call this when scheduling a new alarm
 * to ensure the reschedule loop is active for the next alarm instance.
 * @param alarmId - The base alarm ID.
 */
export function clearMissionComplete(alarmId: string): void {
  ExpoAlarmKitModule.clearMissionComplete(alarmId);
}

/**
 * Get debug log from the native intent. The intent writes to UserDefaults
 * since print() doesn't show in Xcode console for LiveActivityIntents.
 * Call this from JS after testing to see what the intent did.
 */
export function getDebugLog(): string[] {
  return ExpoAlarmKitModule.getDebugLog();
}

export function clearDebugLog(): void {
  ExpoAlarmKitModule.clearDebugLog();
}

/**
 * Get the launch payload if the app was opened from an alarm dismiss/snooze intent.
 * The payload contains the alarmId and payload string (or null if not provided).
 * Note: The payload is cleared after retrieval, so subsequent calls will return null.
 * @returns The launch payload or null if not launched from an alarm.
 */
export function getLaunchPayload(): LaunchPayload | null {
  return ExpoAlarmKitModule.getLaunchPayload();
}

// Default export object for namespace-style usage
const ExpoAlarmKit = {
  configure,
  requestAuthorization,
  generateUUID,
  scheduleAlarm,
  scheduleRepeatingAlarm,
  cancelAlarm,
  getAllAlarms,
  clearAllAlarms,
  removeAlarm,
  setMissionComplete,
  clearMissionComplete,
  getDebugLog,
  clearDebugLog,
  getLaunchPayload,
};

export default ExpoAlarmKit;

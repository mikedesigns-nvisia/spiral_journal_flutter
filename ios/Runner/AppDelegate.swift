import Flutter
import UIKit
import BackgroundTasks

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let backgroundTaskIdentifier = "com.spiraljournal.daily-processing"
  private var backgroundChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Set up background task scheduling
    setupBackgroundTasks()
    
    // Set up method channel for background tasks
    setupMethodChannel()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func setupMethodChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    
    backgroundChannel = FlutterMethodChannel(name: "spiral_journal/background_tasks", binaryMessenger: controller.binaryMessenger)
    
    backgroundChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      self?.handleMethodCall(call: call, result: result)
    }
  }
  
  private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "registerBackgroundTask":
      registerBackgroundTask(result: result)
    case "scheduleDailyProcessing":
      scheduleDailyProcessing(arguments: call.arguments, result: result)
    case "cancelBackgroundTasks":
      cancelBackgroundTasks(result: result)
    case "getBackgroundTaskStatus":
      getBackgroundTaskStatus(result: result)
    case "hasBackgroundRefreshPermission":
      hasBackgroundRefreshPermission(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func setupBackgroundTasks() {
    if #available(iOS 13.0, *) {
      BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { [weak self] task in
        self?.handleDailyProcessing(task: task as! BGAppRefreshTask)
      }
    }
  }
  
  @available(iOS 13.0, *)
  private func handleDailyProcessing(task: BGAppRefreshTask) {
    print("IOSBackgroundScheduler: Background task started")
    
    // Set expiration handler
    task.expirationHandler = {
      print("IOSBackgroundScheduler: Background task expired")
      task.setTaskCompleted(success: false)
    }
    
    // Execute the daily processing via Flutter
    backgroundChannel?.invokeMethod("executeDailyProcessing", arguments: nil) { result in
      if let resultDict = result as? [String: Any], let success = resultDict["success"] as? Bool {
        print("IOSBackgroundScheduler: Daily processing completed with success: \(success)")
        task.setTaskCompleted(success: success)
      } else {
        print("IOSBackgroundScheduler: Daily processing failed")
        task.setTaskCompleted(success: false)
      }
    }
  }
  
  private func registerBackgroundTask(result: @escaping FlutterResult) {
    if #available(iOS 13.0, *) {
      result(true)
    } else {
      result(false)
    }
  }
  
  private func scheduleDailyProcessing(arguments: Any?, result: @escaping FlutterResult) {
    guard #available(iOS 13.0, *) else {
      result(false)
      return
    }
    
    guard let args = arguments as? [String: Any],
          let identifier = args["identifier"] as? String,
          let earliestBeginDateSeconds = args["earliestBeginDate"] as? TimeInterval else {
      result(false)
      return
    }
    
    let request = BGAppRefreshTaskRequest(identifier: identifier)
    request.earliestBeginDate = Date(timeIntervalSince1970: earliestBeginDateSeconds)
    
    do {
      try BGTaskScheduler.shared.submit(request)
      print("IOSBackgroundScheduler: Successfully scheduled background task for \(request.earliestBeginDate?.description ?? "unknown")")
      result(true)
    } catch {
      print("IOSBackgroundScheduler: Failed to schedule background task: \(error)")
      result(false)
    }
  }
  
  private func cancelBackgroundTasks(result: @escaping FlutterResult) {
    if #available(iOS 13.0, *) {
      BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundTaskIdentifier)
      result(true)
    } else {
      result(false)
    }
  }
  
  private func getBackgroundTaskStatus(result: @escaping FlutterResult) {
    if #available(iOS 13.0, *) {
      let status: [String: Any] = [
        "backgroundRefreshStatus": UIApplication.shared.backgroundRefreshStatus.rawValue,
        "isBackgroundTaskSupported": true
      ]
      result(status)
    } else {
      let status: [String: Any] = [
        "backgroundRefreshStatus": UIApplication.shared.backgroundRefreshStatus.rawValue,
        "isBackgroundTaskSupported": false
      ]
      result(status)
    }
  }
  
  private func hasBackgroundRefreshPermission(result: @escaping FlutterResult) {
    let hasPermission = UIApplication.shared.backgroundRefreshStatus == .available
    result(hasPermission)
  }
}

import Foundation
import os.log
import UserNotifications
import UIKit
import ExposureNotification

@objc(ExposureNotificationModule)
public class ExposureNotificationModule: RCTEventEmitter {
    
    private let notificationCenter = NotificationCenter.default
    
    public override init() {
        super.init()
        setupNotifications()
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    /// list events
    public override func supportedEvents() -> [String]! {
        return ["exposureEvent"]
    }
    
    public override func constantsToExport() -> [AnyHashable : Any]! {
        return [:]
    }
    
    @objc
    public override static func requiresMainQueueSetup() -> Bool {
        return true
    }
    
    @objc func configure(_ configData: NSDictionary, resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
      os_log("Request to configure module, %{PRIVATE}@", log: OSLog.setup, type: .debug, configData)
      guard let configDict = configData as? [String: Any] else {
          os_log("Error configuring module, no dictionary passwed in.", log: OSLog.setup, type: .error)
          return resolve(false)
      }

      guard let serverURL = configDict["serverURL"] as? String, let refresh = configDict["refreshToken"] as? String, let token = configDict["authToken"] as? String else {
          os_log("Error configuring module, server url, refresh token or auth missing is missing", log: OSLog.setup, type: .error)
          return resolve(false)
      }
      
      guard !serverURL.isEmpty, !refresh.isEmpty, !token.isEmpty else {
          os_log("Error configuring module, server url, refresh token or auth token is empty", log: OSLog.setup, type: .error)
          return resolve(false)
      }
        
      let configData = Storage.Config(
        refreshToken: refresh,
        serverURL: serverURL,
        keyServerUrl: configDict["keyServerUrl"] as? String ?? serverURL,
        keyServerType: Storage.KeyServerType (rawValue: configDict["keyServerType"] as! String) ?? Storage.KeyServerType.NearForm,
        checkExposureInterval: configDict["exposureCheckFrequency"] as? Int ?? 180,
        storeExposuresFor: configDict["storeExposuresFor"] as? Int ?? 14,
        notificationTitle: configDict["notificationTitle"] as? String ?? "Close Contact Warning",
        notificationDesc: configDict["notificationDesc"] as? String ?? "The COVID Tracker App has detected that you may have been exposed to someone who has tested positive for COVID-19.",
        authToken: token,
        fileLimit: configDict["fileLimit"] as? Int ?? 3,
        notificationRepeat: configDict["notificationRepeat"] as? Int ?? 0,
        callbackNumber: configDict["callbackNumber"] as? String ?? "",
        analyticsOptin: configDict["analyticsOptin"] as? Bool ?? false
      )

      Storage.shared.updateAppSettings(configData)
      
      resolve(true)
    }

    @objc public func cancelNotifications() {
        if #available(iOS 13.5, *) {
            os_log("Cancel repeat notifications", log: OSLog.setup, type: .debug)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [ExposureCheck.REPEAT_NOTIFICATION_ID])
        } else {
            // Nothing to do
        }
    }

    @objc public func authoriseExposure(_ resolve: @escaping RCTPromiseResolveBlock,
                                        rejecter reject: @escaping RCTPromiseRejectBlock) {
        if #available(iOS 13.5, *) {
            os_log("Cancelling notifications", log: OSLog.setup, type: .debug)
            ExposureProcessor.shared.authoriseExposure(resolve, rejecter: reject)
        } else {
            resolve("unavailable")
        }
    }
    
    @objc public func exposureEnabled(_ resolve: RCTPromiseResolveBlock,
                                      rejecter reject: RCTPromiseRejectBlock) {
        if #available(iOS 13.5, *) {
            ExposureProcessor.shared.exposureEnabled(resolve, rejecter: reject)
        } else {
            resolve("unavailable")
        }
    }

    @objc public func isAuthorised(_ resolve: RCTPromiseResolveBlock,
                                      rejecter reject: RCTPromiseRejectBlock) {
        if #available(iOS 13.5, *) {
            ExposureProcessor.shared.isAuthorised(resolve, rejecter: reject)
        } else {
            resolve("unavailable")
        }
    }

    @objc public func isSupported(_ resolve: RCTPromiseResolveBlock,
                                      rejecter reject: RCTPromiseRejectBlock) {
        if #available(iOS 13.5, *) {
            resolve(true)
        } else {
            resolve(false)
        }
    }
    
    @objc public func canSupport(_ resolve: RCTPromiseResolveBlock,
                                      rejecter reject: RCTPromiseRejectBlock) {
        
      resolve(UIDevice.supportsIOS13)
    }

    @objc public func status(_ resolve: @escaping RCTPromiseResolveBlock,
                                      rejecter reject: RCTPromiseRejectBlock) {
        if #available(iOS 13.5, *) {
          ExposureProcessor.shared.status(resolve, rejecter: reject)
        } else {
          resolve(["state": "unavailable"])
        }
    }
  
    @objc public func start(_ resolve: @escaping RCTPromiseResolveBlock,
                            rejecter reject: @escaping RCTPromiseRejectBlock) {
        if #available(iOS 13.5, *) {
          ExposureProcessor.shared.start(resolve, rejecter: reject)
        } else {
            //nothing to do here
            resolve(false)
        }
    }

    @objc public func pause(_ resolve: @escaping RCTPromiseResolveBlock,
                            rejecter reject: @escaping RCTPromiseRejectBlock) {
        if #available(iOS 13.5, *) {
          ExposureProcessor.shared.pause(resolve, rejecter: reject)
        } else {
            //nothing to do here
            resolve(false)
        }
    }
    
    @objc public func stop(_ resolve: @escaping RCTPromiseResolveBlock,
                           rejecter reject: @escaping RCTPromiseRejectBlock) {
       if #available(iOS 13.5, *) {
        ExposureProcessor.shared.stop(resolve, rejecter: reject)
       } else {
           ///nothing to do here
          resolve(false)
       }
    }

    @objc public func getDiagnosisKeys(_ resolve: @escaping RCTPromiseResolveBlock,
                                        rejecter reject: @escaping RCTPromiseRejectBlock) {
       if #available(iOS 13.5, *) {
           ExposureProcessor.shared.getDiagnosisKeys(resolve, rejecter: reject)
       } else {
           resolve([])
       }
    }
    
    @objc public func getCloseContacts(_ resolve: @escaping RCTPromiseResolveBlock,
                                     rejecter reject: @escaping RCTPromiseRejectBlock) {
      if #available(iOS 13.5, *) {
          ExposureProcessor.shared.getCloseContacts(resolve, rejecter: reject)
      } else {
          resolve([])
      }
    }
  
    @objc public func getLogData(_ resolve: @escaping RCTPromiseResolveBlock,
                                     rejecter reject: @escaping RCTPromiseRejectBlock) {
      if #available(iOS 13.5, *) {
          ExposureProcessor.shared.getLogData(resolve, rejecter: reject)
      } else {
          resolve([])
      }
    }

    @objc public func getConfigData(_ resolve: @escaping RCTPromiseResolveBlock,
                                    rejecter reject: @escaping RCTPromiseRejectBlock) {
        if #available(iOS 13.5, *) {
            ExposureProcessor.shared.getConfigData(resolve, rejecter: reject)
        } else {
            resolve([])
        }
        
    }
    
    @objc public func triggerUpdate(_ resolve: @escaping RCTPromiseResolveBlock,
                                   rejecter reject: @escaping RCTPromiseRejectBlock) {
        resolve(false)
    }
  
    @objc public func simulateExposure(_ timeDelay: Int) {
        
        if #available(iOS 13.5, *) {
            os_log("Reqwuest to simulate exposure after %f", log: OSLog.setup, type: .debug, timeDelay)
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(timeDelay)) {
                ExposureProcessor.shared.checkExposureForeground(false, true, true)
            }
        }
    }

    @objc static public func registerBackgroundProcessing() {
         if #available(iOS 13.5, *) {
            ExposureProcessor.shared.registerBackgroundProcessing()
         } else {
             os_log("Skipping regustering backgroiund as not 13.5 or higher", log: OSLog.setup, type: .debug)
        }
    }
     
    @objc public func checkExposure(_ readExposureDetails: Bool, _ skipTimeCheck: Bool) {
        if #available(iOS 13.5, *) {
            ExposureProcessor.shared.checkExposureForeground(readExposureDetails, skipTimeCheck, false)
        }
    }
     
    @objc public func deleteAllData(_ resolve: @escaping RCTPromiseResolveBlock,
                                    rejecter reject: @escaping RCTPromiseRejectBlock) {
        if #available(iOS 13.5, *) {
            ExposureProcessor.shared.deleteAllData(resolve, rejecter: reject)
            cancelNotifications()
        } else {
            resolve(true)
        }
    }

    @objc public func deleteExposureData(_ resolve: @escaping RCTPromiseResolveBlock,
                                    rejecter reject: @escaping RCTPromiseRejectBlock) {
        if #available(iOS 13.5, *) {
            ExposureProcessor.shared.deleteExposureData(resolve, rejecter: reject)
        } else {
            resolve(true)
        }
    }

    @objc public func bundleId(_ resolve: @escaping RCTPromiseResolveBlock,
                                    rejecter reject: @escaping RCTPromiseRejectBlock) {
        resolve(Bundle.main.bundleIdentifier!)
    }
    
    @objc public func version(_ resolve: @escaping RCTPromiseResolveBlock,
                                    rejecter reject: @escaping RCTPromiseRejectBlock) {
        let version = Storage.shared.version()
        
        resolve(version)
    }
    
    private func setupNotifications() {
        notificationCenter.addObserver(self,
              selector: #selector(onStatusChanged),
              name: .onStatusChanged,
              object: nil
        )
    }
    

   @objc private func onStatusChanged(_ notification: Notification) {
      var status: [String: Any] = [:]
    
      if #available(iOS 13.5, *) {
        guard let item = notification.object as? ENStatus else {
          os_log("No data in status change event", log: OSLog.exposure, type: .debug)
          return
        }
        
        switch item {
          case .active:
              status["state"] = "active"
          case .unknown:
              status["state"] = "unknown"
          case .disabled:
              status["state"] = "disabled"
              status["type"] = ["exposure"]
          case .bluetoothOff:
              status["state"] = "disabled"
              status["type"] = ["bluetooth"]
          case .restricted:
              status["state"] = "restricted"
          case .paused:
              status["state"] = "disabled"
              status["type"] = ["paused"]
          case .unauthorized:
              status["state"] = "disabled"
              status["type"] = ["unauthorized"]
          @unknown default:
              status["state"] = "unavailable"
        }
        if ExposureManager.shared.isPaused() && (status["state"] as! String == "disabled" || status["state"] as! String == "unknown") {
           status["state"] = "disabled"
           status["type"] = ["paused"]
        }
        if ExposureManager.shared.isStopped() && (status["state"] as! String == "disabled" || status["state"] as! String == "unknown") {
           status["state"] = "disabled"
           status["type"] = ["stopped"]
        }
        os_log("Status of exposure service has changed %@", log: OSLog.exposure, type: .debug, status)
        sendEvent(withName: "exposureEvent", body: ["onStatusChanged": status])
      }
  }
}

extension OSLog {
    private static var subsystem = Bundle.main.bundleIdentifier!

    static let setup = OSLog(subsystem: subsystem, category: "setup")
    static let exposure = OSLog(subsystem: subsystem, category: "exposure")
    static let checkExposure = OSLog(subsystem: subsystem, category: "checkExposure")
    static let storage = OSLog(subsystem: subsystem, category: "storage")
    
}



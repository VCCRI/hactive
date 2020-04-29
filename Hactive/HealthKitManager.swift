//
//  HealthKitManager.swift
//  Hactive
//
//  Created by Adam Goldberg on 8/8/18.
//  Copyright © 2018 VCCRI. All rights reserved.
//

import Foundation
import HealthKit

protocol HeartRateDelegate {
    func heartRateUpdated(heartRateSamples: [HKSample])
}

class HealthKitManager: NSObject {
    
    static let sharedInstance = HealthKitManager()
    
    private override init() {}
    
    let healthStore = HKHealthStore()
    
    var anchor: HKQueryAnchor?
    
    var heartRateDelegate: HeartRateDelegate?
    
    // access HealthKit API logic.
    func authorizeHealthKit(_ completion: @escaping ((_ success: Bool, _ error: Error?) -> Void)) {
        
        guard let heartRateType: HKQuantityType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return
        }
        
        guard let distanceWalkingRunningType: HKQuantityType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            return
        }
        
        guard let flightsClimbedType: HKQuantityType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) else {
            return
        }
        
        guard let stepCountType: HKQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }
        
        guard let restingHeartRate: HKQuantityType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            return
        }
        
        guard let bodyMass: HKQuantityType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return
        }
        
        guard  let dateOfBirth = HKObjectType.characteristicType(forIdentifier: .dateOfBirth) else {
            return
        }
        
        // Permissions to write and read from HealthKit
        let typesToShare = Set([HKObjectType.workoutType(), heartRateType])
        let typesToRead = Set([HKObjectType.workoutType(), heartRateType, HKSeriesType.workoutRoute(), restingHeartRate, bodyMass, dateOfBirth, distanceWalkingRunningType, flightsClimbedType, stepCountType])
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            print("Was authorisation successful? \(success)")
            completion(success, error)
        }
    }
    
}

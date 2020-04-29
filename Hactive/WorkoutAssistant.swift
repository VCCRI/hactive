//
//  WorkoutAssistant.swift
//  Hactive
//
//  Created by Adam Goldberg on 8/8/18.
//  Copyright © 2018 VCCRI. All rights reserved.
//

import Foundation
import HealthKit
import MapKit

class WorkoutAssistant {
    
    class func loadWorkouts(completion: @escaping (([HKWorkout]?, Error?) -> Swift.Void)) {
        
        // Uncomment this line to get workouts of type .walking and .running
        // let workoutWalkingPredicate = [HKQuery.predicateForWorkouts(with: .walking), HKQuery.predicateForWorkouts(with: .running)]
        
        // Sorts pull request in ascending order
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

        let query = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: nil, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [sortDescriptor]) { (query, samples, error) in
                DispatchQueue.main.async {
                    guard let samples = samples as? [HKWorkout], error == nil else {
                        completion(nil, error)
                        return
                    }
                    // returns completion successful
                    completion(samples, nil)
            }
        }
        HKHealthStore().execute(query)
    }
    
    
    class func getWeightFromHealthkit(completion: @escaping ((Double, Error?) -> Swift.Void)) {
        let weightType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let weightQuery = HKSampleQuery(sampleType: weightType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { (query, results, error) in
            if let result = results?.first as? HKQuantitySample {
                let weight = result.quantity.doubleValue(for: HKUnit(from: "g"))/1000
                completion(weight, nil)
            } else {
                print("Error: Did not get weight \n Results => \(String(describing: results)), error => \(String(describing: error))")
            }
        }
        HKHealthStore().execute(weightQuery)

    }
    
    class func getAgeFromHealthkit(completion: @escaping ((Double, Error?) -> Swift.Void)) {
        do {
            let birthdayComponents =  try HKHealthStore().dateOfBirthComponents()

            let today = Date()
            let calendar = Calendar.current
            let todayDateComponents = calendar.dateComponents([.year], from: today)
            let thisYear = todayDateComponents.year!
            let age = Double(thisYear - birthdayComponents.year!)
            completion(age, nil)
        } catch {
            print("Error")
        }
        
    }
    
    
    // Gets resting heart-rate from HealthKit. This function isn't utilised.
    class func getRHRDataFromHealthkit(completion: @escaping ((Double, Error?) -> Swift.Void)) {
        
        let restingHRType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.restingHeartRate)!
        let restingHeartQuery = HKSampleQuery(sampleType: restingHRType, predicate: nil, limit: 1, sortDescriptors: nil) { (query, restingHR, error) in
            if let result = restingHR?.first as? HKQuantitySample {
                let currentHeartBeatRecording = result.quantity.doubleValue(for: HKUnit(from: "count/min"))
                completion(currentHeartBeatRecording, nil)
            } else {
                print("Error: Did not get RHR \n restingHR => \(String(describing: restingHR)), error => \(String(describing: error))")
            }
        }
        HKHealthStore().execute(restingHeartQuery)
        
    }

    // Gets heart rate data from Healthkit. Uses the start-date and end-date of a workout to determine which HR data to acquire.
    class func fetchLatestHeartRateSampleFromHealthkit(singleWorkout: HKWorkout, startDate: Date, endDate: Date, completion: @escaping (([HKSample], Error?) -> Swift.Void))  {
        
        guard let sampleType = HKObjectType
            .quantityType(forIdentifier: .heartRate) else {
                completion([], nil)
                return
        }
        
        /// Predicate for specifying start and end dates for the query
        let predicate = HKQuery
            .predicateForSamples(
                withStart: startDate,
                end: endDate,
                options: .strictEndDate)
        
        // To gather data straight from the workout. singleWorkout will be unsed for now.
        // let workoutPredicate = HKQuery.predicateForObjects(from: singleWorkout)
        
        /// Set sorting by date.
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true)
        
        /// Create the query
        let query = HKSampleQuery(
            sampleType: sampleType,
            predicate: predicate,
            limit: Int(HKObjectQueryNoLimit),
            sortDescriptors: [sortDescriptor]) { (_, results, error) in
                
                guard error == nil else {
                    print("Error: \(error!.localizedDescription)")
                    return
                }
                completion(results!, nil)
        }
        
        HKHealthStore().execute(query)
    }
    
    // Gets location data. Also uses start date and end date of a workout
    class func fetchLocations(singleWorkout: HKWorkout, startDate: Date, endDate: Date, completion: @escaping (([CLLocation], Error?) -> Swift.Void))  {
    
        // Step 1: Query for samples of type HKWorkoutRoute associated to your workout
        let workoutRouteType = HKSeriesType.workoutRoute()
        let workoutPredicate = HKQuery.predicateForObjects(from: singleWorkout)
        var totalWorkouts = [CLLocation]()
        
        let workoutRoutesQuery = HKSampleQuery(sampleType: workoutRouteType, predicate: workoutPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil)
        { (query, sample, error) in
            guard let routeSamples = sample as? [HKWorkoutRoute] else { return }
            if (routeSamples.count == 0) {
                completion([], nil)
            }
            // Step 2: Query for location data from the samples
            for routeSample in routeSamples {
                let locationQuery = HKWorkoutRouteQuery(route: routeSample) {
                    (routeQuery, location, done, error) in
                    
                    for item in location! {
                        totalWorkouts.append(item)
                    }
                    
                    if done {
                        // The query returned all the location data associated with the route.
                        // Do something with the complete data set.
                        completion(totalWorkouts, nil)
                    }
                }
                HKHealthStore().execute(locationQuery)
            }
        }

        HKHealthStore().execute(workoutRoutesQuery)
    }
    
    // Gets location data. Also uses start date and end date of a workout
    class func fetchStepCount(singleWorkout: HKWorkout, startDate: Date, endDate: Date, completion: @escaping ((Double, Error?) -> Swift.Void))  {

        guard let sampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) else {
                completion(0, nil)
                return
        }

        /// Predicate for specifying start and end dates for the query
        let predicate = HKQuery
            .predicateForSamples(
                withStart: startDate,
                end: endDate,
                options: .strictEndDate)

        /// Create the query
        let query = HKSampleQuery(
            sampleType: sampleType,
            predicate: predicate,
            limit: Int(HKObjectQueryNoLimit),
            sortDescriptors: nil) { (query, results, error) in
                
                guard error == nil else {
                    print("Error: \(error!.localizedDescription)")
                    return
                }
                var counter: Double = 0
                for steps in results as! [HKQuantitySample] {
                    if steps.description.contains("Watch") {
                        counter += steps.quantity.doubleValue(for: HKUnit.count())
                    }
                }
                completion(counter, nil)
        }
        
        HKHealthStore().execute(query)
        
    }
    
}

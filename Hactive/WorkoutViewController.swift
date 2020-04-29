//
//  WorkoutViewController.swift
//  Hactive
//
//  Created by Adam Goldberg on 29/8/18.
//  Copyright © 2018 VCCRI. All rights reserved.
//

import UIKit
import HealthKit
import MapKit
import SpriteKit
import Charts
import CoreData
import CSV
import MessageUI
import Foundation

// Manage all data pulled from HealthKit
struct Recording {
    var timeStamp: Date = Date()
    var totalEnergy: Double = 0
    var deltaEnergy: Double = 0
    var bpm: Double = 0
    var vDisplacement: Double = 0
    var hDisplacement: Double = 0
    var vhSlope: Double = 0
    var latitude: Double = 0
    var longitude: Double = 0
    var altitude: Double = 0
    var speed: Double = -1
}

struct HeartSampleRecording {
    var timeStamp: Date = Date()
    var bpm: Double = 0
}

// Used to display graphs
struct CellData {
    let chart: LineChartData?
    let message: String?
}

// Used to title and change workout details
class DBWorkout: NSManagedObject {
    var title: String?
    var healthInfo: String?
    var startDate: Date?
    var age: Int?
    var weight: Int?
}

protocol isAbleToReceiveData {
    func callOnReturn(didChange: Bool)  //data: string is an example parameter
}

class WorkoutViewController: UIViewController, isAbleToReceiveData {
    
    // After Label pop-up is dismissed, check if age or weight is changed. If it is, recalculated zones based off new data.
    func callOnReturn(didChange: Bool) {
        if didChange {
            self.getMeta(singleWorkout: workout, startDate: workout.startDate, endDate: workout.endDate)
            self.getHeartRates(singleWorkout: workout, startDate: workout.startDate, endDate: workout.endDate)
            self.getLocation(singleWorkout: workout, startDate: workout.startDate, endDate: workout.endDate)
            
            self.rawHeartSamples = []; self.allHealthSamples = []; self.locationAndHeart = []; self.heartSamples = []; self.zones = []; self.locationSamples = []; self.zonesAsTime = []; self.bufferStart = 60; self.bufferEnd = 60; self.receivedHeartRateData = false; self.receivedLocationData = false; self.data = []; self.datasource = []
        }
        self.fetchWorkoutCoreData()
    }
    

    var workout: HKWorkout!
    var age: Double = 60 // dummy default value
    var workoutNumber: Int = -1 // Label for workout
    private var heartSamples: [HKSample] = [] // A collection of only the heart recordings of this workout
    private var locationSamples: [CLLocation] = [] // A collection of only the location data of this workout
    private var locationAndHeart: [Recording] = [] // A collection of all the heart and location recordings for this workout
    private var zones: [(Int, Int)] = [] // Array of tuples to indicate the start and end position of HRDPs
    private var bufferStart: Int = 60 // Buffer start set to 60 seconds. This value can be changed to any value.
    private var bufferEnd: Int = 60  // Buffer end set to 60 seconds. This value can be changed to any value.
    private var receivedHeartRateData: Bool = false
    private var receivedLocationData: Bool = false
    private var zonesAsTime: [(Date, Date)] = []
    
    private var titleFromDB: String = "" // Title of workout, optional
    private var weightFromDB: Int = 60 // Weight
    private var ageFromDB: Int = 60 // Age, optional, default to 60
    private var healthInfoFromDB: String = "" // Age, optional, default to 60
    private var stepCount: String = ""
    
    private var HRDPMaxHR: Int = 0 // Max HR found in an HRDP
    private var HRDPMaxLength: Int = 0 // Max Length of an HRDP
    
    private var rawHeartSamples: [HeartSampleRecording] = [] // uninterpolated heart rate data
    
    private var allHealthSamples: [Recording] = []
    
    @IBOutlet weak var tableView: UITableView! // to managed the table
    @IBOutlet weak var exportData: UIButton!
    
    
    var data: [CellData] = [] // the object of our table list
    
    var datasource: [[Recording]] = []
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.getMeta(singleWorkout: workout, startDate: workout.startDate, endDate: workout.endDate)
        self.getHeartRates(singleWorkout: self.workout, startDate: self.workout.startDate, endDate: self.workout.endDate)
        self.getLocation(singleWorkout: self.workout, startDate: self.workout.startDate, endDate: self.workout.endDate)
        
        self.tableView.register(CustomCell.self, forCellReuseIdentifier: "custom")
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 250
        self.fetchWorkoutCoreData()
    }
    
    @IBAction func exportDataAction(_ sender: Any) {
        let alert = UIAlertController(title: "Are you sure you would like to export your data?", message: "The data will be sent to an email of your choice.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: nil))
        alert.addAction(UIAlertAction(title: "Export", style: UIAlertAction.Style.default, handler: { action in
            self.csv()
        }))
        
        self.present(alert, animated: true, completion: nil)
    
    }
    
    func csv() {
        
        let csvDB = self.dataFromDB()
        let csvRawHealth = self.rawHealthData()
        let csvInterpolated = self.InterpolatedHealthData()
        let csvZone = self.zonesData()
        let csvExtraData = self.getExtraData()
        
        /* Another method for extracting files. Send straight to email
         self.sendEmail(csvData: [csvDB, csvRawHealth, csvInterpolated, csvZone])
        */
        self.exportToFile(dataSets: [("Meta Data", csvDB), ("Raw Health Data", csvRawHealth), ("Interpolated Health Data", csvInterpolated), ("Heart Rate Dynamic Profile Workout Zones (start and end indices)", csvZone), ("Extra Data", csvExtraData)])
    }
    
    func exportToFile(dataSets: [(String, Data)]) {
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Workout-\(self.workoutNumber)-Data.csv")!
        
        var dataAsString: String = ""
        for data in dataSets {
            dataAsString.append("\n\n \(data.0) \n")
            dataAsString.append(String(decoding: data.1, as: UTF8.self))
        }
        
        do {
                try dataAsString.write(to: path, atomically: true, encoding: String.Encoding.utf8)
                let vc = UIActivityViewController(activityItems: [path], applicationActivities: [])
                vc.excludedActivityTypes = [
                    UIActivity.ActivityType.assignToContact,
                    UIActivity.ActivityType.saveToCameraRoll,
                    UIActivity.ActivityType.postToFlickr,
                    UIActivity.ActivityType.postToVimeo,
                    UIActivity.ActivityType.postToTencentWeibo,
                    UIActivity.ActivityType.postToTwitter,
                    UIActivity.ActivityType.postToFacebook,
                    UIActivity.ActivityType.openInIBooks
                ]
                present(vc, animated: true, completion: nil)

        } catch {
            print("Failed to create file: \(error)")
        }
        
    }
    
    func sendEmail(csvData: [Data]) {
        
        if MFMailComposeViewController.canSendMail() {
            
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            
            mail.addAttachmentData(csvData[0], mimeType: "csv", fileName: "Workout-\(self.workoutNumber)-meta-data.csv")
            mail.addAttachmentData(csvData[1], mimeType: "csv", fileName: "Workout-\(self.workoutNumber)-raw-healthkit-data.csv")
            mail.addAttachmentData(csvData[2], mimeType: "csv", fileName: "Workout-\(self.workoutNumber)-Interpolated-data.csv")
            mail.addAttachmentData(csvData[3], mimeType: "csv", fileName: "Workout-\(self.workoutNumber)-Heart-rate-dynamic-profile-zones.csv")
            mail.addAttachmentData(csvData[4], mimeType: "csv", fileName: "Workout-\(self.workoutNumber)-extra-data.csv")
            
            mail.setMessageBody("Data", isHTML: true)
            
            present(mail, animated: true)
        } else {
            let alert = UIAlertController(title: "Could Not Send Email", message: "Your device could not send the e-mail. Please check e-mail configuration and try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)

        }
        
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        // Dismiss the mail compose view controller.
        controller.dismiss(animated: true, completion: nil)
    }
    
    private func dataFromDB() -> Data {
        
        let csv = try! CSVWriter(stream: .toMemory())
        
        try! csv.write(row: ["Title", "Weight", "Age", "Description", "MaxHR", "Longest HRDP in Workout"])
        try! csv.write(row: [self.titleFromDB, String(self.weightFromDB), String(self.ageFromDB), self.healthInfoFromDB, String(self.HRDPMaxHR), String(self.HRDPMaxLength)])
        
        csv.stream.close()
        
        let csvData = csv.stream.property(forKey: .dataWrittenToMemoryStreamKey) as! Data
        
        return csvData
    }
    
    private func getExtraData() -> Data {
        
        let csv = try! CSVWriter(stream: .toMemory())
        var totalDistance = ""
        var totalEnergyBurned = ""
        var totalFlightsClimbed = ""
        
        if let unwrapped = self.workout.totalFlightsClimbed {
            totalFlightsClimbed = unwrapped.description
        }
        if let unwrapped = self.workout.totalEnergyBurned {
            totalEnergyBurned = unwrapped.description
        }
        
        if let unwrapped = self.workout.totalDistance {
            totalDistance = unwrapped.description
        }
    
        try! csv.write(row: ["Duration (Sec)", "stepCount", "totalDistance km", "totalEnergyBurned", "totalFlightsClimbed" ])
        try! csv.write(row: [self.workout.duration.description, self.stepCount, totalDistance, totalEnergyBurned, totalFlightsClimbed])
        
        csv.stream.close()
        
        let csvData = csv.stream.property(forKey: .dataWrittenToMemoryStreamKey) as! Data
        
        return csvData
    }
    
    private func rawHealthData() -> Data {
        
        let csv = try! CSVWriter(stream: .toMemory())
        
        try! csv.write(row: ["Time-Stamp", "BPM"])
        for data in self.rawHeartSamples {
            let HKTime = self.convertUTCtoHKT(UTC: data.timeStamp)
            try! csv.write(row: [HKTime, String(data.bpm)])
        }
        
        csv.stream.close()
        
        let csvData = csv.stream.property(forKey: .dataWrittenToMemoryStreamKey) as! Data
        
        return csvData
    }
    
    private func convertUTCtoHKT(UTC: Date) -> String {
        
        // Convert UTC to HKT, add 8hrs 
        var HKT = UTC
        HKT.addTimeInterval(28800)
        return HKT.description
        
    }
    
    private func zonesData() -> Data {
        
        let csv = try! CSVWriter(stream: .toMemory())
        
        try! csv.write(row: ["Start-Time-Stamp", "End-Time-Stamp"])
        for data in self.zonesAsTime {
            try! csv.write(row: [self.convertUTCtoHKT(UTC: data.0), self.convertUTCtoHKT(UTC: data.1)])
        }
        
        csv.stream.close()
        
        let csvData = csv.stream.property(forKey: .dataWrittenToMemoryStreamKey) as! Data
        
        return csvData
    }
    
    private func InterpolatedHealthData() -> Data {
        
        let csv = try! CSVWriter(stream: .toMemory())
        
        try! csv.write(row: ["Time-Stamp", "Total-Energy", "Delta-Energy", "BPM", "Vertical-Displacement", "Horizontal-Displacement" , "Vertical-Horizontal-Slope", "Latitude", "Longitude", "Altitude", "Speed MPS"])
        
        for data in self.self.allHealthSamples {
            let temp = [self.convertUTCtoHKT(UTC: data.timeStamp), String(data.totalEnergy), String(data.deltaEnergy), String(data.bpm), String(data.vDisplacement), String(data.hDisplacement), String(data.vhSlope), String(data.latitude), String(data.longitude), String(data.altitude), String(data.speed)]
            try! csv.write(row: temp)
        }
        
        csv.stream.close()
        
        let csvData = csv.stream.property(forKey: .dataWrittenToMemoryStreamKey) as! Data
        
        return csvData
    }
    
    // Gets data saved in core data related to this workout
    func fetchWorkoutCoreData() {
        let workoutSD = self.workout.startDate.description
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Workout")
        request.predicate = NSPredicate(format: "startDate = %@", workoutSD)
        request.returnsObjectsAsFaults = false
        // rapped in do incase core data failed
        
        self.titleFromDB = ""
        self.weightFromDB = 0
        self.ageFromDB = 60
        self.healthInfoFromDB = ""
        do {
            let result = try context.fetch(request)
            if (result.count > 0) {
                let data = result.last as! NSManagedObject
                
                if let titleData = data.value(forKey: "title") as? String {
                    self.titleFromDB = titleData
                }
                
                if let weightData = data.value(forKey: "weight") as? Int {
                    self.weightFromDB = weightData
                }
                
                if let ageData = data.value(forKey: "age") as? Int {
                    self.ageFromDB = ageData
                }
                
                if let healthData = data.value(forKey: "healthInfo") as? String {
                    self.healthInfoFromDB = healthData
                }
            }

        } catch {
            print("Failed")
        }
    }
    

    @IBAction func goBack(_ sender: Any) {
        performSegue(withIdentifier: "backButtonSegue", sender: self)
    }

    func getHeartRates(singleWorkout: HKWorkout, startDate: Date, endDate: Date) {
        WorkoutAssistant.fetchLatestHeartRateSampleFromHealthkit(singleWorkout: singleWorkout, startDate: startDate, endDate: endDate) { (samples, error) in
            self.heartSamples = samples
            self.receivedHeartRateData = true
            self.mergeHeartAndLocationData(startDate: startDate, endDate: endDate)
        }
    
    }
    
    func getMeta(singleWorkout: HKWorkout, startDate: Date, endDate: Date) {
        WorkoutAssistant.fetchStepCount(singleWorkout: singleWorkout, startDate: startDate, endDate: endDate) { (steps, error) in
            self.stepCount = String(steps)
        }
        
    }
    
    func getLocation(singleWorkout: HKWorkout, startDate: Date, endDate: Date) {
        WorkoutAssistant.fetchLocations(singleWorkout: singleWorkout, startDate: startDate, endDate: endDate) { (samples, error) in
            self.locationSamples = samples
            self.receivedLocationData = true
            self.mergeHeartAndLocationData(startDate: startDate, endDate: endDate)
        }
    }
    
    // Interpolated Heart rate data to handle missing values
    // Fills data for every second
    func interpolateHeartRateData() -> [HeartSampleRecording] {
        var heartBeatArray: [HeartSampleRecording] = []
        
        for (index, item) in self.heartSamples.enumerated() {
            
            let itemSample = item as? HKQuantitySample
            // converts HR recording into double
            let currentHeartBeatRecording = itemSample!.quantity.doubleValue(for: HKUnit(from: "count/min"))
            
            // ignores first value in the array for out of bounds error
            if (index != 0) {

                // finds the next time in self.heartSamples where a heartrate is recording by taking the time difference in seconds
                // between the current value and the value before this
                let intervalUntillNextRecording = round(item.startDate.timeIntervalSince(self.heartSamples[index-1].startDate))
                let previousItemSample = self.heartSamples[index-1] as? HKQuantitySample
                // converts HR recording into double
                let previousHeartBeatRecording = previousItemSample!.quantity.doubleValue(for: HKUnit(from: "count/min"))
                
                // gets the absolute value change in heart rate between current value and previous available heart rate recording
                let manipulationHeartBeatValue = (currentHeartBeatRecording - previousHeartBeatRecording)/intervalUntillNextRecording
                var manipulationHeartBeatValueVariation = manipulationHeartBeatValue
                let calendar = Calendar.current

                var i = 1

                // starts interpolating the data
                while (i < Int(intervalUntillNextRecording)) {

                    // creates a new date.
                    let newDate = calendar.date(byAdding: .second, value: i, to: previousItemSample!.startDate)
                    var synthesisedHeartSample:HeartSampleRecording = HeartSampleRecording()
                    synthesisedHeartSample.timeStamp = newDate!
                    // adds the HR increase amount to the previous value
                    synthesisedHeartSample.bpm = previousHeartBeatRecording + manipulationHeartBeatValueVariation
                    heartBeatArray.append(synthesisedHeartSample)
                    manipulationHeartBeatValueVariation += manipulationHeartBeatValue
                    i+=1

                    /* Example:
                     Say a BPM was recorded at time 11:00:01am of 70bpm
                     And the next BPM was recorded at time 11:00:05am of 75bpm (which is 4 seconds later)
                     The bpm has increased by 5
                     therefore 5 - 1 = 4, there are 3 spaces to fill, so 4/3 = 1.33
                     11:01:01am = 70
                     11:01:02am = 71.3
                     11:01:03am = 72.6
                     11:01:04am = 73.9
                     11:01:05am = 75
                    */
                }

            }
            
            var realHeartSampleRecording:HeartSampleRecording = HeartSampleRecording()
            realHeartSampleRecording.timeStamp = item.startDate
            realHeartSampleRecording.bpm = currentHeartBeatRecording
            heartBeatArray.append(realHeartSampleRecording)
            rawHeartSamples.append(realHeartSampleRecording)
            
        }
        
        // Watch produces inauthentic results when calebrating: ignore the first 5 values
        if (heartBeatArray.count > 5) {
            heartBeatArray.removeFirst(5)
        }
        return heartBeatArray
    }
    

    func convertLocationsArrayToHash() -> [String: CLLocation] {
        var locationDic = [String: CLLocation]()
        for item in self.locationSamples {
            locationDic[item.timestamp.description] = item
        }
        return locationDic
    }
    
    // Mergers to two data sets together
    func mergeHeartAndLocationData(startDate: Date, endDate: Date) {
        /*
        Energy expenditure calculations used (Also used in CardiacProfileR) are described in:
        
            Weyand, P. G., Smith, B. R., Puyau, M. R., & Butte, N. F. (2010).
            The mass-specific energy cost of human walking is set by stature.
            The Journal of Experimental Biology, 213(Pt 23), 3972–3979.
        
            Kawata, A., Shiozawa, N., & Makikawa, M. (2007).
            Estimation of Energy Expenditure during Walking Including UP/Down Hill.
            In R. Magjarevic & J. H. Nagel (Eds.), World Congress on Medical Physics And Biomedical Engineering 2006,
            441-444.
        */
        
        let Etm = 7.98*pow(Double(self.weightFromDB), -0.29)*Double(self.weightFromDB)
        
        // ensures the data has been received from WorkoutAssistant and there is enough data to work with
        if (!self.locationSamples.isEmpty && self.heartSamples.count > 15) {
            
            let locationDic = convertLocationsArrayToHash()
            
            let heartBeatArray = interpolateHeartRateData()
            
            for (index, heartRateItem) in heartBeatArray.enumerated() {
                
                var recording:Recording = Recording()
                recording.timeStamp = heartRateItem.timeStamp
                recording.bpm = heartRateItem.bpm
                
                // checks if there is a location for the given time
                if let item = locationDic[heartRateItem.timeStamp.description] {
                    
                    let indexOfItem = self.locationSamples.firstIndex(of: item)
                    // makes sure it's not at the beginning or end of array for out of bounds error
                    if (index != 0 && indexOfItem != 0) {
                        
                        // Remove outliers: hDistance > +-5 m/s above average walking speed
                        // Set to 0 if 0.5m < hDisplacement < 0.5m
                        let distance = item.distance(from: self.locationSamples[indexOfItem!-1])
                        if (distance < 0.2 && distance > -0.2) {
                            recording.hDisplacement = 0
                        } else {
                            recording.hDisplacement = distance
                        }
                        
                        // Remove outliers: -5 < vDistance < 5m
                        recording.vDisplacement = item.altitude - self.locationSamples[indexOfItem!-1].altitude

                        recording.latitude = item.coordinate.latitude
                        recording.longitude = item.coordinate.longitude
                        recording.altitude = item.altitude
                        recording.speed = item.speed
                        
                    }
                    
                    let rawVHSlope = recording.vDisplacement / recording.hDisplacement
                    
                    // Smooth slope to between -0.2 and 0.2
                    if (rawVHSlope > 0.2) {
                        recording.vhSlope = 0.2
                    } else if (rawVHSlope < -0.2) {
                        recording.vhSlope = -0.2
                    } else if (rawVHSlope.isNaN) {
                        recording.vhSlope = 0
                    } else {
                        recording.vhSlope = rawVHSlope
                    }
                    
                    let hEnergy = recording.hDisplacement * Etm // Horizontal energy
                    // Remove outliers where diff(totalEnergy) > 50 then prev/next non 0 value
                    recording.totalEnergy = hEnergy * (1+recording.vhSlope)
         
                    if (index != 0 && indexOfItem! != 0) {
                        // total_energy <- h_energy * (1+vh_slope) -> Total energy is always positive
                        // because vh_slope > -0.2 therefore: 0.2 < total_energy < 1.2
                        recording.deltaEnergy = recording.totalEnergy - self.locationAndHeart[index-1].totalEnergy
                    }
                }
                
                // remove outliers
                // energy should not change by more than 350 second-to-second. Treat as faulty
                if (abs(recording.deltaEnergy) > 350) {
                    recording.totalEnergy = 0
                    recording.deltaEnergy = 0
                    recording.hDisplacement = 0
                    recording.vDisplacement = 0
                    recording.vhSlope = 0
                }
                let serialQueue = DispatchQueue(label: "myqueue")
                
                serialQueue.sync {
                    self.locationAndHeart.append(recording)
                    self.allHealthSamples.append(recording)
                }
            }

            // After arrays have been merged and data has been interpolated, extract HRDPs
            zoneExtraction()
            activityExtraction(zones: self.zones)
            
            // Dispose of arrays
            self.locationAndHeart = []
            self.locationSamples = []
            self.heartSamples = []
            
        } else if (receivedHeartRateData && receivedLocationData) {
            // GPS failed to record location, total energy cannot be calculated
            let heartBeatArray = interpolateHeartRateData()
            for (_, heartRateItem) in heartBeatArray.enumerated() {
                
                var recording:Recording = Recording()
                recording.timeStamp = heartRateItem.timeStamp
                recording.bpm = heartRateItem.bpm
                recording.totalEnergy = 0
                recording.deltaEnergy = 0
                recording.hDisplacement = 0
                recording.vDisplacement = 0
                recording.vhSlope = 0
                
                let serialQueue = DispatchQueue(label: "myqueue")
                
                serialQueue.sync {
                    self.locationAndHeart.append(recording)
                    self.allHealthSamples.append(recording)
                }
                
            }
            
            zoneExtraction()
            activityExtraction(zones: self.zones)
            
            self.locationAndHeart = []
            self.locationSamples = []
            self.heartSamples = []
        }
    }
    
    // Given a set of HRDP start and end zones, get all the data including buffer zones
    func activityExtraction( zones: [(Int, Int)] ) {

        // All activities represents a list of HRDP and a bool representing if the buffer zones have been included.
        // Buffer start and end zones won't be included in the HRDP if and only if the HRDP occurs within the buffer zone (in this case 60 seconds) of the start or end of the workout
        var allActivities: [([Recording], Bool)] = []
        for activityZone in zones {
            let startOfActivity = activityZone.0
            let endOfActivity = activityZone.1
            
            // Found an Activity zone after 60 seconds within a workout and before 60 seconds of the end of the workout
            if (startOfActivity > self.bufferStart && endOfActivity + self.bufferEnd < self.locationAndHeart.count - 1) {
                let newStartZone = startOfActivity-self.bufferStart
                let newEndZone = endOfActivity + self.bufferEnd
                
                let serialQueue = DispatchQueue(label: "myqueue")
                
                serialQueue.sync {
                    let activity = (Array(self.locationAndHeart[newStartZone...newEndZone]), true)
                    allActivities.append(activity)
                }
                
            } else {
                // Can't include buffer zones
                let serialQueue = DispatchQueue(label: "myqueue")
                
                serialQueue.sync {
                    let activity = (Array(self.locationAndHeart[startOfActivity...endOfActivity]), false)
                    allActivities.append(activity)
                }
                
            }
        }
        self.tableSetUp(activities: allActivities)
    }

    // HRDP extraction algorithm
    func zoneExtraction() {

        // Calculation of max HR as per literature
        let maxHeartRate = 220.0 - Double(self.ageFromDB) // Default age to 60
        var i = 1
        var counter = 0 // represents the 20 consecutive non-decreasing second threshold
        var endCounter = 0 // represents the 20 consecutive non-increasing second threshold
        var curStartZone = -1
        var lookingForStartZone = true // bool indicating if the algo is looking for the start or the end of an HRDP

        while (i < self.locationAndHeart.count) {

            let currentItem = self.locationAndHeart[i]
            if (lookingForStartZone) {
                if (currentItem.bpm >= self.locationAndHeart[i-1].bpm) {
                    counter+=1
                } else {
                    counter = 0
                }
            } else {
                if (currentItem.bpm <= self.locationAndHeart[i-1].bpm) {
                    endCounter+=1
                } else {
                    endCounter = 0
                }
            }

            // First Looks for a period where HR is non-decreasing for 20 consecutive seconds
            if (counter >= 20) {

                if (lookingForStartZone) {

                    // MAX heart rate = 220 - Age
                    // SHR = Starting heart rate (i-20)
                    // EHR = Ending heart rate (i)
                    
                    // AGE |      MAX HR    | SHR  | SHR% of MAX  | EHR | EHR% of MAX    | Increase % of MAX |
                    // 20  |  220-20 = 200  |  60  | 60/200 = 30% | 75  | 75/200 = 37.5% |      of 7.5%      |
                    // 80  |  220-80 = 140  |  60  | 60/140 = 41% | 75  | 75/140 = 53%   |      of 11%       |

                    // If % difference between EHR - SHR > 40%
                    // AND If EHR% of MAX > 50% they are active

                    let introHB = self.locationAndHeart[i-counter+1].bpm
                    let outroHB = self.locationAndHeart[i].bpm

                    let introPercetangeRespectMaxHR = (introHB/maxHeartRate)*100
                    let outroPercetangeRespectMaxHR = (outroHB/maxHeartRate)*100
                    let outroIntroHBDiffPercent = (outroPercetangeRespectMaxHR - introPercetangeRespectMaxHR)

                    // If the final value is greater than 50% of max HR and the difference has increased by 10
                    // then mark the beginning of an HRDP
                    if (outroIntroHBDiffPercent > 10 && outroPercetangeRespectMaxHR > 50) {
                        curStartZone = i-counter
                        counter = 0
                        lookingForStartZone = !lookingForStartZone
                    }
                }
            }

            // Look for the ned of the zone
            if (endCounter >= 20) {
                if (!lookingForStartZone) {

                    let outroHB = self.locationAndHeart[i].bpm
                    let outroPercetangeRespectMaxHR = (outroHB/maxHeartRate)*100
                    // let SDArray = Array(self.locationAndHeart[i-endCounter+1...i])
                    // let SD = self.standardDeviation(arr: SDArray)
                    if (outroPercetangeRespectMaxHR <= 50) {
                        if (i+1 < self.locationAndHeart.count && self.locationAndHeart[i+1].bpm > currentItem.bpm) {
                            let activityZoneSize = i-endCounter - curStartZone
                            if ( activityZoneSize >= 0 ) {
                                // add the HRDP to the list
                                self.zones.append( (curStartZone, i) )
                                self.zonesAsTime.append((locationAndHeart[curStartZone].timeStamp, locationAndHeart[i].timeStamp))
                            }
                            endCounter = 0
                            lookingForStartZone = !lookingForStartZone
                        }
                    }
                }
            }

            i+=1
        }

    }
    
    // Calculate SD, not in use
    func standardDeviation(arr : [Recording]) -> Double {
        var arrFinal: [Double] = []
        
        for x in arr {
            arrFinal.append(x.bpm)
        }
        
        let length = Double(arrFinal.count)
        let avg = arrFinal.reduce(0, {$0 + $1}) / length
        let sumOfSquaredAvgDiff = arrFinal.map { pow($0 - avg, 2.0)}.reduce(0, {$0 + $1})
        return sqrt(sumOfSquaredAvgDiff / length)
        
    }
    
    // Table logic for UI
    func tableSetUp(activities:  [([Recording], Bool)]) {
        
        viewEntireWorkout()
        var HRDPCounter = 1
        var allHRDPDataSets = [IChartDataSet]()
        
        // For each HRDP, set UI logic
        for activityExtract in activities {
            let activity = activityExtract.0
            let startBufferZonesIncluded = activityExtract.1
            var curBiggestHeartRate: Double = 0 // Meta data about HRDP
            var curBiggestHeartRateIndex: Int = 0 // Meta data about HRDP
            var averageHeartRate: Double = 0 // Meta data about HRDP
            var curBiggestEnergyExpenditure: Double = 0 // Meta data about HRDP
            var averageEnergyExpenditure: Double = 0 // Meta data about HRDP
            var dataPoints: [Int] = []
            var values: [Double] = []
            var valueColors = [NSUIColor](repeating: NSUIColor.blue.withAlphaComponent(0), count: activity.count)
            
            if (startBufferZonesIncluded) {
                
                // Mark Resting
                valueColors[self.bufferStart] = NSUIColor.blue
                // Mark Recovery
                valueColors[activity.count-self.bufferEnd] = NSUIColor.green
            } else {
                // Mark Resting
                valueColors[0] = NSUIColor.blue
                // Mark Recovery
                valueColors[activity.count-2] = NSUIColor.green
            }
            
            for (index, item) in activity.enumerated() {
                dataPoints.append(index)
                values.append(item.bpm)
                
                // Dont include the buffer resting zones when calculating average and max HR for HRDP
                if (!startBufferZonesIncluded || (startBufferZonesIncluded && index > self.bufferStart && index < activity.count - self.bufferEnd)) {
                    let curBPM = item.bpm
                    let curTE = item.totalEnergy
                    if (curBPM > curBiggestHeartRate) {
                        curBiggestHeartRateIndex = index
                        curBiggestHeartRate = curBPM
                    }
                    if (curTE > curBiggestEnergyExpenditure) {
                        curBiggestEnergyExpenditure = curTE
                    }
                    averageEnergyExpenditure = averageEnergyExpenditure + item.totalEnergy
                    averageHeartRate = averageHeartRate + item.bpm
                }
                
            }
            
            // Mark Active
            valueColors[curBiggestHeartRateIndex] = NSUIColor.red
            
            averageHeartRate = averageHeartRate/Double(activity.count)
            averageEnergyExpenditure = averageEnergyExpenditure/Double(activity.count)
            
            var dataEntries: [ChartDataEntry] = []
            let old = Double(dataPoints.count)
            
            // linear multiplier of 100 to scale HRDPs. change willingly
            let new = 100.0
            let scalar = new/old
            for i in 0..<dataPoints.count - 1 {
                // let DataEntry = ChartDataEntry(x: Double(i), y: values[i])
                let DataEntry = ChartDataEntry(x: Double(i) * scalar, y: values[i])
                dataEntries.append(DataEntry)
            }
            
            // Set up the plot logic and colours
            let lineChart: LineChartDataSet = LineChartDataSet(entries: dataEntries, label: "HRDP: \(HRDPCounter)")
            lineChart.axisDependency = .left
            lineChart.setColor(UIColor.blue)
            lineChart.lineWidth = 1.0
            lineChart.drawValuesEnabled = false
            lineChart.circleRadius = 5.0
            lineChart.drawCircleHoleEnabled = false
            lineChart.circleColors = valueColors
            lineChart.valueColors = valueColors
            
            HRDPCounter+=1
            var dataSets = [IChartDataSet]()

            dataSets.append(lineChart)
            allHRDPDataSets.append(lineChart)
            
            let lineChartData = LineChartData(dataSets: dataSets)
            // Formats date logic
            let dateFormatterPrint = DateFormatter()
            dateFormatterPrint.dateFormat = "HH:mm:ss"
            
            let formattedStartDate = dateFormatterPrint.string(from: activity[0].timeStamp)
            let formattedEndDate = dateFormatterPrint.string(from: activity[activity.count-1].timeStamp)

            let roundedAHR = Double(round(100*averageHeartRate)/100)
            let roundedATE = Double(round(100*averageEnergyExpenditure)/100)
            let roundedBTE = Double(round(100*curBiggestEnergyExpenditure)/100)
        
            
            if (self.HRDPMaxHR < Int(curBiggestHeartRate)) {
                self.HRDPMaxHR = Int(curBiggestHeartRate)
            }

            if (self.HRDPMaxLength < dataPoints.count) {
                self.HRDPMaxLength = dataPoints.count
            }
            
            // Calls CustomCell to init data including message to user under graph
            self.data.append(CellData.init(chart: lineChartData, message: " Actual Activity length: \(activity.count) secs \n Start time: \(formattedStartDate) \n End Time: \(formattedEndDate) \n Average Heart Rate: \(roundedAHR), Max Heart Rate: \(curBiggestHeartRate) \n Max Energy Exp: \(roundedBTE), Average Energy Exp: \(roundedATE)"))
            
        }
        
        // Display overlaid HRDP graph if there is more than 1 HRDP
        if (activities.count > 1) {
            self.overlayHRDPs(HRDPset: allHRDPDataSets)
        } else {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    // Overlay many HRDPs onto one plot
    func overlayHRDPs(HRDPset: [IChartDataSet]) {
        let newHRDPSet = HRDPset
        for HRDP in newHRDPSet {
            let colour = UIColor.random()
            HRDP.setColor(colour)
        }

        let lineChartData = LineChartData(dataSets: HRDPset)

        let roundedHRDPMaxHR = Double(round(Double(100*self.HRDPMaxHR))/100)
        let roundedHRDPMaxLength = Double(round(100*Double(self.HRDPMaxLength)/60)/100)

        // Construct visual representation of all HRDP overlaid
        self.data.append(CellData.init(chart: lineChartData, message: " HRDP Data \n Max HR found in HRDP: \(roundedHRDPMaxHR) \n Max length of HRDP: \(roundedHRDPMaxLength) Mins"))

        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
    }
    
    // Plot logic for entire workout at the top of the page
    func viewEntireWorkout() {
    
        let activity = self.locationAndHeart
        var curBiggestHeartRate: Double = 0
        var averageHeartRate: Double = 0
        var dataPoints: [Int] = []
        var values: [Double] = []
        
        var valueColors = [NSUIColor](repeating: NSUIColor.blue.withAlphaComponent(0), count: self.locationAndHeart.count)
        
        var curColour = NSUIColor.red
        
        // Mark the HRDPs in red and black dots
        for item in self.zones {
            let start = item.0
            let end = item.1
            valueColors[start] = curColour
            valueColors[end] = curColour
            if (curColour == NSUIColor.black) {
                curColour = NSUIColor.red
            } else {
                curColour = NSUIColor.black
            }
        }
        
        // Calculate metadata for entire workout
        for (index, item) in self.locationAndHeart.enumerated() {
            dataPoints.append(index)
            let curBPM = item.bpm
            if (curBPM > curBiggestHeartRate) {
                curBiggestHeartRate = curBPM
            }
            averageHeartRate = averageHeartRate + item.bpm
            values.append(item.bpm)
        }
        
        
        averageHeartRate = averageHeartRate/Double(activity.count)
        
        var dataEntries: [ChartDataEntry] = []
        if (dataPoints.count > 1) {
            for i in 0..<dataPoints.count - 1 {
                let DataEntry = ChartDataEntry(x: Double(i), y: values[i])
                dataEntries.append(DataEntry)
            }
            // workout plot logic and colouring
            let set: LineChartDataSet = LineChartDataSet(entries: dataEntries, label: "Entire Workout")
            set.axisDependency = .left // Line will correlate with left axis values
            set.setColor(UIColor.green)
            set.lineWidth = 1.0
            set.drawValuesEnabled = false
            set.circleRadius = 5.0
            set.drawCircleHoleEnabled = false
            
            set.circleColors = valueColors
            set.valueColors = valueColors
            
            var dataSets = [IChartDataSet]()
            
            dataSets.append(set)
            let lineChartData = LineChartData(dataSets: dataSets)
            
            let dateFormatterPrint = DateFormatter()
            dateFormatterPrint.dateFormat = "dd MMM HH:mm:ss"
            
            let formattedStartDate = dateFormatterPrint.string(from: activity[0].timeStamp)
            let formattedEndDate = dateFormatterPrint.string(from: activity[activity.count-1].timeStamp)
            let roundedAHR = Double(round(100*averageHeartRate)/100)
            let roundedLengthInMins = Double(round(100*Double(activity.count)/60)/100)
            
            self.data.append(CellData.init(chart: lineChartData, message: " Workout Length: \(roundedLengthInMins + 1) Mins \n Start time: \(formattedStartDate) \n End Time: \(formattedEndDate) \n Average Heart Rate: \(roundedAHR), Max Heart Rate: \(curBiggestHeartRate) \n"))
        }
    }
    
}


extension CGFloat {
    static func random0To1ValProducer() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

extension UIColor {
    static func random() -> UIColor {
        return UIColor(red:   .random0To1ValProducer(),
                       green: .random0To1ValProducer(),
                       blue:  .random0To1ValProducer(),
                       alpha: 1.0)
    }
}

// Set up table view logic
extension WorkoutViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        if data.count == 0 {
            self.tableView.setEmptyMessage("This Workout does not have \n any location data.")
        } else {
            self.tableView.restore()
        }
        return 1
    }


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "custom") as! CustomCell
        cell.chart = data[indexPath.row].chart
        cell.message = data[indexPath.row].message
        cell.layoutSubviews()
        return cell
        
    }
    
}

extension WorkoutViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    // passes data to the PopUpViewController on click
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let receiverVC = segue.destination as? PopUpViewController else { return }
        receiverVC.delegate = self
        receiverVC.workoutStartDate = self.workout.startDate.description
    }
    
}

extension UITableView {
    
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = .black
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = .center;
        messageLabel.font = UIFont(name: "TrebuchetMS", size: 15)
        messageLabel.sizeToFit()
        
        self.backgroundView = messageLabel;
        self.separatorStyle = .none;
    }
    
    func restore() {
        self.backgroundView = nil
        self.separatorStyle = .singleLine
    }
    
}

extension WorkoutViewController: MFMailComposeViewControllerDelegate {
    
}


extension URL {
    var typeIdentifier: String? {
        return (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier
    }
    var localizedName: String? {
        return (try? resourceValues(forKeys: [.localizedNameKey]))?.localizedName
    }
}

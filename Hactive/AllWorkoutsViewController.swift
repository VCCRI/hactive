//
//  ViewController.swift
//  Hactive
//
//  Created by Adam Goldberg on 8/8/18.
//  Copyright © 2018 VCCRI. All rights reserved.
//

import UIKit
import HealthKit
import MapKit
import SpriteKit
import CoreData

class AllWorkoutsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    let healthKitManager = HealthKitManager.sharedInstance

    private var workouts: [HKWorkout]?
    private var singleWorkout: HKWorkout?
    private var restingHeartRate: Double = 0
    private var workoutNumber: Int = -1
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var datasource: [HKWorkout] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()        
        
        healthKitManager.authorizeHealthKit { (success, error) in
            print("Was HealthKit successful? \(success)")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getMetaData()
        getWorkouts()
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    // Calls functions in WorkoutAssistant
    // Gets age, weight and RHR data from HealthKit
    func getMetaData() {
        
        /* Uncomment if interested in weight and age
            WorkoutAssistant.getWeightFromHealthkit { (success, error) in }
            WorkoutAssistant.getAgeFromHealthkit { (success, error) in }
        */
        
        WorkoutAssistant.getRHRDataFromHealthkit { (success, error) in
            self.restingHeartRate = success
        }
    
    }

    // Calls workout function in WorkoutAssistant and appends workouts to table
    func getWorkouts() {
        
        WorkoutAssistant.loadWorkouts { (workouts, error) in
            self.workouts = workouts
            if self.workouts != nil {
                let item = self.workouts!
                for x in item {
                    self.datasource.append(x)
                }
                self.tableView.reloadData()
            } else {
                print("no workouts")
            }
        }
    }

}

extension AllWorkoutsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.count
    }
    
    // Sets up table view. Including duration, start-date and workout number
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "workout", for: indexPath)

        let indexNumber = indexPath.row + 1
        let duration = Int(Double(datasource[indexPath.row].duration / 60).rounded())
        let startDate = datasource[indexPath.row].startDate
        
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "dd MMM HH:mm:ss"
        
        let formattedDate = dateFormatterPrint.string(from: startDate)
        cell.textLabel?.text = "\(indexNumber): \(formattedDate) | \(duration) minutes"
        
        return cell
    }
    
}

extension AllWorkoutsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.singleWorkout = workouts?[indexPath.row]
        self.workoutNumber = Int(indexPath.row + 1)
        performSegue(withIdentifier: "tableToWorkOutSeque", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let workoutVC = segue.destination as? WorkoutViewController else {return}
        workoutVC.workout = self.singleWorkout
        workoutVC.workoutNumber = self.workoutNumber
    }
    
}

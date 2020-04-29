//
//  PopUpViewController.swift
//  Hactive
//
//  Created by Adam Goldberg on 10/10/18.
//  Copyright © 2018 VCCRI. All rights reserved.
//

import UIKit
import HealthKit
import CoreData

class PopUpViewController: UIViewController {
    
    @IBOutlet weak var popUpView: UIView!
    @IBOutlet weak var workoutTitleField: UITextField!
    @IBOutlet weak var weightField: UITextField!
    @IBOutlet weak var generalHealthInfoField: UITextField!
    @IBOutlet weak var ageField: UITextField!
    
    var delegate: isAbleToReceiveData!
    var workout: HKWorkout!
    var newWorkout: NSManagedObject!
    var context: NSManagedObjectContext!
    var workoutStartDate: String!
    var didChangeAgeOrWeight: Bool = false
    
    var ageOnEntry: String = ""
    var weightOnEntry: String = ""
    
    var workoutViewController = WorkoutViewController.self
    
    override func viewDidLoad() {
        super.viewDidLoad()
        popUpView.layer.cornerRadius = 15
        popUpView.layer.masksToBounds = true
        
        workoutTitleField.delegate = self
        weightField.delegate = self
        generalHealthInfoField.delegate = self
        ageField.delegate = self

        // set up core data logic
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.context = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Workout", in: self.context)
        self.newWorkout = NSManagedObject(entity: entity!, insertInto: self.context)
        self.fetchWorkoutCoreData()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(false)
        delegate.callOnReturn(didChange: self.didChangeAgeOrWeight)
    }
    
    @IBAction func cancelChanges(_ sender: Any) {
        self.dismissMod()
    }
    
    @IBAction func closePopUp(_ sender: Any) {
        
        let alert = UIAlertController(title: "Are you sure you would like to save?", message: "", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: UIAlertAction.Style.default, handler: { (action) in
            self.dismissMod()
        }))
        
        alert.addAction(UIAlertAction.init(title: "Save", style: UIAlertAction.Style.default, handler: { (action) in
            self.saveData()
        }))
        
        self.present(alert, animated: true) {
            // Completion block
        }
        
    }
    
    func dismissMod() {
        
        dismiss(animated: true, completion: nil)
        
    }
    
    func saveData() {
        
        if let workoutTitleField = workoutTitleField.text {
            self.newWorkout.setValue(workoutTitleField, forKey: "title")
        }
        
        if var weightField = weightField.text {
            // sets user input to 0 - 10
            if (weightField != "") {
                if (Int(weightField)! < 0) {
                    weightField = String(1)
                }
                self.newWorkout.setValue(Int(weightField), forKey: "weight")
                if weightField != self.weightOnEntry {
                    self.didChangeAgeOrWeight = true
                }
            }

        }
        
        if var ageField = ageField.text {

            if (ageField != "") {
                if (Int(ageField)! < 0) {
                    ageField = String(60)
                } else if (Int(ageField)! > 120) {
                    ageField = String(100)
                }
                self.newWorkout.setValue(Int(ageField), forKey: "age")
                if ageField != self.ageOnEntry {
                    self.didChangeAgeOrWeight = true
                }
            }
            
        }
        
        
        if let generalHealthInfoField = generalHealthInfoField.text {
            self.newWorkout.setValue(generalHealthInfoField, forKey: "healthInfo")
        }
        
        if let workoutDate = workoutStartDate {
            self.newWorkout.setValue(workoutDate.description, forKey: "startDate")
        }
        
        // saves to core data
        do {
            try self.context.save()
        } catch {
            print("Saving Failed")
        }
        self.dismissMod()
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        weightField.resignFirstResponder()
        
    }
    
    // Gets data saved in core data related to this workout
    func fetchWorkoutCoreData() {
        let workoutSD = self.workoutStartDate.description
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Workout")
        request.predicate = NSPredicate(format: "startDate = %@", workoutSD)
        request.returnsObjectsAsFaults = false
        
        do {
            let result = try context.fetch(request)
            if (result.count > 0) {
                
                let data = result.last as! NSManagedObject
                if let titleData = data.value(forKey: "title") as? String {
                    workoutTitleField.text = titleData
                }
                
                if let weightData = data.value(forKey: "weight") as? Int {
                    weightField.text = String(weightData)
                    self.weightOnEntry = String(weightData)
                }
                
                if let ageData = data.value(forKey: "age") as? Int {
                    ageField.text = String(ageData)
                    self.ageOnEntry = String(ageData)
                }
                
                if let healthData = data.value(forKey: "healthInfo") as? String {
                    generalHealthInfoField.text = healthData
                }
            }
            
        } catch {
            print("Failed")
        }
    }
    
}

extension PopUpViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // ensures input length is less than 20 characters
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        return newLength <= 1000
    }
    
}

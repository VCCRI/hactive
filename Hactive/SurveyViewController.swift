//
//  SurveyViewController.swift
//  Hactive
//
//  Created by Adam Goldberg on 30/8/18.
//  Copyright © 2018 VCCRI. All rights reserved.
//

import UIKit
import ResearchKit

// Class logic for ResearchKit consent
class SurveyViewController: UIViewController {
    
    @IBOutlet weak var viewWorkoutOutlet: UIButton!

    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var consentOutletButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.textColor = .white
        
        viewWorkoutOutlet.backgroundColor = .white
        viewWorkoutOutlet.layer.cornerRadius = 5
        viewWorkoutOutlet.layer.borderWidth = 1
        viewWorkoutOutlet.layer.borderColor = UIColor.black.cgColor
        
        consentOutletButton.backgroundColor = .white
        consentOutletButton.layer.cornerRadius = 5
        consentOutletButton.layer.borderWidth = 1 
        consentOutletButton.layer.borderColor = UIColor.black.cgColor
    }
    
    @IBAction func consentOutletAction(_ sender: Any) {
        let taskViewController = ORKTaskViewController(task: ConsentTask, taskRun: nil)
        taskViewController.delegate = self
        present(taskViewController, animated: true, completion: nil)
    }
    
    @IBAction func nextPageButton(_ sender: Any) {
        performSegue(withIdentifier: "nextPageSegue", sender: self)
    }
    
}

extension SurveyViewController : ORKTaskViewControllerDelegate {
    
    func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        //Handle results with taskViewController.result
        taskViewController.dismiss(animated: true, completion: nil)
    }
    
}

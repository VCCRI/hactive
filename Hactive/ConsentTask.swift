//
//  ConsentTask.swift
//  Hactive
//
//  Created by Adam Goldberg on 3/9/18.
//  Copyright © 2018 VCCRI. All rights reserved.
//

import Foundation
import ResearchKit

// Final review consent form ResearchKit task
public var ConsentTask: ORKOrderedTask {
    
    var steps = [ORKStep]()
    
    let consentDocument = ConsentDocument
    let visualConsentStep = ORKVisualConsentStep(identifier: "VisualConsentStep", document: consentDocument)
    steps += [visualConsentStep]

    
    let signature = consentDocument.signatures!.first
    
    let reviewConsentStep = ORKConsentReviewStep(identifier: "ConsentReviewStep", signature: signature, in: consentDocument)
    
    reviewConsentStep.text = "Review Consent!"
    reviewConsentStep.reasonForConsent = "Consent to join study"
    
    steps += [reviewConsentStep]

    
    return ORKOrderedTask(identifier: "ConsentTask", steps: steps)
}


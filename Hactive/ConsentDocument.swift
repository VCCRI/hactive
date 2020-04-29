//
//  ConsentDocument.swift
//  Hactive
//
//  Created by Adam Goldberg on 3/9/18.
//  Copyright © 2018 VCCRI. All rights reserved.
//

import Foundation
import ResearchKit

// ResearchKit Consent flow, change to fit real consent document
public var ConsentDocument: ORKConsentDocument {
    
    let consentDocument = ORKConsentDocument()
    consentDocument.title = "Example Consent"
    
    let consentSectionTypes: [ORKConsentSectionType] = [
        .overview,
        .dataGathering,
        .privacy,
        .dataUse,
        .timeCommitment,
        .studySurvey,
        .studyTasks,
        .withdrawing
    ]
    
    let consentSections: [ORKConsentSection] = consentSectionTypes.map { contentSectionType in
        let consentSection = ORKConsentSection(type: contentSectionType)
        consentSection.summary = "Consent to being part of this study..."
        consentSection.content = "Lorem ipsum dolor sit amet, consectetur adipiscing elit"
        return consentSection
    }
    
    consentDocument.sections = consentSections

    consentDocument.addSignature(ORKConsentSignature(forPersonWithTitle: nil, dateFormatString: nil, identifier: "ConsentDocumentParticipantSignature"))
    
    return consentDocument
}


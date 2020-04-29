//
//  CustomCell.swift
//  Hactive
//
//  Created by Adam Goldberg on 18/9/18.
//  Copyright © 2018 VCCRI. All rights reserved.
//

import Foundation
import UIKit
import Charts

class CustomCell: UITableViewCell {
    var chart : LineChartData?
    var message: String?
    
    var messageView : UITextView = {
        var textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = false
        return textView
    }()
    
    var chartView : LineChartView = {
       var chartView = LineChartView()
        // chartView.chartAnimator.animate(xAxisDuration: 0.5)
        chartView.rightAxis.drawGridLinesEnabled = false
        chartView.leftAxis.drawGridLinesEnabled = false
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.contentMode = .scaleAspectFit
        chartView.drawGridBackgroundEnabled = false
        
        return chartView
    }()
    
    // UI logic for displaying graph
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(chartView)
        self.addSubview(messageView)
        
        chartView.heightAnchor.constraint(equalToConstant: 250).isActive = true
        chartView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        chartView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        chartView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        chartView.bottomAnchor.constraint(equalTo: self.messageView.topAnchor).isActive = true

        messageView.topAnchor.constraint(equalTo: self.chartView.bottomAnchor).isActive = true
        messageView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        messageView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        messageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
    }
    
    override func layoutSubviews() {
         super.layoutSubviews()

        if let chart = chart {
            chartView.data = chart
        }
        
        if let message = message {
            messageView.text = message
        }
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


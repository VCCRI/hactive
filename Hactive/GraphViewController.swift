//
//  GraphViewController.swift
//  healthDisplay
//
//  Created by Adam Goldberg on 12/9/18.
//  Copyright © 2018 Adam Goldberg. All rights reserved.
//

import UIKit
import Charts

class GraphViewController: UIViewController, ChartViewDelegate {
    
    @IBOutlet weak var lineChartView: LineChartView!
    var days: [String]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        days = ["M", "T", "W", "W", "T", "F", "S", "S",]
        let values = [110,121,110.1,104.5,105.7, 125.0,102.5]
        setChart(dataPoints: days, Values: values)
    }
    
    func setChart(dataPoints: [String]?, Values: [Double]) {
        lineChartView.delegate = self
        var dataEntries: [ChartDataEntry] = []
        
        for i in 0..<dataPoints!.count - 1 {
            let DataEntry = ChartDataEntry(x: Values[i], y: Double(i))
            dataEntries.append(DataEntry)
        }
        
        let lineChartDataSet = LineChartDataSet(values: dataEntries, label: "Altitude")
        lineChartDataSet.setColor(UIColor.blue)
        lineChartDataSet.mode = .cubicBezier
        lineChartDataSet.drawCirclesEnabled = false
        lineChartDataSet.lineWidth = 1.0
        lineChartDataSet.circleRadius = 5.0
        lineChartDataSet.highlightColor = UIColor.red
        lineChartDataSet.drawHorizontalHighlightIndicatorEnabled = true
        
        var dataSets = [IChartDataSet]()
        dataSets.append(lineChartDataSet)
        
        let lineChartData = LineChartData(dataSets: dataSets)
        
        lineChartView.data = lineChartData
        
    }
}




//
//  MapSearchTableVC.swift
//  Trippng
//
//  Created by Noah Safian on 5/10/16.
//  Copyright © 2016 Noah Safian. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class MapSearchTableVC: UITableViewController, UISearchResultsUpdating {
    
    var data: [Place] = []
    
    var center: CLLocation?
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        
        let searchBarText = searchController.searchBar.text!
        
        if searchBarText == "" {
            return
        }
        
        let priority = DISPATCH_QUEUE_PRIORITY_BACKGROUND
        
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            if let center: CLLocation = self.center! {
                let results = GooglePlacesSearcher.getAutocompletePlaces(center.coordinate.latitude, longitude: center.coordinate.longitude, text: searchBarText, type: nil)
                
                dispatch_async(dispatch_get_main_queue())
                {
                    self.data = results
                    self.tableView.reloadData()
                }
            }
            
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell")!
        let place = data[indexPath.row]
        cell.textLabel?.text = place.name
        cell.detailTextLabel?.text = place.address
        return cell
    }
}
//
//  RouteSearchVC.swift
//  Trippng
//
//  Created by Noah Safian on 5/24/16.
//  Copyright © 2016 Noah Safian. All rights reserved.
//

import UIKit
import MapKit
import GoogleMaps

class RouteSearchVC: UIViewController, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    
    var searchController = UISearchController()
    
    var route: MKRoute!
    
    var results = [Place]()
    
    var radiusMeters = 10000
    
    var distanceBetweenSearches: Double = 20000
    
    var delegate: RouteSearchDelegate?
    
    var maxResultsFromOneSearch = 5
    
    static let cellID = "placeCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController = UISearchController(searchResultsController: nil)
        
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        
        tableView.tableHeaderView = searchController.searchBar
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationItem.title = "Search along your route"
        
        searchController.searchBar.delegate = self
        searchController.searchBar.becomeFirstResponder()
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier(RouteSearchVC.cellID)
        
        if cell == nil {
            cell = UITableViewCell(style: .Subtitle, reuseIdentifier: RouteSearchVC.cellID)
        }
        
        let place = results[indexPath.row]
        
        cell.textLabel!.text = place.name
        cell.detailTextLabel!.text = place.address
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let delegate = delegate {
            if let navController = navigationController{
                delegate.routeSearchDidReturnWithResult(self.results[indexPath.row])

                navController.popViewControllerAnimated(true)
            }
//            self.dismissViewControllerAnimated(true) {
//                delegate.routeSearchDidReturnWithResult(self.results[indexPath.row])
//            }
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        searchController.searchBar.becomeFirstResponder()
    }
    
    var indicator = UIActivityIndicatorView()
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        let length: CGFloat = 60
        indicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, length, length))
        indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        indicator.center = self.view.center
        self.view.addSubview(indicator)
        indicator.startAnimating()
        
        tableView.userInteractionEnabled = false
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) {
            self.performSearchAlongRoute()
            self.indicator.stopAnimating()
            self.tableView.userInteractionEnabled = true
        }
        
        
    }
    
    func performSearchAlongRoute() {
        if let searchText = searchController.searchBar.text {
            
            if searchText == "" {
                return
            }
            
            let pointCount = route.polyline.pointCount
            
            let coordinateArray = UnsafeMutablePointer<CLLocationCoordinate2D>.alloc(pointCount)
            
            route.polyline.getCoordinates(coordinateArray, range: NSMakeRange(0, pointCount-1))
            
            results = [Place]()
            
            print("\(pointCount)")
            
            var lastSearchLoc = coordinateArray[0]
            for var i = 0; i < pointCount; i += pointCount/100 {
                if lastSearchLoc.distanceTo(coordinateArray[i]) > distanceBetweenSearches {
                    lastSearchLoc = coordinateArray[i]
                    let searchResults = GooglePlacesSearcher.getNearbyPlaces(lastSearchLoc.latitude, longitude: lastSearchLoc.longitude, keyword: searchText, type: nil)
                    results.appendContentsOf(searchResults)
                }
            }
        }
        
        tableView.reloadData()
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
//        performSearchAlongRoute()
    }
}

extension CLLocationCoordinate2D {
    func distanceTo(coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let thisLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let otherLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        return thisLocation.distanceFromLocation(otherLocation)
    }
}

protocol RouteSearchDelegate {
    func routeSearchDidReturnWithResult(place: Place)
}

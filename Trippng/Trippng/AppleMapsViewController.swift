//
//  AppleMapsViewController.swift
//  Trippng
//
//  Created by Noah Safian on 5/5/16.
//  Copyright © 2016 Noah Safian. All rights reserved.
//

import UIKit
import MapKit
import GoogleMaps

class AppleMapsViewController: UIViewController, MKMapViewDelegate, UISearchBarDelegate, CLLocationManagerDelegate, GMSAutocompleteResultsViewControllerDelegate {
    
    var searchController: UISearchController?
    
    var locationSearchTable: MapSearchTableVC?
    
    let locationManager = CLLocationManager()
    
    var resultsViewController = GMSAutocompleteResultsViewController()
    
    
    var searchRadiusBiasDegrees: Double = 2
    var searchRadiusBiasMiles: Double = 100
    
    @IBOutlet weak var mapView: MKMapView!
    
    func showSearchBar() {
        if let searchController = searchController {
            searchController.hidesNavigationBarDuringPresentation = false
            searchController.searchBar.delegate = self
            //presentViewController(searchController, animated: true, completion: nil)
            self.showViewController(searchController, sender: nil)
        }
    }
    
    //    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
    //         searchBar.resignFirstResponder()
    //    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        
        locationSearchTable = storyboard!.instantiateViewControllerWithIdentifier("MapSearchTableVC") as? MapSearchTableVC
        locationSearchTable!.center = locationManager.location
        
        //        searchController = UISearchController(searchResultsController: locationSearchTable)
        //        searchController?.searchResultsUpdater = locationSearchTable
        //
        // Google autocmplete sdk
        resultsViewController.delegate = self
        
        if let currentLocation = locationManager.location?.coordinate {
            
            let neCorner = CLLocationCoordinate2D(latitude: currentLocation.latitude + searchRadiusBiasDegrees/2.0, longitude: currentLocation.longitude + searchRadiusBiasDegrees/2.0)
            
            let swCorner = CLLocationCoordinate2D(latitude: currentLocation.latitude - searchRadiusBiasDegrees/2.0, longitude: currentLocation.longitude - searchRadiusBiasDegrees/2.0)
            resultsViewController.autocompleteBounds = GMSCoordinateBounds(coordinate: neCorner, coordinate: swCorner)
        }
        
        
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController?.searchResultsUpdater = resultsViewController
        
        if let searchBar = searchController?.searchBar {
            searchBar.sizeToFit()
            searchBar.placeholder = "Enter your destination here"
            navigationItem.titleView = searchController?.searchBar
        }
        
        
        searchController?.hidesNavigationBarDuringPresentation = false
        searchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        
        
    }
    
    func resultsController(resultsController: GMSAutocompleteResultsViewController, didAutocompleteWithPlace place: GMSPlace) {
        searchController?.active = false
        
        zoomInOn(place.coordinate, animated: true)
        
        mapView.removeAnnotations(mapView.annotations)
        
        mapView.addAnnotation(place)
        
        // Do something with the selected place.
        print("Place name: ", place.name)
        print("Place address: ", place.formattedAddress)
        print("Place attributions: ", place.attributions)
    }
    
    static let annotationIdentifier = "annot"
    
    func mapView(sender: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation.isEqual(mapView.userLocation) {
            return nil
        }
        
        var view: MKAnnotationView! = sender.dequeueReusableAnnotationViewWithIdentifier(AppleMapsViewController.annotationIdentifier)
        if (view == nil) {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: AppleMapsViewController.annotationIdentifier)
            
            view.canShowCallout = true
            
            let length: CGFloat = 40
            
            let goButton = UIButton(type: UIButtonType.Custom)
            goButton.setTitle("Go!", forState: UIControlState.Normal)
            
            goButton.frame = CGRectMake(0, 0, length, length)
            
            goButton.backgroundColor = UIColor.blackColor()
            view.rightCalloutAccessoryView = goButton
            
            view.autoresizesSubviews = true
            
            if let pinView = view as? MKPinAnnotationView {
                pinView.animatesDrop = true
                pinView.pinTintColor = MKPinAnnotationView.purplePinColor()
            }
            
            // set canShowCallout to true or false and build aView’s callout accessory views here
        }
        view.annotation = annotation
        // maybe load up accessory views and/or title/subtitle here
        // or reset them and wait until mapView(didSelectAnnotationView:) to load actual data
        return view
    }
    
    var route: MKPolyline?
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        mapView.removeOverlays(mapView.overlays)
        
        if let currentCoordinate = locationManager.location?.coordinate {
            if let destinationCoordinate = view.annotation?.coordinate {
                
                let request = MKDirectionsRequest()
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: currentCoordinate, addressDictionary: nil))
                request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate, addressDictionary: nil))
                request.requestsAlternateRoutes = false
                request.transportType = .Automobile
                
                let directions = MKDirections(request: request)
                
                directions.calculateDirectionsWithCompletionHandler { [unowned self] response, error in
                    guard let unwrappedResponse = response else { return }
                    
                    self.route = unwrappedResponse.routes[0].polyline
                    self.mapView.addOverlay(self.route!)
                    
                    let boundingRect = self.route!.boundingMapRect
                    
                    let scale = 2.0
                    
                    let newRect = MKMapRect(origin: MKMapPoint(x: boundingRect.origin.x - (scale - 1.0)/2.0 * boundingRect.size.width, y: boundingRect.origin.y - (scale - 1.0)/2.0 * boundingRect.size.height), size: MKMapSize(width: boundingRect.size.width * scale, height: boundingRect.size.height * scale))
                    self.mapView.setVisibleMapRect(newRect, animated: true)
//                    self.mapView.deselectAnnotation(view.annotation, animated: true)
                }
            }
        }
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor.blueColor()
            return renderer
        }
        return MKPolygonRenderer()
    }
    
//    func mapView(mapView: MKMapView, didAddOverlayRenderers renderers: [MKOverlayRenderer]) {
//        let renderer = renderers[0]
//        let l = renderer.overlay.coordinate
//        let scale = 1.1
//        let span = MKCoordinateSpan(latitudeDelta: currentSpan.latitudeDelta * scale, longitudeDelta: currentSpan.longitudeDelta * scale)
//        let region = MKCoordinateRegion(center: mapView.region.center, span: span)
//        mapView.setRegion(region, animated: true)
//    }
    
    func resultsController(resultsController: GMSAutocompleteResultsViewController,
                           didFailAutocompleteWithError error: NSError){
        // TODO: handle the error.
        print("Error: ", error.description)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictionsForResultsController(resultsController: GMSAutocompleteResultsViewController) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictionsForResultsController(resultsController: GMSAutocompleteResultsViewController) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            locationManager.requestLocation()
        }
        //        else {
        //            locationManager.requestWhenInUseAuthorization()
        //        }
    }
    
    func zoomInOn(loc: CLLocationCoordinate2D, animated: Bool) {
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: loc, span: span)
        mapView.setRegion(region, animated: animated)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        
        if let userLoc = locationManager.location {
            zoomInOn(userLoc.coordinate, animated: false)
        }
        //        zoomInOn(mapView.userLocation.coordinate)
        
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //        if let location = locations.first {
        //            let span = MKCoordinateSpanMake(0.05, 0.05)
        //            let region = MKCoordinateRegion(center: location.coordinate, span: span)
        //            mapView.setRegion(region, animated: true)
        //
        //            if let locationSearchTable = locationSearchTable {
        //                locationSearchTable.center = location
        //            }
        //        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("error:: \(error)")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}

extension GMSPlace: MKAnnotation {
    public var title: String? {
        get {
            return self.name
        }
    }
    
    public var subtitle: String? {
        get {
            return self.formattedAddress
        }
    }
}

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

class AppleMapsViewController: UIViewController, MKMapViewDelegate, UISearchBarDelegate, CLLocationManagerDelegate, GMSAutocompleteResultsViewControllerDelegate, RouteSearchDelegate {
    
    var searchController: UISearchController?
    
    @IBOutlet weak var cancelSearchButton: UIButton!
    
    var locationSearchTable: MapSearchTableVC?
    
    let locationManager = CLLocationManager()
    
    var resultsViewController = GMSAutocompleteResultsViewController()
    
    var routeSearchBarColor = UIColor.orangeColor()
    
    var searchRadiusBiasDegrees: Double = 2
    var searchRadiusBiasMiles: Double = 100
    
    var isInitial = true
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBAction func cancelSearchButtonTapped(sender: UIButton) {
        setupSearchBar()
        cancelSearchButton.hidden = true
        mapView.removeOverlays(mapView.overlays)
        destination = nil
    }
    
    func setupSearchBar() {
        if let searchBar = searchController?.searchBar {
            searchBar.sizeToFit()
            searchBar.placeholder = "Enter your destination here"
            navigationItem.titleView = searchController?.searchBar
        }
    }
    
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
        
        setupSearchBar()
        
        searchController?.hidesNavigationBarDuringPresentation = false
        searchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        cancelSearchButton.hidden = true
//        cancelSearchButton.alpha = 0.5
        cancelSearchButton.backgroundColor = UIColor.grayColor().colorWithAlphaComponent(0.5)
        
    }
    
    func resultsController(resultsController: GMSAutocompleteResultsViewController, didAutocompleteWithPlace place: GMSPlace) {
        searchController?.active = false
        
        zoomInOn(place.coordinate, animated: true)
        
        mapView.removeOverlays(mapView.overlays)
        
        mapView.removeAnnotations(mapView.annotations)
        
        mapView.addAnnotation(place)
        
        mapView.selectAnnotation(place, animated: true)
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
        //        self.mapView.selectAnnotation(annotation, animated: true)
        
        //        if (self.mapView.annotationsInMapRect(mapView.visibleMapRect).contains(annotation)) {
        //            self.mapView.selectAnnotation(annotation, animated: true)
        //        }
        // maybe load up accessory views and/or title/subtitle here
        // or reset them and wait until mapView(didSelectAnnotationView:) to load actual data
        return view
    }
    
    var route: MKRoute?
    
    var destination: CLLocationCoordinate2D?
    
    func newRectScaledBy(scale: Double, orig: MKMapRect) -> MKMapRect {
        let newRect = MKMapRect(origin: MKMapPoint(x: orig.origin.x - (scale - 1.0)/2.0 * orig.size.width, y: orig.origin.y - (scale - 1.0)/2.0 * orig.size.height), size: MKMapSize(width: orig.size.width * scale, height: orig.size.height * scale))
        return newRect
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        mapView.removeOverlays(mapView.overlays)
        
        if let currentCoordinate = locationManager.location?.coordinate {
            if let destinationCoordinate = view.annotation?.coordinate {
                destination = destinationCoordinate
                
                let request = MKDirectionsRequest()
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: currentCoordinate, addressDictionary: nil))
                request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate, addressDictionary: nil))
                request.requestsAlternateRoutes = false
                request.transportType = .Automobile
                
                let directions = MKDirections(request: request)
                
                directions.calculateDirectionsWithCompletionHandler { [unowned self] response, error in
                    guard let unwrappedResponse = response else { return }
                    
                    self.route = unwrappedResponse.routes[0]
                    self.mapView.addOverlay(self.route!.polyline)
                    
                    let boundingRect = self.route!.polyline.boundingMapRect
                    
                    let scale = 2.0
                    
                    //                    let newRect = MKMapRect(origin: MKMapPoint(x: boundingRect.origin.x - (scale - 1.0)/2.0 * boundingRect.size.width, y: boundingRect.origin.y - (scale - 1.0)/2.0 * boundingRect.size.height), size: MKMapSize(width: boundingRect.size.width * scale, height: boundingRect.size.height * scale))
                    
                    let newRect = self.newRectScaledBy(scale, orig: boundingRect)
                    
                    self.mapView.setVisibleMapRect(newRect, animated: true)
                    self.mapView.deselectAnnotation(view.annotation, animated: true)
                    
                    let button = UIButton(type: .Custom)
                    button.setTitle("Click here to search along route", forState: .Normal)
                    button.setTitleColor(UIColor.blackColor(), forState: .Normal)
                    button.addTarget(self, action: "searchAlongRoute:", forControlEvents: .TouchUpInside)
                    
                    
                    self.navigationItem.titleView = button
                    
                    self.cancelSearchButton.hidden = false
                    
                    //                    if let searchBar = self.searchController?.searchBar {
                    //                        searchBar.placeholder = "Search along your route!"
                    //                        searchBar.backgroundColor = self.routeSearchBarColor
                    //                        searchBar.autoresizingMask = UIViewAutoresizing.FlexibleWidth
                    //                        searchBar.superview?.backgroundColor = self.routeSearchBarColor
                    //                    }
                }
            }
        }
    }
    
    static let routeVCIdentifier = "RouteVC"
    
    func searchAlongRoute(sender: UIButton) {
        if let searchAlongRouteVC = storyboard?.instantiateViewControllerWithIdentifier(AppleMapsViewController.routeVCIdentifier) as? RouteSearchVC {
            
            searchAlongRouteVC.route = self.route
            
            searchAlongRouteVC.delegate = self
            
            self.navigationController?.pushViewController(searchAlongRouteVC, animated: true)
            
            //            self.presentViewController(searchAlongRouteVC, animated: true, completion: nil)
        }
        
    }
    
    func routeSearchDidReturnWithResult(place: Place) {
        if let currentCoordinate = locationManager.location?.coordinate {
            let request1 = MKDirectionsRequest()
            request1.source = MKMapItem(placemark: MKPlacemark(coordinate: currentCoordinate, addressDictionary: nil))
            request1.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude) , addressDictionary: nil))
            request1.requestsAlternateRoutes = false
            request1.transportType = .Automobile
            
            
            
            let directions1 = MKDirections(request: request1)
            
            directions1.calculateDirectionsWithCompletionHandler { [unowned self] response, error in
                guard let unwrappedResponse = response else { return }
                
                self.route = unwrappedResponse.routes[0]
                
                let request2 = MKDirectionsRequest()
                
                request1.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude), addressDictionary: nil))
                
                request1.destination = MKMapItem(placemark: MKPlacemark(coordinate: self.destination!, addressDictionary: nil))
                
                let directions2 = MKDirections(request: request1)
                
                directions2.calculateDirectionsWithCompletionHandler { [unowned self] response, error in
                    guard let unwrappedResponse = response else { return }
                    
                    let route2 = unwrappedResponse.routes[0]
                    
                    //                let pointCount = self.route!.polyline.pointCount + route2.polyline.pointCount
                    //
                    //                let coordinateArray = UnsafeMutablePointer<CLLocationCoordinate2D>.alloc(pointCount)
                    //
                    //                route.polyline.getCoordinates(coordinateArray, range: NSMakeRange(0, pointCount-1))
                    
                    self.mapView.addOverlay(self.route!.polyline)
                    self.mapView.addOverlay(route2.polyline)
                    
                    let boundingRect1 = self.route!.polyline.boundingMapRect
                    let boundingRect2 = route2.polyline.boundingMapRect
                    let xMin = min(boundingRect1.origin.x, boundingRect2.origin.x)
                    let yMin = min(boundingRect1.origin.y, boundingRect2.origin.y)
                    let xMax = max(boundingRect1.origin.x + boundingRect1.size.width, boundingRect2.origin.x + boundingRect2.size.width)
                    let yMax = max(boundingRect1.origin.y + boundingRect1.size.height, boundingRect2.origin.y + boundingRect2.size.height)
                    
                    print("\(xMin),\(yMin) \(xMax),\(yMax)")
                    
                    let scale = 1.2
                    let newRect1 = MKMapRect(origin: MKMapPoint(x: xMin, y: yMin), size: MKMapSize(width: xMax - xMin, height: yMax - yMin))
                    //                let newRect2 = MKMapRect(origin: MKMapPoint(x: xMin - (scale - 1.0)/2.0 * (xMax - xMin), y: yMin - (scale - 1.0)/2.0 * (yMax - yMin)), size: MKMapSize(width: (xMax - xMin) * scale, height: (yMax-yMin) * scale))
                    
                    let newRect2 = self.newRectScaledBy(scale, orig: newRect1)
                    self.mapView.setVisibleMapRect(newRect2, animated: true)
                    
                    let annotation = MKPointAnnotation()
                    annotation.title = place.name
                    annotation.subtitle = place.address
                    annotation.coordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
                    
                    self.mapView.addAnnotation(annotation)
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
        if isInitial{
            if let userLoc = locationManager.location {
                zoomInOn(userLoc.coordinate, animated: false)
            }
            isInitial = false
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

//
//  GooglePlacesSearcher.swift
//  Trippng
//
//  Created by Noah Safian on 5/5/16.
//  Copyright © 2016 Noah Safian. All rights reserved.
//

import Foundation

class GooglePlacesSearcher
{
    static let nearbyBaseURL = "https://maps.googleapis.com/maps/api/place/nearbysearch/"
    
    static let autoCompleteBaseURL = "https://maps.googleapis.com/maps/api/place/autocomplete/"
    
    static let ApiKey = "AIzaSyDarYYTZysTTHua1-YF_c9ePDVRfpBl8Bk"
    
    static let example = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=-33.8670522,151.1957362&radius=500&type=restaurant&name=cruise&key=YOUR_API_KEY"
    
    static let language = "json"
    
    enum PlaceType: String {
        case Accounting = "accounting",
        Airport = "airport",
        AmusementPark = "amusement_park",
        Restaraunt = "restaurant"
    }
    
    static func getPlacesFromURL(urlString: String) -> [Place] {
        let url = NSURL(string: urlString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLFragmentAllowedCharacterSet())!)
        
        var parsedObject: AnyObject?
        do {
            parsedObject = try NSJSONSerialization.JSONObjectWithData(NSData(contentsOfURL: url!)!, options: NSJSONReadingOptions.MutableContainers)
        } catch let error1 as NSError {
            print(error1)
        }
        
        var places = [Place]()
        
        if let jsonResult = parsedObject as? NSDictionary {
            let placesArray: NSArray = jsonResult["results"]! as! NSArray
            for index in 0..<placesArray.count {
                let placesJSON: NSDictionary = placesArray[index]as! NSDictionary
                
                let latitude = placesJSON["geometry"]!["location"]!!["lat"] as! Double
                let longitude = placesJSON["geometry"]!["location"]!!["lng"] as! Double
                
                let name = placesJSON["name"] as! String
                let address = placesJSON["vicinity"] as! String
                
                places.append(Place(lat: latitude, long: longitude, nm: name, ad: address))
            }
        }
        
        return places
    }
    
    static func getAutocompletePlaces(latitude: Double, longitude: Double, text: String, type: GooglePlacesSearcher.PlaceType?, radius: Double = 10000, minPrice: Int = 0, maxPrice: Int = 4, onlyOpenNow:Bool = false) -> [Place] {
        
        let urlString = generateAutocompleteURL(latitude, longitude: longitude, text: text, type: type, radius: radius, minPrice: minPrice, maxPrice: maxPrice, onlyOpenNow: onlyOpenNow)
        
        return GooglePlacesSearcher.getPlacesFromAutocompleteURL(urlString)
    }
    
    static func getPlacesFromAutocompleteURL(urlString: String) -> [Trippng.Place] {
        
        print("\(urlString)")
        let url = NSURL(string: urlString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLFragmentAllowedCharacterSet())!)
        
        var parsedObject: AnyObject?
        do {
            parsedObject = try NSJSONSerialization.JSONObjectWithData(NSData(contentsOfURL: url!)!, options: NSJSONReadingOptions.MutableContainers)
        } catch let error1 as NSError {
            print(error1)
        }
        
        var places = [Place]()
        
        if let jsonResult = parsedObject as? NSDictionary {
            let placesArray: NSArray = jsonResult["predictions"]! as! NSArray
            for index in 0..<placesArray.count {
                let placesJSON: NSDictionary = placesArray[index]as! NSDictionary
                
                let latitude = placesJSON["geometry"]!["location"]!!["lat"] as! Double
                let longitude = placesJSON["geometry"]!["location"]!!["lng"] as! Double
                
                let name = placesJSON["name"] as! String
                let address = placesJSON["vicinity"] as! String
                
                places.append(Place(lat: latitude, long: longitude, nm: name, ad: address))
            }
        }
        
        return places
    }
    
    static func generateAutocompleteURL(latitude: Double, longitude: Double, text: String, type: GooglePlacesSearcher.PlaceType?, radius: Double = 100000, minPrice: Int = 0, maxPrice: Int = 4, onlyOpenNow:Bool = false) -> String {
        
        var url = "\(GooglePlacesSearcher.autoCompleteBaseURL)\(language)?key=\(GooglePlacesSearcher.ApiKey)&input=\(text)&location=\(latitude),\(longitude)&radius=\(radius)"
        
        if let type = type {
            url += "&type=" + "\(type)"
        }
        
        if minPrice <= maxPrice {
            if minPrice >= 0 && minPrice <= 4 {
                url += "&minprice=" + String(minPrice)
            }
            if maxPrice >= 0 && maxPrice <= 4 {
                url += "&maxprice=" + String(maxPrice)
            }
        }
        
        if onlyOpenNow {
            url += "&opennow=true"
        }
        
        return url
    }

    
    static func getNearbyPlaces(latitude: Double, longitude: Double, keyword: String?, type: GooglePlacesSearcher.PlaceType?, radius: Double = 10000, minPrice: Int = 0, maxPrice: Int = 4, onlyOpenNow:Bool = false) -> [Place] {
        
        let urlString = generateNearbyURL(latitude, longitude: longitude, keyword: keyword, type: type, radius: radius, minPrice: minPrice, maxPrice: maxPrice, onlyOpenNow: onlyOpenNow)
        
        return GooglePlacesSearcher.getPlacesFromURL(urlString)
    }
    
    static func generateNearbyURL(latitude: Double, longitude: Double, keyword: String?, type: GooglePlacesSearcher.PlaceType?, radius: Double = 10000, minPrice: Int = 0, maxPrice: Int = 4, onlyOpenNow:Bool = false) -> String {
        
        return GooglePlacesSearcher.generateURL(GooglePlacesSearcher.nearbyBaseURL, latitude: latitude, longitude: longitude, keyword: keyword, type: type, radius: radius, minPrice: minPrice, maxPrice: maxPrice, onlyOpenNow: onlyOpenNow)
    }
    
    static func generateURL(baseURL: String, latitude: Double, longitude: Double, keyword: String?, type: GooglePlacesSearcher.PlaceType?, radius: Double = 10000, minPrice: Int = 0, maxPrice: Int = 4, onlyOpenNow:Bool = false) -> String {
        var url = "\(baseURL)\(language)?key=\(GooglePlacesSearcher.ApiKey)&location=\(latitude),\(longitude)&radius=\(radius)"
        
        if let keyword = keyword {
            url += "&keyword=" + keyword
        }
        
        if let type = type {
            url += "&type=" + "\(type)"
        }
        
        if minPrice <= maxPrice {
            if minPrice >= 0 && minPrice <= 4 {
                url += "&minprice=" + String(minPrice)
            }
            if maxPrice >= 0 && maxPrice <= 4 {
                url += "&maxprice=" + String(maxPrice)
            }
        }
        
        if onlyOpenNow {
            url += "&opennow=true"
        }
        
        return url
    }

    
}
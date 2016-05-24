//
//  Place.swift
//  Trippng
//
//  Created by Noah Safian on 5/10/16.
//  Copyright © 2016 Noah Safian. All rights reserved.
//

import Foundation

class Place
{
    private init()
    {
        latitude = -1
        longitude = -1
        name = ""
        address = ""
    }
    
    init(lat: Double, long: Double, nm: String, ad: String)
    {
        latitude = lat
        longitude = long
        name = nm
        address = ad
    }
    
    var name: String?
    var latitude: Double?
    var longitude: Double?
    var address: String?
    var googleId: String?
}
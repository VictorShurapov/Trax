//
//  MKGPX.swift
//  Trax
//
//  Created by Victor Shurapov on 6/8/18.
//  Copyright © 2018 Victor Shurapov. All rights reserved.
//

import MapKit

class EditableWaypoint: GPX.Waypoint {
    
    // make coordinate gettable & settable (for draggable annotations)
    override var coordinate: CLLocationCoordinate2D {
        get { return super.coordinate }
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }
}

extension GPX.Waypoint: MKAnnotation {
    
    // MARK: - MKAnnotation

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var title: String? { return name! }
    
    var subtitle: String? { return info }
    
    // MARK: - Links to Images

    var thumbnailURL: URL? { return getImageURLofType(type: "thumbnail") }
    
    var imageURL: URL? { return getImageURLofType(type: "large") }

    private func getImageURLofType(type: String) -> URL? {
        for link in links {
            if link.type == type {
                return link.url!
            }
        }
        return nil
    }
    
}

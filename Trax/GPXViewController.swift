//
//  ViewController.swift
//  Trax
//
//  Created by Victor Shurapov on 3/2/18.
//  Copyright © 2018 Victor Shurapov. All rights reserved.
//

import UIKit
import MapKit

class GPXViewController: UIViewController, MKMapViewDelegate, UIPopoverPresentationControllerDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.mapType = .satellite
            mapView.delegate = self
        }
    }
    
    // MARK: - Public API
    
    var gpxURL: URL? {
        didSet {
            clearWaypoints()
            if let url = gpxURL {
                GPX.parse(url: url) {
                    if let gpx = $0 {
                        self.handleWaypoints(gpx.waypoints)
                    }
                }
            }}
    }
    
    // MARK: - Waypoints
    
    private func clearWaypoints() {
        if mapView?.annotations != nil { mapView.removeAnnotations(mapView.annotations)}
    }
    
    private func handleWaypoints(_ waypoints: [GPX.Waypoint]) {
        mapView.addAnnotations(waypoints)
        mapView.showAnnotations(waypoints, animated: true)
    }
    
    @IBAction func addWaypoint(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.began {
            let coordinate = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
            let waypoint = EditableWaypoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
            waypoint.name = "Dropped"
            mapView.addAnnotation(waypoint)
        }
    }
    
    
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var view = mapView.dequeueReusableAnnotationView(withIdentifier: Constants.AnnotationViewReuseIdentifier)
        
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Constants.AnnotationViewReuseIdentifier)
            view!.canShowCallout = true
        } else {
            view!.annotation = annotation
        }
        
        view!.isDraggable = annotation is EditableWaypoint
        
        view!.leftCalloutAccessoryView = nil
        view!.rightCalloutAccessoryView = nil
        if let waypoint = annotation as? GPX.Waypoint {
            if waypoint.thumbnailURL != nil {
                view!.leftCalloutAccessoryView = UIButton(frame: Constants.LeftCalloutFrame)
            }
            if annotation is EditableWaypoint {
                view!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            }
        }
        return view
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let waypoint = view.annotation as? GPX.Waypoint {
            if let thumbnailImageButton = view.leftCalloutAccessoryView as? UIButton {
                ///
                DispatchQueue.global(qos: .userInitiated).async {
                    let thumbURL = waypoint.thumbnailURL!
                    let imageDataOpt = try? Data(contentsOf: thumbURL)
                    DispatchQueue.main.async {
                        if thumbURL == waypoint.thumbnailURL! {
                            guard let imageData = imageDataOpt else {
                                thumbnailImageButton.setImage(nil, for: .normal)
                                return
                            }
                            thumbnailImageButton.setImage(UIImage(data: imageData), for: .normal) 
                        }
                    }
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if (control as? UIButton)?.buttonType == .detailDisclosure {
            mapView.deselectAnnotation(view.annotation, animated: false)
            performSegue(withIdentifier: Constants.EditWaypointSegue, sender: view)
        } else if let waypoint = view.annotation as? GPX.Waypoint {
            if waypoint.imageURL != nil {
                performSegue(withIdentifier: Constants.ShowImageSegue, sender: view)
            }
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case Constants.ShowImageSegue:
            if let waypoint = (sender as? MKAnnotationView)?.annotation as? GPX.Waypoint {
                if let ivc = segue.destination as? ImageViewController {
                    ivc.imageURL = waypoint.imageURL
                    ivc.title = waypoint.name
                }
            }
        case Constants.EditWaypointSegue:
            if let waypoint = (sender as? MKAnnotationView)?.annotation as? EditableWaypoint {
                if let ewvc = segue.destination.contentViewController as? EditWaypointViewController {
                    if let ppc = ewvc.popoverPresentationController {
                        let coordinatePoint = mapView.convert(waypoint.coordinate, toPointTo: mapView)
                        ppc.sourceRect = (sender as! MKAnnotationView).popoverSourceRectForCoordinatePoint(coordinatePoint: coordinatePoint)
                        let minimumSize = ewvc.view.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
                        ewvc.preferredContentSize = CGSize(width: Constants.EditWaypointPopoverWidth, height: minimumSize.height)
                        ppc.delegate = self
                    }
                    ewvc.waypointToEdit = waypoint
                }
            }
        default: return
        }
    }
    
    // MARK: - UIAdaptivePresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.overFullScreen // fullscreen, but we can see what's underneath
    }
    
    func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        let navcon = UINavigationController(rootViewController: controller.presentedViewController)
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
        visualEffectView.frame = navcon.view.bounds
        navcon.view.insertSubview(visualEffectView, at: 0) // back-most subview
        return navcon
    }

    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let center = NotificationCenter.default
        let queue = OperationQueue.main
        let appDelegate = UIApplication.shared.delegate
        
        center.addObserver(forName: NSNotification.Name(rawValue: GPXURL.Notification), object: appDelegate, queue: queue) { (notification) in
            if let url = notification.userInfo?[GPXURL.Key] as? URL {
                self.gpxURL = url
            }
        }
        // for testing purposes
        gpxURL = URL(string: "http://cs193p.stanford.edu/Vacation.gpx")
    }
    
    // MARK: - Constants
    
    private struct Constants {
        static let LeftCalloutFrame = CGRect(x: 0, y: 0, width: 59, height: 59)
        static let AnnotationViewReuseIdentifier = "waypoint"
        static let ShowImageSegue = "Show Image"
        static let EditWaypointSegue = "Edit Waypoint"
        static let EditWaypointPopoverWidth: CGFloat = 320

        
        
    }
}

// MARK: - Convenience Extensions

extension UIViewController {
    var contentViewController: UIViewController {
        if let navcon = self as? UINavigationController {
            return navcon.visibleViewController!
        } else {
            return self
        }
    }
}

extension MKAnnotationView {
    func popoverSourceRectForCoordinatePoint(coordinatePoint: CGPoint) -> CGRect {
        // assign coordinatePoint as SourceRectOrigin and then modify as needed
        var popoverSourceRectOrigin = coordinatePoint
        popoverSourceRectOrigin.x -= frame.width / 2 - centerOffset.x - calloutOffset.x
        popoverSourceRectOrigin.y -= frame.height / 2 - centerOffset.y - calloutOffset.y
        return CGRect(origin: popoverSourceRectOrigin, size: frame.size)

    }
}

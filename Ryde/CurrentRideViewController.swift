//
//  CurrentRideViewController.swift
//  Ryde
//
//  Created by Franki Yeung on 4/12/16.
//  Copyright © 2016 Jared Deiner. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import FBSDKCoreKit
import FBSDKLoginKit

class CustomPointAnnotation: MKPointAnnotation {
    var imageName: String!
}

class CurrentRideViewController: UIViewController, RiderSlideMenuDelegate, MKMapViewDelegate {
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    // Rider FB id
    var FBid = ""
    
    // Rider Latitude
    var startLatitude: Double = 0
    
    // Rider Longitude
    var startLongitude: Double = 0
    
    // Destination Latitude
    var destLat: Double = 0
    
    // Destination Longitude
    var destLong: Double = 0
    
    // Route between anotations
    var myRoute : MKRoute?
    
    // Driver name
    var driverName:String = ""
    
    // Driver car info
    var carinfo: String = ""
    
    // Driver Phone Number
    var driverNumber:String = ""
    
    // Timer to schedule tasks
    var updateTask: NSTimer?
    
    // Status of the rider's ride
    var queueStatus:String = "active"
    
    // Mapkit showing the anotations
    @IBOutlet var mapView: MKMapView!
    
    // label of the name of driver assigned
    @IBOutlet var driverNameLabel: UILabel!
    
    // label of the car information of driver
    @IBOutlet var driverCarLabel: UILabel!
    
    // Location manager for handling coordinations
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        
        // Grab data from FB
        let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields" : "id, name, email"])
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            self.FBid = (result.valueForKey("id") as? String)!
        })
        
        // Sets the title of the current Ride
        self.title = "Current Ride"
        
        // Add the side menu bar
        self.addSlideMenuButton()
        
        // Set map view delegate with controller
        self.mapView.delegate = self
        
        // Call method to update driver information and check if ride has completed
        updateRide()
        
        super.viewDidLoad()
        
        // Create the start coordinates
        let startLocation = CLLocationCoordinate2DMake(startLatitude, startLongitude)
        
        // Set the span of the map
        let theSpan:MKCoordinateSpan = MKCoordinateSpanMake(0.03 , 0.03)
        let theRegion:MKCoordinateRegion = MKCoordinateRegionMake(startLocation, theSpan)
        mapView.setRegion(theRegion, animated: true)
    
        // Places an annotation for start location
        let annotation = CustomPointAnnotation()
        annotation.coordinate = startLocation
        annotation.title = "Your pick up location."
        annotation.imageName = "Marker Filled-50"
        mapView.addAnnotation(annotation)
        
        self.mapView.showsUserLocation = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        // Show two anotation and a route instead if a destination was inputted
        if (destLong != 0 && destLat != 0)
        {
            // Create annotation for destination
            let destLocation = CLLocationCoordinate2DMake(destLat, destLong)
            let destAnnotation = CustomPointAnnotation()
            destAnnotation.coordinate = destLocation
            destAnnotation.title = "Your drop off location."
            destAnnotation.imageName = "Destination"
            mapView.addAnnotation(destAnnotation)
            
            // Create a direction from start to destination annotations
            let directionsRequest = MKDirectionsRequest()
            let markStart = MKPlacemark(coordinate: CLLocationCoordinate2DMake(annotation.coordinate.latitude, annotation.coordinate.longitude), addressDictionary: nil)
            let markDest = MKPlacemark(coordinate: CLLocationCoordinate2DMake(destAnnotation.coordinate.latitude, destAnnotation.coordinate.longitude), addressDictionary: nil)
            
            directionsRequest.source = MKMapItem(placemark: markStart)
            directionsRequest.destination = MKMapItem(placemark: markDest)
            directionsRequest.transportType = MKDirectionsTransportType.Automobile
            let directions = MKDirections(request: directionsRequest)
            // Calculates the direction from start to destination
            directions.calculateDirectionsWithCompletionHandler
                {
                    (response, error) -> Void in
                    
                    if let routes = response?.routes where response?.routes.count > 0 && error == nil
                    {
                        let route : MKRoute = routes[0]
                        
                        //distance calculated from the request
                        print(route.distance)
                        //travel time calculated from the request
                        print(route.expectedTravelTime)
                        self.mapView.addOverlay((route.polyline), level: MKOverlayLevel.AboveRoads)
                        
                        var rect = route.polyline.boundingMapRect
                        // reset the mapview to show the route
                        self.mapView.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
                    }
            }
        }
        
        // schedules task for every 3 second to updateRide
        updateTask = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "updateRide", userInfo: nil, repeats: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /**
     * Method for creating a custom annotation with an image
     */
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if !(annotation is CustomPointAnnotation) {
            return nil
        }
        
        let reuseId = "test"
        
        var anView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
        if anView == nil {
            anView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            anView!.canShowCallout = true
        }
        else {
            anView!.annotation = annotation
        }
        
        // Create a new annotation with image path that is passed in
        let cpa = annotation as! CustomPointAnnotation
        anView!.image = UIImage(named:cpa.imageName)
        
        return anView
    }
    
    /**
     * Method for updating ride information and checking if ride has completed
     */
    func updateRide(){
        // Post a request to update ride information
        let postUrl = ("http://\(self.appDelegate.baseURL)/Ryde/api/ride/driverInfo/" + self.FBid)
        self.getRideInfo(postUrl)
        
        // Update view labels if information has changed for driver
        driverNameLabel.text = "Driver Name: " + driverName
        driverCarLabel.text = "Driver's Car: " + carinfo
        
        // Pop back to home view of the rider if the ride is over
        if queueStatus != "active"
        {
            self.tabBarController?.tabBar.hidden = false
            self.updateTask?.invalidate()
            self.navigationController?.popToRootViewControllerAnimated(true)
        }
    }
    
    // Get Function for Checking updates on ride
    func getRideInfo(url : String) {
        
        //Create a http request, type GET
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "GET"
        
        let task = session.dataTaskWithRequest(request)
        {
            (data, response, error) in
            guard let _ = data else {
                print("error calling")  // Request failed
                return
            }
            let json: NSDictionary?
            
            // Attempt to read the http request body as JSON
            do {
                json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? NSDictionary
            } catch let dataError{
                
                // Did the JSONObjectWithData constructor return an error? If so, log the error to the console
                print(dataError)
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Error could not parse JSON: '\(jsonStr)'")
                return
            }
            
            // read the new JSON
            if let parseJSON = json {
                // Grab the status of the ride
                if let status = parseJSON["queueStatus"] as? String
                {
                    // Check if the rider's ride is over
                    if status == "notInQueue"
                    {
                        self.appDelegate.rydesTakenCount += 1
                        self.queueStatus = status
                    }
                    else if status == "nonActive"   // Check if the rider's ride was cancelled by driver
                    {
                        self.queueStatus = status
                        //segue back to queue?
                        print("nonActive")
                    }
                    else if status == "active"  // Check if the ride is still active, update driver information
                    {
                        self.queueStatus = status
                        if  let rideJSON = parseJSON["ride"] as? NSDictionary
                        {
                            if let driverJSON = rideJSON["driverUserId"] as? NSDictionary
                            {
                                if let firstName = driverJSON["firstName"] as? String{
                                    self.driverName = firstName
                                }
                                if let lastName = driverJSON["lastName"] as? String{
                                    self.driverName = self.driverName + " " + lastName
                                }
                                if let carMake = driverJSON["carMake"] as? String{
                                    self.carinfo = carMake
                                }
                                if let carModel = driverJSON["carModel"] as? String{
                                    self.carinfo = self.carinfo + " " + carModel
                                }
                                if let carColor = driverJSON["carColor"] as? String{
                                    self.carinfo = self.carinfo + ", " + carColor
                                }
                                if let driverPhoneNumber = driverJSON["phoneNumber"] as? String{
                                    self.driverNumber = driverPhoneNumber
                                }
                            }
                        }
                    }
                }
            }
            else {
                // Woa, okay the json object was nil, something went worng. Maybe the server isn't running?
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Error could not parse JSON: \(jsonStr)")
            }
        }
        
        task.resume()
    }
    
    /*
     Creates an alert box when contact driver is clicked
     prints the driver number in the alert box and allow for rider to call driver
    */
    func contactDriverAlert()
    {
        let alert = UIAlertController(title: driverName + "'s Phone Number", message: driverNumber, preferredStyle: UIAlertControllerStyle.Alert)
        
        // Handles action if the rider wants to call driver, switch to phone application and calls the number
        alert.addAction(UIAlertAction(title: "Call", style: .Default, handler: { (action: UIAlertAction!) in
            if let url = NSURL(string: "tel://\(self.driverNumber)") {
                UIApplication.sharedApplication().openURL(url)
            }
        }))
        
        // Closes alert box
        alert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: { (action: UIAlertAction!) in
            
        }))
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    /*
     Creates an alert box cancel ride is clicked
     post a delete request and pop to root view
     */
    func cancelRideAlert()
    {
        let alert = UIAlertController(title: "Are you sure you want to cancel ride?", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        
        // Attempt to cancel ride if the user presses Yes
        alert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action: UIAlertAction!) in
            // Bring back tabBar before segueing to home screen
            self.tabBarController?.tabBar.hidden = false
            
            // Post a request to server to delete the ride from the queue and database
            let postUrl = ("http://\(self.appDelegate.baseURL)/Ryde/api/ride/cancel/" + self.FBid)
            self.postCancel(postUrl)
            // Stops the scheduled method
            self.updateTask?.invalidate()
            // change back to home screen of rider
            self.navigationController?.popToRootViewControllerAnimated(true)
        }))
        
        // Closes the alert box
        alert.addAction(UIAlertAction(title: "No", style: .Default, handler: { (action: UIAlertAction!) in
            //do nothing
        }))
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // Post Function for Canceling, deletes the ride from the server and database
    func postCancel(url : String) {
        
        // Create a new http request, type DELETE
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "DELETE"
        
        let task = session.dataTaskWithRequest(request)
        {
            (data, response, error) in
            guard let _ = data else {
                print("error calling")  // request failed
                return
            }
        }
        
        task.resume()
    }
    
    //Handles Slide Menu interaction
    func slideMenuItemSelectedAtIndex(index: Int32) {
        let topViewController : UIViewController = self.navigationController!.topViewController!
        print("View Controller is : \(topViewController) \n", terminator: "")
        switch(index){
        case 0:
            print("Contact Driver\n", terminator: "")  // contact driver is pressed
            
            contactDriverAlert() // calls contact driver method to bring up alert
            
            break
        case 1:
            print("Cancel Ride\n", terminator: "")  // cancel ride is pressed
            
            cancelRideAlert()   // Calls cancel ride to bring up alert
            
            break
        default:
            print("default\n", terminator: "")  // Closes menu
        }
    }
    
    // Method to bring up slidemenu
    func openViewControllerBasedOnIdentifier(strIdentifier:String){
        let destViewController : UIViewController = self.storyboard!.instantiateViewControllerWithIdentifier(strIdentifier)
        
        let topViewController : UIViewController = self.navigationController!.topViewController!
        
        if (topViewController.restorationIdentifier! == destViewController.restorationIdentifier!){
            print("Same VC")
        } else {
            self.navigationController!.pushViewController(destViewController, animated: true)
        }
    }
    
    // Create and add button on navigation bar to open up slidemenu
    func addSlideMenuButton(){
        let btnShowMenu = UIButton(type: UIButtonType.System)
        btnShowMenu.setImage(self.defaultMenuImage(), forState: UIControlState.Normal)
        btnShowMenu.frame = CGRectMake(0, 0, 30, 30)
        btnShowMenu.addTarget(self, action: #selector(self.onSlideMenuButtonPressed(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        let customBarItem = UIBarButtonItem(customView: btnShowMenu)
        self.navigationItem.leftBarButtonItem = customBarItem;
    }
    
    // Set the menu image to icons
    func defaultMenuImage() -> UIImage {
        var defaultMenuImage = UIImage()
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(30, 22), false, 0.0)
        
        UIColor.blackColor().setFill()
        UIBezierPath(rect: CGRectMake(0, 3, 30, 1)).fill()
        UIBezierPath(rect: CGRectMake(0, 10, 30, 1)).fill()
        UIBezierPath(rect: CGRectMake(0, 17, 30, 1)).fill()
        
        UIColor.whiteColor().setFill()
        UIBezierPath(rect: CGRectMake(0, 4, 30, 1)).fill()
        UIBezierPath(rect: CGRectMake(0, 11,  30, 1)).fill()
        UIBezierPath(rect: CGRectMake(0, 18, 30, 1)).fill()
        
        defaultMenuImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return defaultMenuImage;
    }
    
    // Handles if pressed while on the slide menu
    func onSlideMenuButtonPressed(sender : UIButton){
        if (sender.tag == 10)
        {
            // To Hide Menu If it already there
            self.slideMenuItemSelectedAtIndex(-1);
            
            sender.tag = 0;
            
            let viewMenuBack : UIView = view.subviews.last!
            
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                var frameMenu : CGRect = viewMenuBack.frame
                frameMenu.origin.x = -1 * UIScreen.mainScreen().bounds.size.width
                viewMenuBack.frame = frameMenu
                viewMenuBack.layoutIfNeeded()
                viewMenuBack.backgroundColor = UIColor.clearColor()
                }, completion: { (finished) -> Void in
                    viewMenuBack.removeFromSuperview()
            })
            
            return
        }
        
        sender.enabled = false
        sender.tag = 10
        
        let menuVC : RiderMenuViewController = self.storyboard!.instantiateViewControllerWithIdentifier("RiderMenuViewController") as! RiderMenuViewController
        menuVC.btnMenu = sender
        menuVC.delegate = self
        self.view.addSubview(menuVC.view)
        self.addChildViewController(menuVC)
        menuVC.view.layoutIfNeeded()
        
        
        menuVC.view.frame=CGRectMake(0 - UIScreen.mainScreen().bounds.size.width, 0, UIScreen.mainScreen().bounds.size.width, UIScreen.mainScreen().bounds.size.height);
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            menuVC.view.frame=CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width, UIScreen.mainScreen().bounds.size.height);
            sender.enabled = true
            }, completion:nil)
    }
    
    // Rerender the map with route and change the route line color and size
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        // set the line to blue
        renderer.strokeColor = UIColor.blueColor()
        // sets the route line width
        renderer.lineWidth = 3.0
        
        return renderer
    }
    
}

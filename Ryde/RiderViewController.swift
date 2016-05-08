//
//  RiderViewController.swift
//  Ryde
//
//  Created by Joe Fletcher on 4/3/16.
//  Copyright © 2016 Jared Deiner. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

protocol HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark, destination:String)
    func cancelSearch()
}

class RiderViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITextFieldDelegate, HandleMapSearch, UISearchControllerDelegate, UISearchBarDelegate {

    // The label showcasing the current address of the User
    @IBOutlet var address: UILabel!
    
    // Map View Reference from StoryBoard
    @IBOutlet var mapView: MKMapView!
    
    // Location Manager instance
    let locationManager = CLLocationManager()
    
    // Geo Coder Reference
    var geoCoder: CLGeocoder!
    
    // Previous Address String
    var previousAddress: String!
    
    //current user Latitude
    var previousLat: Double = 0
    
    //current user Longitude
    var previousLong: Double = 0
    
    // Destination Latitude
    var destLat: Double = 0
    
    // Destination Longitude
    var destLong: Double = 0
    
    // Last known current location of the user
    var lastLocation = CLLocation()
    
    // View for pick up/ drop off adreesses
    @IBOutlet var addressView: UIView!
    
    // Destination pin
    var selectedPin:MKPlacemark? = nil
    
    // Search Controller
    var resultSearchController:UISearchController? = nil
    
    // Destination Button to Search
    
    @IBOutlet var destinationButton: UIButton!
    
    // Dictionary to store the drivers timeslot
    var timeslotDictionary = NSDictionary()
    
    // Store the timeslot id once retrieved
    var timeslotID = ""
    
    // The Facebook ID of the current User
    var fbToken = ""
    
    // The driverStatus of the current user
    var driverStatus: Bool!
    
    // Driver name
    var driverName:String = ""
    
    // Driver car info
    var carinfo: String = ""
    
    // Driver Phone Number
    var driverNumber:String = ""
    
    var activeDriver = false
    
    let semaphore = dispatch_semaphore_create(0);
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

    var startTime = ""
    var endTime = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //UINavigationBar.appearance().barTintColor = UIColor(red: 73, green: 181, blue: 138, alpha: 0)

        
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.delegate = self
        self.locationManager.requestAlwaysAuthorization()
//        self.locationManager.requestLocation()
        self.locationManager.startUpdatingLocation()
        self.mapView.showsUserLocation = true
        self.mapView.delegate = self
        
        geoCoder = CLGeocoder()
        
        fbToken = self.appDelegate.FBid
        
        getRiderQueueStatus(("http://\(self.appDelegate.baseURL)/Ryde/api/ride/driverInfo/" + self.fbToken))
        //getRiderQueueStatus(("http://\(self.appDelegate.baseURL)/Ryde/api/ride/driverInfo/MikeFBTok"))
    }
    
    // Mark - Cancel Search
    
    func cancelSearch() {
        
        if addressView.subviews.count > 1 {
            addressView.subviews.last?.removeFromSuperview()
            destinationButton.setTitle("Enter Destination", forState: UIControlState.Normal)
        }
            
        
    }
    
    
    // Mark - Destination Pin Drop
    // Link: http://www.thorntech.com/2016/01/how-to-search-for-location-using-apples-mapkit/
    
    func dropPinZoomIn(placemark:MKPlacemark, destination:String){
        
        // cache the pin
        selectedPin = placemark
        // clear existing pins
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            annotation.subtitle = "\(city) \(state)"
        }
        mapView.addAnnotation(annotation)
        
        self.destLat = Double(placemark.coordinate.latitude)
        self.destLong = Double(placemark.coordinate.longitude)
        
        addressView.subviews.last?.removeFromSuperview()
        
        destinationButton.setTitle(destination, forState: UIControlState.Normal)
        
        //        The following code drops a pin where the user searched but we dont want that. Just in case im leaving it here.
        
        //        let span = MKCoordinateSpanMake(0.05, 0.05)
        //        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        //        mapView.setRegion(region, animated: true)
    }
    
    // Mark - Change Destination Button Clicked
    
    @IBAction func changeDestination(sender: UIButton) {
        
        let locationSearchTable = storyboard!.instantiateViewControllerWithIdentifier("LocationSearchTable") as! LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        let searchBar = resultSearchController!.searchBar
        
        searchBar.placeholder = "Enter Destination"
        
        let frame = CGRect(x: 0, y: -2, width: 100, height: 30)
        resultSearchController!.searchBar.backgroundImage = UIImage()
        resultSearchController!.searchBar.frame = frame
        
        addressView.addSubview((resultSearchController?.searchBar)!)

        
        searchBar.sizeToFit()
        
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        locationSearchTable.mapView = mapView
        
        locationSearchTable.handleMapSearchDelegate = self
        
        self.resultSearchController!.delegate = self
        self.resultSearchController!.active = true
        self.resultSearchController!.delegate = self
        
    }
    
    // Mark - Present Search Controller right now
    
    func didPresentSearchController(searchController: UISearchController) {
        self.resultSearchController!.searchBar.becomeFirstResponder()
    }
    

    
    // Mark - Location Delegate Methods
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        print("location updated")
        
        self.locationManager.stopUpdatingLocation()
        
        lastLocation = locations.last!
        
        let location: CLLocation = locations.first!
        self.mapView.centerCoordinate = location.coordinate
        let reg = MKCoordinateRegionMakeWithDistance(location.coordinate, 1500, 1500)
        self.mapView.setRegion(reg, animated: true)
        geoCode(location)
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error with Map View: " + error.localizedDescription)
    }

    
    // Mark - Map View Methods
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let location = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        geoCode(location)
    }
    
    // Mark - Custom Methods
    
    func geoCode(location : CLLocation!){
        /* Only one reverse geocoding can be in progress at a time hence we need to cancel existing
         one if we are getting location updates */
        geoCoder.cancelGeocode()
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (data, error) -> Void in
            guard let placeMarks = data as [CLPlacemark]! else {
                return
            }
            let loc: CLPlacemark = placeMarks[0]
            let addressDict : [NSString:NSObject] = loc.addressDictionary as! [NSString: NSObject]
            let addrList = addressDict["FormattedAddressLines"] as! [String]
            
            let address = addrList[0]
            self.address.text = address
            self.previousAddress = address
            self.previousLat = Double(location.coordinate.latitude)
            self.previousLong = Double(location.coordinate.longitude)
        })
        
    }
    
    
    // Mark - Re-set to current location
    @IBAction func resetToCurrentLocation(sender: UIButton) {

        let userLocation = self.lastLocation
        
        let reg = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 1500, 1500)
        self.mapView.setRegion(reg, animated: true)
    }
    
    
    // Mark - Request Ryde button is pressed
    @IBAction func RequestRydeClicked(sender: UIButton) {
        performSegueWithIdentifier("ShowRiderRequestGroup", sender: self)
    }
    
    // Mark - Get Rid of Keyboard when Done Editing
    /**
     * Called when 'return' key pressed. return NO to ignore.
     */
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    /**
     * Called when the user click on the view (outside the UITextField).
     */
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // Mark - Retrieve the driver's timeslot from the server
    
    func getDriverTimeslot() {
        let url = NSURL(string: "http://\(self.appDelegate.baseURL)/Ryde/api/user/findActiveDriverTimeslot/\(fbToken)")
        
        // Creaste URL Request
        let request = NSMutableURLRequest(URL:url!);
        
        // Set request HTTP method to GET. It could be POST as well
        request.HTTPMethod = "GET"
        
        // If needed you could add Authorization header value
        //request.addValue("Token token=884288bae150b9f2f68d8dc3a932071d", forHTTPHeaderField: "Authorization")
        
        // Execute HTTP Request
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            
            // Check for error
            if error != nil
            {
                print("error=\(error)")
                return
            }
            
            // Print out response string
            let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            //print("responseString = \(responseString!)")
            
            
            let json: NSDictionary?
            
            do {
                
                json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? NSDictionary
                
            }
            catch let dataError{
                
                // Did the JSONObjectWithData constructor return an error? If so, log the error to the console
                print(dataError)
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Error could not parse JSON: '\(jsonStr!)'")
                // return or throw?
                self.activeDriver = false
                dispatch_semaphore_signal(self.semaphore);
                return
            }
            
            // The JSONObjectWithData constructor didn't return an error. But, we should still
            // check and make sure that json has a value using optional binding.
            if let parseJSON = json {
                // Okay, the parsedJSON is here, lets store its values into an array
                self.timeslotDictionary = parseJSON as NSDictionary
                self.activeDriver = true
                
            }
            else {
                // Woa, okay the json object was nil, something went worng. Maybe the server isn't running?
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Error could not parse JSON: \(jsonStr!)")
            }
            dispatch_semaphore_signal(self.semaphore);
            
        })
        
        task.resume()
    }
    

    // First get user datat to check if driver status is true. If it is
    // then get timeslot data and queue data before performing segue
    // to driver view
    @IBAction func driverLoginBtnPressed(sender: UIBarButtonItem) {
        self.getDriverTimeslot()
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        print("timeslot = \(timeslotDictionary)")
        
        
        if (activeDriver){         // login successful, user is currently a driver
            self.performSegueWithIdentifier("DriverLogin", sender: self)
            
            
        } else {                                //login failed, user is not currently a driver
            let alertController = UIAlertController(title: "Driver Login Failed",
                                                    message: "You are not currently registered as a driver for a group.",
                                                    preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
            
            // Present the alert controller by calling the presentViewController method
            presentViewController(alertController, animated: true, completion: nil)
        }
        
    }
    
    
    /**
     * Get request for checking if user has already requested a ride
     *
     * Set appropriate fields if a ride request or ride exists and segues to 
     * different screens
     */
    func getRiderQueueStatus(url : String) {
        
        // Create a new HTTP request, type GET
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "GET"
        
        // Send the HTTP request and handle the returned JSON
        let task = session.dataTaskWithRequest(request)
        {
            (data, response, error) in
            guard let _ = data else {
                print("error calling")  // If the get request fails, return
                return
            }
            let json: NSDictionary?
            
            // Attempt to parse the response body and put it into local variable json
            do {
                json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? NSDictionary
            } catch let dataError{
                
                // Did the JSONObjectWithData constructor return an error? If so, log the error to the console
                print(dataError)
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Error could not parse JSON: '\(jsonStr)'")
                return
            }
            // json correctly retrieved, now parse for needed information
            if let parseJSON = json {
                // Check the ride status of the rider to see if the rider is in the queue or has a ride
                if let status = parseJSON["queueStatus"] as? String
                {
                    // Rider has requested a ride and is in the queue, set location information and segue to
                    // RequestRideViewController
                    if status == "nonActive"
                    {
                        if  let rideJSON = parseJSON["ride"] as? NSDictionary
                        {
                            if let startLat = rideJSON["startLat"] as? Double
                            {
                                self.previousLat = startLat
                            }
                            if let startLong = rideJSON["startLon"] as? Double
                            {
                                self.previousLong = startLong
                            }
                            if let endLat = rideJSON["endLat"] as? Double
                            {
                                self.destLat = endLat
                            }
                            if let endLong = rideJSON["endLon"] as? Double
                            {
                                self.destLong = endLong
                            }
                        }
                        self.performSegueWithIdentifier("homeShowRequestView", sender: self)
                    }
                    // Rider has a current Ride, Retrieve driver's information and ride location information
                    // Segue to CurrentRideViewController
                    else if status == "active"
                    {
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
                            if let startLat = rideJSON["startLat"] as? Double
                            {
                                self.previousLat = startLat
                            }
                            if let startLong = rideJSON["startLon"] as? Double
                            {
                                self.previousLong = startLong
                            }
                            if let endLat = rideJSON["endLat"] as? Double
                            {
                                self.destLat = endLat
                            }
                            if let endLong = rideJSON["endLon"] as? Double
                            {
                                self.destLong = endLong
                            }
                        }
                        self.performSegueWithIdentifier("homeShowCurrentRide", sender: self)
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
    
    func convertTime(startHour : Int, startMin : Int, endHour : Int, endMin : Int){
        var sTimeStamp = ""
        var sHour = 0
        var eTimeStamp = ""
        var eHour = 0
        
        if (startHour > 0 && startHour < 12){
            sTimeStamp = "a.m."
            sHour = startHour
        } else if (startHour > 12 &&  startHour < 24){
            sTimeStamp = "p.m."
            sHour = startHour - 12
        } else if (startHour == 0){
            sTimeStamp = "a.m."
            sHour = 12
        } else if (startHour == 12){
            sTimeStamp = "p.m."
            sHour = startHour
        }
        
        if (endHour > 0 && endHour < 12){
            eTimeStamp = "a.m."
            eHour = endHour
        } else if (endHour > 12 &&  endHour < 24){
            eTimeStamp = "p.m."
            eHour = endHour - 12
        } else if (endHour == 0){
            eTimeStamp = "a.m."
            eHour = 12
        } else if (endHour == 12){
            eTimeStamp = "p.m."
            eHour = endHour
        }
        
        startTime = String(format: "\(sHour):%02d \(sTimeStamp)", startMin)
        endTime = String(format: "\(eHour):%02d \(eTimeStamp)", endMin)
        
    }
    
    /*
     -------------------------
     MARK: - Prepare For Segue
     -------------------------
     */
    
    // This method is called by the system whenever you invoke the method performSegueWithIdentifier:sender:
    // You never call this method. It is invoked by the system.
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        
        if segue.identifier == "ShowRiderRequestGroup" {
            
            // Obtain the object reference of the destination view controller
            let riderRequestGroupTableViewController: RiderRequestGroupTableViewController = segue.destinationViewController as! RiderRequestGroupTableViewController
            
            self.tabBarController?.tabBar.hidden = true
            
            riderRequestGroupTableViewController.address = self.previousAddress
            riderRequestGroupTableViewController.startLatitude = self.previousLat
            riderRequestGroupTableViewController.startLongitude = self.previousLong
            riderRequestGroupTableViewController.destLat = self.destLat
            riderRequestGroupTableViewController.destLong = self.destLong
            
            print("Ride Requested: Destination: \(self.previousLat) , \(self.previousLong)\t\(self.destLat) , \(self.destLong)")
        } else if segue.identifier == "DriverLogin" {
            
            // Obtain the object reference of the destination view controller
            let driverMainViewController: DriverMainViewController = segue.destinationViewController as! DriverMainViewController
            
            let tempStartTime = timeslotDictionary["startTime"] as! String
            let tempEndTime = timeslotDictionary["endTime"] as! String
            let tsID = timeslotDictionary["id"] as! Int
            
            //Get the Start Time
            let dateStartArray = tempStartTime.componentsSeparatedByString("T")
            let timeAndZoneStart = dateStartArray[1]
            let timeStartArray = timeAndZoneStart.componentsSeparatedByString(":")
            
            //Get the End time
            let dateEndArray = tempEndTime.componentsSeparatedByString("T")
            let timeAndZoneEnd = dateEndArray[1]
            let timeEndArray = timeAndZoneEnd.componentsSeparatedByString(":")

            //Convert the time
            convertTime(Int(timeStartArray[0])!, startMin: Int(timeStartArray[1])!, endHour: Int(timeEndArray[0])!, endMin: Int(timeEndArray[1])!)
            driverMainViewController.endTime = endTime
            driverMainViewController.startTime = startTime
            driverMainViewController.timeSlotID = tsID
            
            activeDriver = false //Clear dictionary so it must be reloaded if the user logs out
        } else if segue.identifier == "homeShowCurrentRide" {
            // Obtain the object reference of the destination view controller
            let currentRideViewController: CurrentRideViewController = segue.destinationViewController as! CurrentRideViewController
            
            // Pass all needed information downwind to currentRideViewController
            currentRideViewController.startLatitude = self.previousLat
            currentRideViewController.startLongitude = self.previousLong
            currentRideViewController.destLat = self.destLat
            currentRideViewController.destLong = self.destLong
            currentRideViewController.driverName = self.driverName
            currentRideViewController.carinfo = self.carinfo
            currentRideViewController.driverNumber = self.driverNumber
        } else if segue.identifier == "homeShowRequestView" {
            // Obtain the object reference of the destination view controller
            let requestRideViewController: RequestRideViewController = segue.destinationViewController as! RequestRideViewController
            
            // Pass all needed information downwind to requestRideViewController
            requestRideViewController.destLat = self.destLat
            requestRideViewController.destLong = self.destLong
            requestRideViewController.startLongitude = self.previousLong
            requestRideViewController.startLatitude = self.previousLat
        }
    }
    
}
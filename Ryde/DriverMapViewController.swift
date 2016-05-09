//
//  DriverMapViewController.swift
//  Ryde
//
//  Created by Blake Duncan on 4/6/16.
//  Copyright © 2016 Jared Deiner. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class DriverMapViewController: DriverBaseViewController, UIWebViewDelegate,  MKMapViewDelegate,CLLocationManagerDelegate, UITextFieldDelegate, HandleMapSearch, UISearchControllerDelegate, UISearchBarDelegate{
    
    //needed fields
    var riderName = "Blake Duncan"
    var rideID = 0
    var riderPhone = ""
    var riderLat = 0.0
    var riderLng = 0.0
    var driverLat = 0.0
    var driverLng = 0.0
    var destLat = 0.0
    var destLng = 0.0
    var searchLat = 0.0
    var searchLng = 0.0
    
    //False if driver hasn't picked up rider and true otherwise
    var hasRider = false
    
    @IBOutlet var headerLabel: UILabel!
    @IBOutlet var riderNameLabel: UILabel!
    @IBOutlet var webView: UIWebView!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var callButton: UIButton!
    @IBOutlet var driverButton: UIButton!
    
    //google maps fields
    var mapsHtmlFilePath: String?
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    // Search Controller
    var resultSearchController:UISearchController? = nil
    // View for pick up/ drop off adreesses
    @IBOutlet var addressView: UIView!
    // Destination Button to Search
    @IBOutlet var destinationButton: UIButton!
    // Map View Reference from StoryBoard
    @IBOutlet var mapView: MKMapView!
    // Destination pin
    var selectedPin:MKPlacemark? = nil
    // Location Manager instance
    let locationManager = CLLocationManager()
    
    // Geo Coder Reference
    var geoCoder: CLGeocoder!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        destinationButton.hidden = true
        addressView.hidden = true
        
        //hide back button and add slide menu
        self.navigationItem.setHidesBackButton(true, animated:true);
        
        riderNameLabel.text = riderName
        hasRider = false
        
        //Get the maps html file path and save it to a field
        mapsHtmlFilePath = NSBundle.mainBundle().pathForResource("maps", ofType: "html")
        
        //now load the map
        loadMapView(1)
        
        self.mapView.showsUserLocation = true
        self.mapView.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.delegate = self
        self.locationManager.requestAlwaysAuthorization()
        //        self.locationManager.requestLocation()
        self.locationManager.startUpdatingLocation()
        
        geoCoder = CLGeocoder()
    }
    
    
    func loadMapView(showMap: Int){
        let tempDriverLat = String(driverLat)
        let tempDriverLng = String(driverLng)
        let driverCoord = "\(tempDriverLat),\(tempDriverLng)"
        let tempRiderLat = String(riderLat)
        let tempRiderLng = String(riderLng)
        let riderCoord = "\(tempRiderLat),\(tempRiderLng)"
        let tempSearchLat = String(searchLat)
        let tempSearchLng = String(searchLng)
        let destCoord = "\(tempSearchLat),\(tempSearchLng)"
        var googleMapQuery = ""
        
        if showMap == 1 {
            googleMapQuery = mapsHtmlFilePath! + "?start=\(driverCoord)&end=\(riderCoord)&traveltype=DRIVING"
        } else {
            googleMapQuery = mapsHtmlFilePath! + "?start=\(driverCoord)&end=\(destCoord)&traveltype=DRIVING"
        }
        
        // Obtain the data passed from the upstream view controller VTPlaceInfoViewController
        let mapQuery = googleMapQuery
        
        /*
         Convert the mapQuery into an NSURL object and store its object reference
         into the local variable url. An NSURL object represents a URL.
         */
        let url: NSURL? = NSURL(string: mapQuery)
        
        /*
         Convert the NSURL object into an NSURLRequest object and store its object
         reference into the local variable request. An NSURLRequest object represents
         a URL load request in a manner independent of protocol and URL scheme.
         */
        let request = NSURLRequest(URL: url!)
        
        // Ask the webView object to display the web page for the given URL
        webView.loadRequest(request)
    }
    
    func pickupConfirmed(){
        headerLabel.text = "Drop Off"
        self.driverButton.setTitle("Ride Over", forState: .Normal)
        hasRider = true
        callButton.hidden = true
        cancelButton.hidden = true
        
        if (destLat != 0 || destLng != 0){
        //load new directions
        let tempDriverLat = String(riderLat)
        let tempDriverLng = String(riderLng)
        let driverCoord = "\(tempDriverLat),\(tempDriverLng)"
        
        let tempDropLat = String(destLat)
        let tempDropLng = String(destLng)
        let dropOffCoord = "\(tempDropLat),\(tempDropLng)"
        
        let googleMapQuery: String = mapsHtmlFilePath! + "?start=\(driverCoord)&end=\(dropOffCoord)&traveltype=DRIVING"
        
        let mapQuery = googleMapQuery
        
        let url: NSURL? = NSURL(string: mapQuery)
        
        let request = NSURLRequest(URL: url!)
        webView.loadRequest(request)
        } else {
            let alertController = UIAlertController(title: "No rider desitnation entered",
                                                    message: "Would you like to enter a destination?",
                                                    preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Enter Destiniation", style: .Default, handler: { (action: UIAlertAction!) in
                
                self.destinationButton.hidden = false
                self.addressView.hidden = false
                
            }))
            
            // Create a UIAlertAction object and add it to the alert controller
            alertController.addAction(UIAlertAction(title: "No", style: .Default, handler: nil))

            
            // Present the alert controller by calling the presentViewController method
            presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func changeDestination(sender: UIButton) {
        
        let locationSearchTable = storyboard!.instantiateViewControllerWithIdentifier("LocationSearchTable") as! LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        let searchBar = resultSearchController!.searchBar
        
        searchBar.placeholder = "Enter Destination"
        
        let frame = CGRect(x: 0, y: -1, width: 100, height: 30)
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
        
        self.searchLat = Double(placemark.coordinate.latitude)
        self.searchLng = Double(placemark.coordinate.longitude)
        self.driverLat = mapView.centerCoordinate.latitude
        self.driverLng = mapView.centerCoordinate.longitude
        
        addressView.subviews.last?.removeFromSuperview()
        
        destinationButton.setTitle(destination, forState: UIControlState.Normal)
        loadMapView(2)
        self.destinationButton.hidden = true
        self.addressView.hidden = true

        
        //        The following code drops a pin where the user searched but we dont want that. Just in case im leaving it here.
        
        //        let span = MKCoordinateSpanMake(0.05, 0.05)
        //        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        //        mapView.setRegion(region, animated: true)
    }
    
    // Mark - Cancel Search
    
    func cancelSearch() {
        
        if addressView.subviews.count > 1 {
            addressView.subviews.last?.removeFromSuperview()
            destinationButton.setTitle("Enter Destination", forState: UIControlState.Normal)
        }
        
        
    }
    
    // Mark - Cancel Button
    
    @IBAction func cancelButtonPressed(sender: UIButton) {
        //confirm pickup
        let alertController = UIAlertController(title: "Confirmation",
                                                message: "Are you sure you would like to cancel pickup?",
                                                preferredStyle: UIAlertControllerStyle.Alert)
        
        // Create a UIAlertAction object and add it to the alert controller
        alertController.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action: UIAlertAction!) in
            
            //cancel pickup.  Rider is left in queue but driver is unassigned
            self.put("http://\(self.appDelegate.baseURL)/Ryde/api/ride/driverCancel/\(self.appDelegate.FBid)/")
            
            self.navigationController?.popViewControllerAnimated(true)
        }))
        alertController.addAction(UIAlertAction(title: "No", style: .Default, handler: nil))
        
        // Present the alert controller by calling the presentViewController method
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    // Mark - Pick Up Button
    
    @IBAction func pickupButtonPressed(sender: UIButton) {
        if !hasRider {
            
            //confirm pickup
            let alertController = UIAlertController(title: "Confirm",
                                                    message: "Confirm that pickup has been made",
                                                    preferredStyle: UIAlertControllerStyle.Alert)
            
            // Create a UIAlertAction object and add it to the alert controller
            alertController.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action: UIAlertAction!) in
                self.pickupConfirmed()
            }))
            alertController.addAction(UIAlertAction(title: "No", style: .Default, handler: nil))
            
            // Present the alert controller by calling the presentViewController method
            presentViewController(alertController, animated: true, completion: nil)
            
        } else if hasRider{
            
            //confirm ride over and drop off made
            let alertController = UIAlertController(title: "Confirm",
                                                    message: "Confirm that ride is over and drop off has been made",
                                                    preferredStyle: UIAlertControllerStyle.Alert)
            
            // Create a UIAlertAction object and add it to the alert controller
            alertController.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action: UIAlertAction!) in

                //Ride is over so post to db
                let JSONObject: [String : String] = [
                    "id"  : "\(self.rideID)"
                ]
                
                //Sends a POST to the specified URL with the JSON conent
                self.post(JSONObject, url: "http://\(self.appDelegate.baseURL)/Ryde/api/ride/endRide/\(self.rideID)")
                
                //update counter
                self.appDelegate.rydesGivenCount += 1
                
                self.navigationController?.popViewControllerAnimated(true)
            }))
            alertController.addAction(UIAlertAction(title: "No", style: .Default, handler: nil))
            
            // Present the alert controller by calling the presentViewController method
            presentViewController(alertController, animated: true, completion: nil)
        }
        
    }
    
    // Mark - Call Rider Button
    
    @IBAction func phoneButtonPressed(sender: UIButton) {
        
        if let url = NSURL(string: "tel://\(riderPhone)") {
            UIApplication.sharedApplication().openURL(url)
        }
        
    }
    
    // SOURCE: http://jamesonquave.com/blog/making-a-post-request-in-swift/
    func post(params : Dictionary<String, String>, url : String) {
        print("end ride post start here")
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        
        
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(params, options: [])
        } catch {
            print(error)
            request.HTTPBody = nil
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            print("Response: \(response)")
            let strData = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("Body: \(strData)")
            
            let json: NSDictionary?
            
            do {
                json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as? NSDictionary
            } catch let dataError{
                
                // Did the JSONObjectWithData constructor return an error? If so, log the error to the console
                print(dataError)
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Error could not parse JSON: '\(jsonStr)'")
                // return or throw?
                return
            }
            
            // The JSONObjectWithData constructor didn't return an error. But, we should still
            // check and make sure that json has a value using optional binding.
            if let parseJSON = json {
                // Okay, the parsedJSON is here, let's get the value for 'success' out of it
                let success = parseJSON["success"] as? Int
                print("Succes: \(success)")
            }
            else {
                // Woa, okay the json object was nil, something went worng. Maybe the server isn't running?
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Error could not parse JSON: \(jsonStr)")
            }
        })
        
        task.resume()
    }
    
    // Mark - Generic POST function that takes in a JSON dictinoary and the URL to be POSTed to
    
    
    // SOURCE: http://jamesonquave.com/blog/making-a-post-request-in-swift/
    func put(url : String) {
        
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "PUT"
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            print("Response: \(response)")
            /**
             let strData = NSString(data: data!, encoding: NSUTF8StringEncoding)
             print("Body: \(strData)")
             
             let json: NSDictionary?
             
             do {
             json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as? NSDictionary
             } catch let dataError{
             
             // Did the JSONObjectWithData constructor return an error? If so, log the error to the console
             print(dataError)
             let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
             print("Error could not parse JSON: '\(jsonStr)'")
             // return or throw?
             return
             }
             
             // The JSONObjectWithData constructor didn't return an error. But, we should still
             // check and make sure that json has a value using optional binding.
             
             if let parseJSON = json {
             // Okay, the parsedJSON is here, let's get the value for 'success' out of it
             let success = parseJSON["success"] as? Int
             print("Succes: \(success)")
             }
             else {
             // Woa, okay the json object was nil, something went worng. Maybe the server isn't running?
             let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
             print("Error could not parse JSON: \(jsonStr)")
             }
             **/
        })
        
        task.resume()
    }

    
    /*
     -------------------------
     MARK: - Prepare for Segue
     -------------------------
     */
    // This method is called by the system whenever you invoke the method performSegueWithIdentifier:sender:
    // You never call this method. It is invoked by the system.
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        
        if segue.identifier == "RideOver" {
            
            // Obtain the object reference of the destination (downstream) view controller
            //let driverMapViewController: DriverMapViewController = segue.destinationViewController as! DriverMapViewController
            
            
        }
    }
    
    // Mark - Location Delegate Methods
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        print("location updated")
        
        self.locationManager.stopUpdatingLocation()
        
       // lastLocation = locations.last!
        
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
//            guard let placeMarks = data as [CLPlacemark]! else {
//                return
//            }
            //let loc: CLPlacemark = placeMarks[0]
            //let addressDict : [NSString:NSObject] = loc.addressDictionary as! [NSString: NSObject]
            //let addrList = addressDict["FormattedAddressLines"] as! [String]
            
            //let address = addrList[0]
        })
        
    }
    
    

    
}

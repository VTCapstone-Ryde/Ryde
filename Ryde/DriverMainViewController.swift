//
//  DriverMainViewController.swift
//  Ryde
//
//  Created by Blake Duncan on 4/6/16.
//  Copyright © 2016 Jared Deiner. All rights reserved.
//

import UIKit
import CoreLocation
import FBSDKCoreKit

class DriverMainViewController: UIViewController, SlideMenuDelegate, CLLocationManagerDelegate   {
    
    //Global Variables
    var driverName = "Blake Duncan"
    var startTime = "10:00 p.m."
    var endTime = "1:00 a.m."
    var queueSize = 1
    var timeSlotID = 0
    var driverLat = 0.0
    var driverLng = 0.0
    var carMakeString = ""
    var carModelString = ""
    var carColorString = ""
    var carInfo = ""
    var phoneNumber = ""
    var email = ""
    var id = Int()
    //Stores list of riders that haven't been assigned a driver
    var nonActiveQueueDict = [NSDictionary]()
    //Stores the next rider
    var nextRideDictionary = NSDictionary()
    //Stores the queue
    var queueArray = NSArray()
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let semaphore = dispatch_semaphore_create(0)
    
    //Outlets
    @IBOutlet var startLabel: UILabel!
    @IBOutlet var endLabel: UILabel!
    @IBOutlet var queueLabel: UILabel!
    @IBOutlet var headerLabel: UILabel!
    @IBOutlet var acceptRideButton: UIButton!
    @IBOutlet var btnShowMenu: UIBarButtonItem!
    
    // Location Manager instance
    let locationManager = CLLocationManager()
    
    // Timer to schedule tasks
    var updateTimer: NSTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBarController?.tabBar.hidden = true
        
        //hide back button and add slide menu button
        self.navigationItem.setHidesBackButton(true, animated:true);
        
        //Get non active rides to get the queue size
        getNonActiveRides()
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        // schedules task for every n second
        updateTimer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector:  #selector(DriverMainViewController.updateQueueLabel), userInfo: nil, repeats: true)
        
        headerLabel.text = "Welcome!"
        
        // Grab data from FB
        let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields" : "id, name, email"])
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            
            // Set Name
            self.headerLabel.text = "Welcome " + (result.valueForKey("name") as? String)!.componentsSeparatedByString(" ")[0]
        })
        
        startLabel.text = "Start Time: " + startTime
        endLabel.text = "End Time: " + endTime
        let queueSize = String(nonActiveQueueDict.count)
        queueLabel.text = "Queue Size: " + queueSize
        let status = 1
        
        //updated driver status to true after logged in.
        self.put("http://\(self.appDelegate.baseURL)/Ryde/api/user/setDriverStatus/\(self.appDelegate.FBid)/\(status)")
        
        //Start getting driver coordinates
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    //Function called when view reappears
    override func viewWillAppear(animated: Bool) {
        //Get non active rides to get the queue size
        getNonActiveRides()
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        let queueSize = String(nonActiveQueueDict.count)
        queueLabel.text = "Queue Size: " + queueSize
        
        //Start getting driver coordinates again after view reappears
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        // schedules task for every n second
        if (updateTimer!.valid == false){
            updateTimer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector:  #selector(DriverMainViewController.updateQueueLabel), userInfo: nil, repeats: true)
        }
    }
    
    //Function called when view disappears
    override func viewWillDisappear(animated:Bool){
        //Stop the timer
        updateTimer?.invalidate()
        
        //Stop the location manager
        locationManager.stopUpdatingLocation()
    }
    
    //Sets the queue size label to the current queue size
    func updateQueueLabel(){
        //Api call to return the non active rides
        updateNonActiveRides()
        
        //Set the label
        let queueSize = String(self.nonActiveQueueDict.count)
        self.queueLabel.text = "Queue Size: " + queueSize
    }
    
    //Location manager function to get driver coordinates.
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        driverLat = locValue.latitude
        driverLng = locValue.longitude
    }
    
    //If queue size does not equal zero it gets the next rider and segues to the next view
    @IBAction func acceptRidePressed(sender: UIButton) {
        
        //Get non active rides to get the queue size
        getNonActiveRides()
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        //Make sure queue isn't empty before getting next ride
        if (nonActiveQueueDict.count != 0){
            
            //Stop updating driver location to conserve memory
            locationManager.stopUpdatingLocation()
            performSegueWithIdentifier("AcceptRide", sender: self)
        
        } else {    //no one in queue so you can't get next rider
            
            //Let driver know there is currently know one in the queue
            let alertController = UIAlertController(title: "Queue Empty",
                                                    message: "No rides have been requested.",
                                                    preferredStyle: UIAlertControllerStyle.Alert)
            
            // Create a UIAlertAction object and add it to the alert controller
            alertController.addAction(UIAlertAction(title: "Okay", style: .Default, handler: nil))
            
            // Present the alert controller by calling the presentViewController method
            presentViewController(alertController, animated: true, completion: nil)
        }
    
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Mark - Generic POST function that takes in a JSON dictinoary and the URL to be POSTed to
    // SOURCE: http://jamesonquave.com/blog/making-a-post-request-in-swift/
    // Put method is used to set the driver status
    func put(url : String) {
        
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "PUT"
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            //do nothing
        })
        
        task.resume()
    }
    
    // Mark - Retrieve the next rider's information from the server
    func getNextRide() {
        let url = NSURL(string: "http://\(self.appDelegate.baseURL)/Ryde/api/ride/startNextRideForTimeslot/\(self.timeSlotID)/\(self.appDelegate.FBid)")!
        
        // Creaste URL Request
        let request = NSMutableURLRequest(URL:url);
        
        // Set request HTTP method to GET. It could be POST as well
        request.HTTPMethod = "GET"
        
        // If needed you could add Authorization header value
        //request.addValue("Token token=884288bae150b9f2f68d8dc3a932071d", forHTTPHeaderField: "Authorization")
        
        // Execute HTTP Request
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            
            //print("Response: \(response)")
            let strData = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("Body: \(strData)")
            
            let json: NSDictionary?
            
            do {
                
                json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? NSDictionary
                
            } catch let dataError{
                
                // Did the JSONObjectWithData constructor return an error? If so, log the error to the console
                print(dataError)
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Error could not parse JSON: '\(jsonStr!)'")
                // return or throw?
                return
            }
            
            
            // The JSONObjectWithData constructor didn't return an error. But, we should still
            // check and make sure that json has a value using optional binding.
            if let parseJSON = json {
                
                self.nextRideDictionary = parseJSON as NSDictionary
                
            } else {
                // Woa, okay the json object was nil, something went worng. Maybe the server isn't running?
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Error could not parse JSON: \(jsonStr)")
            }
            dispatch_semaphore_signal(self.semaphore);
        })
        
        task.resume()
        
    }
    
    
    // Get the list of rides that have not been assigned a driver yet
    func getNonActiveRides() {
        let url = NSURL(string: "http://\(self.appDelegate.baseURL)/Ryde/api/ride/getNonActiveQueue/\(self.timeSlotID)")!
        
        // Creaste URL Request
        let request = NSMutableURLRequest(URL:url);
        
        // Set request HTTP method to GET. It could be POST as well
        request.HTTPMethod = "GET"
        
        // If needed you could add Authorization header value
        //request.addValue("Token token=884288bae150b9f2f68d8dc3a932071d", forHTTPHeaderField: "Authorization")
        
        // Execute HTTP Request
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            
            //print("Response: \(response)")
            let strData = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("Body: \(strData)")
            
            let json: [NSDictionary]?
            
            do {
                
                json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? [NSDictionary]
                
            } catch let dataError{
                
                // Did the JSONObjectWithData constructor return an error? If so, log the error to the console
                print(dataError)
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Error could not parse JSON: '\(jsonStr!)'")
                // return or throw?
                return
            }
            
            
            print("json : ===  \(json)")
            // The JSONObjectWithData constructor didn't return an error. But, we should still
            // check and make sure that json has a value using optional binding.
            if let parseJSON = json {
                
                self.nonActiveQueueDict = parseJSON as [NSDictionary]
                
            }
            else {
                // Woa, okay the json object was nil, something went worng. Maybe the server isn't running?
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Error could not parse JSON: \(jsonStr)")
            }
            dispatch_semaphore_signal(self.semaphore);
        })
        
        task.resume()
        
    }
    
    //Get the list of rides that have not been assigned a driver without using a semaphore
    func updateNonActiveRides() {
        
        let url = NSURL(string: "http://\(self.appDelegate.baseURL)/Ryde/api/ride/getNonActiveQueue/\(self.timeSlotID)")!
        
        // Creaste URL Request
        let request = NSMutableURLRequest(URL:url);
        
        // Set request HTTP method to GET. It could be POST as well
        request.HTTPMethod = "GET"
        
        // If needed you could add Authorization header value
        //request.addValue("Token token=884288bae150b9f2f68d8dc3a932071d", forHTTPHeaderField: "Authorization")
        
        // Execute HTTP Request
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            
            //print("Response: \(response)")
            //let strData = NSString(data: data!, encoding: NSUTF8StringEncoding)
            
            let json: [NSDictionary]?
            
            do {
                
                json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? [NSDictionary]
                
            } catch let dataError{
                
                // Did the JSONObjectWithData constructor return an error? If so, log the error to the console
                print(dataError)
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Error could not parse JSON: '\(jsonStr!)'")
                // return or throw?
                return
            }
            
            // The JSONObjectWithData constructor didn't return an error. But, we should still
            // check and make sure that json has a value using optional binding.
            if let parseJSON = json {
                
                self.nonActiveQueueDict = parseJSON as [NSDictionary]
                
            }
            else {
                // Woa, okay the json object was nil, something went worng. Maybe the server isn't running?
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Error could not parse JSON: \(jsonStr)")
            }
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
        
        if segue.identifier == "AcceptRide" {
            
            //Get non active rides to get the queue size
            getNextRide()
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            
            let userInfo = nextRideDictionary["riderUserId"] as! NSDictionary
            print(userInfo)
            
            // Obtain the object reference of the destination view controller
            let driverMapViewController: DriverMapViewController = segue.destinationViewController as! DriverMapViewController
            
            //Fields to be passed down stream
            driverMapViewController.riderName = userInfo["firstName"] as! String
            driverMapViewController.riderPhone = userInfo["phoneNumber"] as! String
            driverMapViewController.rideID = nextRideDictionary["id"] as! Int
            driverMapViewController.riderLat = nextRideDictionary["startLat"] as! Double
            driverMapViewController.riderLng = nextRideDictionary["startLon"] as! Double
            driverMapViewController.driverLat = driverLat
            driverMapViewController.driverLng = driverLng
            driverMapViewController.destLat = nextRideDictionary["endLat"] as! Double
            driverMapViewController.destLng = nextRideDictionary["endLon"] as! Double
        }
        else if segue.identifier == "EditProfileFromDriver" {
            // Do nothing
        }
    }
    
    /*
     --------------------------------
     MARK: - Slide out menu functions
     --------------------------------
     */
    
    // Function called when a slide menu option is pressed
    func slideMenuItemSelectedAtIndex(index: Int32) {
        let topViewController : UIViewController = self.navigationController!.topViewController!
        print("View Controller is : \(topViewController) \n", terminator: "")
        switch(index){
        case 0:
            //confirm Log out
            let alertController = UIAlertController(title: "Confirmation",
                                                    message: "Are you sure you would like to log out?",
                                                    preferredStyle: UIAlertControllerStyle.Alert)
            
            // Create a UIAlertAction object and add it to the alert controller
            alertController.addAction(UIAlertAction(title: "Confirm", style: .Default, handler: { (action: UIAlertAction!) in
                //TODO INVALIDATE TIMER.
                let status = 0
                //Update the driver status to False (logged out)
                self.put("http://\(self.appDelegate.baseURL)/Ryde/api/user/setDriverStatus/\(self.appDelegate.FBid)/\(status)")
                
                //Unhide tab bar and pop the current view from the navigation.
                self.tabBarController?.tabBar.hidden = false;
                self.navigationController?.popViewControllerAnimated(true)
                
            }))
            alertController.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
            
            // Present the alert controller by calling the presentViewController method
            presentViewController(alertController, animated: true, completion: nil)
            break
        case 1:
            performSegueWithIdentifier("EditProfileFromDriver", sender: self)
            break
        default:
            print("default\n", terminator: "")
        }
    }
    
    //Function called when the slide menu button is pressed to bring out slide menu
    @IBAction func onSlideMenuButtonPressed(sender: UIBarButtonItem) {
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
        
        let menuVC : DriverMenuViewController = self.storyboard!.instantiateViewControllerWithIdentifier("DriverMenuViewController") as! DriverMenuViewController
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
    
}

//
//  RequestRideViewController.swift
//  Ryde
//
//  Created by Franki Yeung on 4/7/16.
//  Copyright © 2016 Jared Deiner. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class RequestRideViewController: UIViewController {
    
    // Rider FB id
    var FBid = ""
    
    var queueNum: Int = 1
    
    // Rider Latitude
    var startLatitude: Double = 0
    
    // Rider Longitude
    var startLongitude: Double = 0
    
    // Destination Latitude
    var destLat: Double = 0
    
    // Destination Longitude
    var destLong: Double = 0
    
    // Timeslot ID
    var selectedTID:Int = 0
    
    // Timer to schedule tasks
    var updateTimer: NSTimer?
    
    // Status of ride
    var rideStatus: String = "nonActive"
    
    // Driver name
    var driverName:String = ""
    
    // Driver car info
    var carinfo: String = ""
    
    // Driver Phone Number
    var driverNumber:String = ""
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    // Label that shows the queue position of the rider
    @IBOutlet var queueLabel: UILabel!
    
    override func viewDidLoad() {
        // gets rid of back button in navigation
        let backButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: navigationController, action: nil)
        
        // Grab data from FB
        let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields" : "id, name, email"])
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            self.FBid = (result.valueForKey("id") as? String)!
        })
        
        // Set the title of the view
        self.title = "Ryde Requested"
        // Set the back navigation button to a blank action
        navigationItem.leftBarButtonItem = backButton
        
        super.viewDidLoad()
        
        // Gets queue position for the driver
        let postUrl = ("http://\(self.appDelegate.baseURL)/Ryde/api/ride/getposition/" + self.FBid + "/" + (String)(self.selectedTID))
        self.getQueuePos(postUrl)
        // Scheduler that calls updateQueue every 3 seconds
        updateTimer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "updateQueue", userInfo: nil, repeats: true)
    }
    
    /**
     *  Function for updating the queue position and checking if a driver has been assigned
     */
    func updateQueue(){
        // Create a new request to check the queueposition and ride status
        let postUrl = ("http://\(self.appDelegate.baseURL)/Ryde/api/ride/getposition/" + self.FBid + "/" + (String)(self.selectedTID))
        self.getQueuePos(postUrl)
        self.queueLabel.text = (String)(queueNum)
        // check if a driver has been assigned, active means the rider has a driver
        if rideStatus == "active"
        {
            // Stops the scheduler
            updateTimer?.invalidate()
            // Segue to new screen
            self.performSegueWithIdentifier("ShowCurrentRide", sender: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /**
     * Method to handle driver pressing cancel ride
     */
    @IBAction func cancelRideClicked(sender: UIButton) {
        //Calls on cancelRideAlert to create an alert for the user to confirm cancellation
        cancelRideAlert()
    }
    
    /*
     * Creates an alert box cancel ride is clicked
     */
    func cancelRideAlert()
    {
        let alert = UIAlertController(title: "Are you sure you want to cancel ride?", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        
        // Handles when user confirms cancellation of ride request
        alert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action: UIAlertAction!) in
            // Bring back tabBarController before segueing to home screen
            self.tabBarController?.tabBar.hidden = false
            
            // Post a request to the server to remove the user from the queue
            let postUrl = ("http://\(self.appDelegate.baseURL)/Ryde/api/ride/cancel/" + self.FBid)
            self.postCancel(postUrl)
            
            // Stops the task Scheduler
            self.updateTimer?.invalidate()
            // Pop back to rider's homepage
            self.navigationController?.popToRootViewControllerAnimated(true)
        }))
        
        // Closes the alert box
        alert.addAction(UIAlertAction(title: "No", style: .Default, handler: { (action: UIAlertAction!) in
            //do nothing
        }))
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // SOURCE: http://jamesonquave.com/blog/making-a-post-request-in-swift/
    // Post Function for Canceling a rider's request
    func postCancel(url : String) {
        
        // Create a new http request, type DELETE
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "DELETE"
        
        // attempt to send request
        let task = session.dataTaskWithRequest(request)
        {
            (data, response, error) in
            guard let _ = data else {
                print("error calling")
                return
            }
        }
        
        task.resume()
    }
    
    // Get Function for updating ride information
    func getQueuePos(url : String) {
        
        //let params: [String : AnyObject] = [:]
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "GET"
        
        let task = session.dataTaskWithRequest(request)
        {
            (data, response, error) in
            guard let _ = data else {
                print("error calling")
                return
            }
            let json: NSDictionary?
            
            // Attempt to read the body of the response as JSON
            do {
                json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? NSDictionary
            } catch let dataError{
                
                // Did the JSONObjectWithData constructor return an error? If so, log the error to the console
                print(dataError)
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Error could not parse JSON: '\(jsonStr)'")
                return
            }
            if let parseJSON = json {
                // Grab all ride information before segueing to CurrentRide view
                if let tempNum = parseJSON["position"] as? Int
                {
                    self.queueNum = tempNum
                }
                if let status = parseJSON["queueStatus"] as? String
                {
                    self.rideStatus = status
                    if status == "active"
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
     -------------------------
     MARK: - Prepare For Segue
     -------------------------
     */
    
    // This method is called by the system whenever you invoke the method performSegueWithIdentifier:sender:
    // You never call this method. It is invoked by the system.
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        
        if segue.identifier == "ShowCurrentRide" {
            
            // Obtain the object reference of the destination view controller
            let currentRiderViewController: CurrentRideViewController   = segue.destinationViewController as! CurrentRideViewController
            
            //Pass the data object to the destination view controller object
            currentRiderViewController.startLatitude = self.startLatitude
            currentRiderViewController.startLongitude = self.startLongitude
            currentRiderViewController.destLat = self.destLat
            currentRiderViewController.destLong = self.destLong
            currentRiderViewController.driverName = self.driverName
            currentRiderViewController.driverNumber = self.driverNumber
            currentRiderViewController.carinfo = self.carinfo
        }
    }
    
}

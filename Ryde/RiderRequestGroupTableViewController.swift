//
//  RiderRequestGroupTableViewController.swift
//  Ryde
//
//  Created by Franki Yeung on 4/7/16.
//  Copyright © 2016 Jared Deiner. All rights reserved.
//

import UIKit

import FBSDKCoreKit
import FBSDKLoginKit

class RiderRequestGroupTableViewController: UITableViewController {
    
    // List of Active Groups
    var activeGroups:NSArray = NSArray()
    
    // List of Active TADs
    var activeTADs:NSArray = NSArray()
    
    // Rider Location
    var address: String! = ""
    
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
    
    // Section Titles
    let section = ["Groups with Active Timeslots"]
    
    // Queue Position
    var queuePos:Int = 0
    
    // Dictionary of the user's current timeslots
    var groupDictionary = [NSDictionary]()
    
    // Information of the selected Group
    var selectedGroupInfo: NSDictionary?
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    // the ID of a selected timeslot
    var selectedTID:Int = 0
    
    // semaphore used to wait till all needed information is pulled before segueing
    let semaphore = dispatch_semaphore_create(0);
    
    override func viewDidLoad() {
        // Set the view title
        self.title = "Select Group"
        super.viewDidLoad()
        
        // Grab data from FB
        let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields" : "id, name, email"])
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            self.FBid = (result.valueForKey("id") as? String)!
            self.getUserTimeslots()
        })
        
        //Create a new navigation button that handings popping the current view controller
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Bordered, target: self, action: "back:")
        self.navigationItem.leftBarButtonItem = newBackButton;
        
        //Adds a navigation button to bring up alert to add TAD
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Join TAD", style: .Plain, target: self, action:#selector(self.joinTAD))
        self.view.backgroundColor = UIColor.init(patternImage: UIImage(named: "BackgroundMain")!)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        getUserTimeslots()
    }
    
    func back(sender: UIBarButtonItem) {
        self.tabBarController?.tabBar.hidden = false;
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    // Mark - Retrieve the user's active groups from the server
    func getUserTimeslots() {
        // The API call url
        let url = NSURL(string: (String)("http://\(self.appDelegate.baseURL)/Ryde/api/timeslotuser/gettads/" + FBid))
        
        // Create URL Request
        let request = NSMutableURLRequest(URL:url!);
        
        // Set request HTTP method to GET.
        request.HTTPMethod = "GET"
        
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
            print("responseString = \(responseString!)")
            
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
                // Okay, the parsedJSON is here, lets store its values into an array
                self.groupDictionary = parseJSON as [NSDictionary]
                //print(self.groupDictionary)
                dispatch_async(dispatch_get_main_queue(), {
                    self.tableView.reloadData()
                })
            }
            else {
                // Woa, okay the json object was nil, something went worng. Maybe the server isn't running?
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Error could not parse JSON: \(jsonStr!)")
            }
            
            
        })
        
        task.resume()
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.section[section]
    }
    
    // The number of sections that should be in the table
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.section.count
    }
    
    // The number of rows in the section
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupDictionary.count
    }
    
    // Populates the table with groups
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row = indexPath.row
        let cell = tableView.dequeueReusableCellWithIdentifier("rideGroupCell") as! RideGroupTableViewCell
        
        // Sets the title of the cell to the Group's name
        if let groupTitle = groupDictionary[row]["groupName"] as? String {
            cell.rowName.text = groupTitle
        }
        // Sets the number of drives to display the number of current drivers
        if let numDriver = groupDictionary[row]["numDrivers"] as? Int {
            cell.numDriverLabel.text = "Number of Drivers: " + (String)(numDriver)
        }
        // Sets the queue size to the number of people in the queue
        if let numQueue = groupDictionary[row]["queueSize"] as? Int {
            cell.numQueueLabel.text = "People in Queue: " + (String)(numQueue)
        }
        
        return cell
    }
    
    // A row selected, Attempt to post a ride to the server
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = indexPath.row
        
        // Gets the ID of the timeslot that is selected
        if let tid = groupDictionary[row]["tsId"] as? Int {
            self.selectedTID = tid
        }
        
        // Create a new JSON object to send to the server to post a ride
        let JSONObject: [String : AnyObject] = [
            "tsId" : self.selectedTID,          // The ID of the timeslot in the database
            "startLat" : self.startLatitude,    // The pickup latitude
            "startLon" : self.startLongitude,   // The pickup longitude
            "endLat"    : self.destLat,         // The drop off latitude
            "endLon"   : self.destLong          // The drop off longitude
        ]
        
        // Create a new url to post the request to
        let postUrl = ("http://\(self.appDelegate.baseURL)/Ryde/api/ride/request/" + self.FBid + "/" + (String)(self.selectedTID))
        // Calls the posting method and passes in the created JSON and the request URL
        self.postRequest(JSONObject, url: postUrl)
        
        // wait for the request to complete
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        performSegueWithIdentifier("ShowRequestRide", sender: nil)
    }
    
    
    /*
     -------------------------
     MARK: - TAD Functions
     -------------------------
     */
    
    /*
     Creates an alert box when join TAD is clicked.
     */
    func joinTAD()
    {
        // The new alert prompting rider to enter a passcode
        let alert = UIAlertController(title: "Enter TAD Passcode", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        
        // A textfield for the rider to input the passcode
        alert.addTextFieldWithConfigurationHandler({ (textField) -> Void in
            textField.placeholder = "Passcode"
        })
        
        // Action to check the passcode
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
            // Gets the inputted text
            let textField = alert.textFields![0] as UITextField
            // Calls post request generation method to check the passcode
            self.generateTADRequest(textField.text!)
        }))
        
        // Closes the alert box
        alert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: { (action: UIAlertAction!) in
            //do nothing
        }))
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // Sends passcode and user's facebook Token to server side to attempt to join TAD
    func generateTADRequest (passcode: String)
    {
        // Create a new JSON with the user's Facebook Token and entered passcode
        let JSONObject: [String : String] = [
            "fbTok" : self.FBid,
            "TADPasscode" : passcode
        ]
        
        // Post a request to check if the passcode is correct
        self.postTAD(JSONObject, url: ("http://\(self.appDelegate.baseURL)/Ryde/api/timeslotuser/jointad/" + FBid + "/" + passcode))
    }
    
    // Alert for showing the user has entered in an incorrect passcode
    func passcodeError()
    {
        let alert = UIAlertController(title: "Incorrect TAD Passcode", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        
        // Allows for user to dismiss the alert
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
            //do nothing
        }))
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // Mark - POST function that takes in a JSON dictinoary and the URL to be posted to
    /**
     * Post method for handing TAD joining
     */
    func postTAD(params : Dictionary<String, String>, url : String) {
        
         // Create a new HTTP request, type POST
         let request = NSMutableURLRequest(URL: NSURL(string: url)!)
         let session = NSURLSession.sharedSession()
         request.HTTPMethod = "POST"
        
        // Attempt to send the request
         let task = session.dataTaskWithRequest(request)
         {
            (data, response, error) in
            guard let _ = data else {   // Request failed
                print("error calling")
                return
            }
         
            let json: NSDictionary?
         
            // Attempt to read the body as a JSON object
            do {
                json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? NSDictionary
            } catch let dataError{
         
                // Did the JSONObjectWithData constructor return an error? If so, log the error to the console
                print(dataError)
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Error could not parse JSON: '\(jsonStr)'")
                return
            }
         
            // The JSONObjectWithData constructor didn't return an error. But, we should still
            // check and make sure that json has a value using optional binding.
            if let parseJSON = json {
                // Grab the field that indicates whether the user has joined
                if let succ = parseJSON["joinTADSuccess"] as? Bool
                {
                    // Check if the user has join, repopulate tables if true, display error if false
                    if (succ == true)
                    {
                        self.getUserTimeslots()
                    }
                    else
                    {
                        self.passcodeError()
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
    
    
    // SOURCE: http://jamesonquave.com/blog/making-a-post-request-in-swift/
    // Post Function for request
    func postRequest(params : Dictionary<String, AnyObject>, url : String) {
        
        // Create a new http request, type POST
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        
        // Attempt to set the request body to the passed in dictionary object
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
                json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? NSDictionary
            } catch let dataError{
                
                // Did the JSONObjectWithData constructor return an error? If so, log the error to the console
                print(dataError)
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Error could not parse JSON: '\(jsonStr)'")
                return
            }
            
            // The JSONObjectWithData constructor didn't return an error. But, we should still
            // check and make sure that json has a value using optional binding.
            if let parseJSON = json {
                // gets the position of the rider in the queue
                if let queueTemp = parseJSON["position"] as? Int
                {
                    self.queuePos = queueTemp
                    // tells the sempahore to continue so the view can segue
                    dispatch_semaphore_signal(self.semaphore);
                }
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
     MARK: - Prepare For Segue
     -------------------------
     */
    
    // This method is called by the system whenever you invoke the method performSegueWithIdentifier:sender:
    // You never call this method. It is invoked by the system.
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        
        if segue.identifier == "ShowRequestRide" {
            
            // Obtain the object reference of the destination view controller
            let requestRideViewController: RequestRideViewController = segue.destinationViewController as! RequestRideViewController
            
            //Pass the data object to the destination view controller object
            requestRideViewController.queueNum = self.queuePos
            requestRideViewController.startLatitude = self.startLatitude
            requestRideViewController.startLongitude = self.startLongitude
            requestRideViewController.destLat = self.destLat
            requestRideViewController.destLong = self.destLong
            requestRideViewController.selectedTID = self.selectedTID
        }
    }
    
}
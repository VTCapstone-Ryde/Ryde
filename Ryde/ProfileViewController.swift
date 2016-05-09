//
//  ProfileViewController.swift
//  Ryde
//
//  Created by Andrew Mogg on 4/2/16.
//  Copyright © 2016 Jared Deiner. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class ProfileViewController: UIViewController, FBSDKLoginButtonDelegate  {

    //Outlets
    @IBOutlet var editButton: UIButton!
    @IBOutlet var profileImage: UIImageView!
    @IBOutlet var profileName: UILabel!
    @IBOutlet var cellNumberTextField: UILabel!
    @IBOutlet var carInfoTextField: UILabel!
    @IBOutlet var rydesGivenLabel: UILabel!
    @IBOutlet var profileScrollView: UIScrollView!
    
    //Global Strings
    var carMakeString = ""
    @IBOutlet var rydesTakenLabel: UILabel!
    var carModelString = ""
    var carColorString = ""
    var carInfo = ""
    var phoneNumber = ""
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var id = Int()
    let semaphore = dispatch_semaphore_create(0);
    var FBid = ""
    var token = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Make the image a circle
        profileImage.layer.borderWidth = 1
        //profileImage.layer.masksToBounds = false
        profileImage.layer.borderColor = UIColor.clearColor().CGColor
        profileImage.layer.cornerRadius = profileImage.frame.height/2
        profileImage.clipsToBounds = true
        profileName.text! = ""
        
        //Set FB button to bottom of screen
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        let screenWidth = screenSize.width * 0.5
        let labelAbove = carInfoTextField.frame.origin.y + 350
        let a = CGPointMake(screenWidth, labelAbove)
        let fbButton = FBSDKLoginButton()
        fbButton.center = self.view.convertPoint(a, fromCoordinateSpace: self.view)
        fbButton.delegate = self
        self.profileScrollView.addSubview(fbButton)
        
        
        //Set the ryde counters
        rydesGivenLabel.text! = String(appDelegate.rydesGivenCount)
        rydesTakenLabel.text! = String(appDelegate.rydesTakenCount)
        
        //Get the user data
        getUserData(FBSDKAccessToken.currentAccessToken().userID)
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

        
        // Grab data from FB
        let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields" : "id, name, email"])
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            
            // Set Name
            self.profileName.text = result.valueForKey("name") as? String
            
            self.FBid = (result.valueForKey("id") as? String)!
            
            
            let url = NSURL(string: "https://graph.facebook.com/\(self.FBid)/picture?type=large&return_ssl_resources=1")
            // Set Image
            self.profileImage.image = UIImage(data: NSData(contentsOfURL: url!)!)
        })
        
    }
    
    // Mark - Retrieve the users groups from the server
    func getUserData(token: String) {
        print("RETRIEVE USER DATA")
        
        let url = NSURL(string: "http://\(self.appDelegate.baseURL)/Ryde/api/user/findByToken/\(token)")
        print(url)
        
        // Creaste URL Request
        let request = NSMutableURLRequest(URL:url!);
        
        // Set request HTTP method to GET. It could be POST as well
        request.HTTPMethod = "GET"
        
        // If needed you could add Authorization header value
        //request.addValue("Token token=884288bae150b9f2f68d8dc3a932071d", forHTTPHeaderField: "Authorization")
        
        // Execute HTTP Request
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            
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
                //Check if the user has car data
                if parseJSON["carMake"] != nil {
                    self.carMakeString = (parseJSON["carMake"] as? String)!
                    self.carModelString = (parseJSON["carModel"] as? String)!
                    self.carColorString = (parseJSON["carColor"] as? String)!
                    self.carInfo = "\(self.carMakeString) \(self.carModelString) \(self.carColorString)"

                }
                
                //This id should always be found
                self.id = (parseJSON["id"] as? Int)!
                
                //Set the labels and signal semaphore
                self.cellNumberTextField.text! = (parseJSON["phoneNumber"] as? String)!
                
                //Check if they have car data
                if (self.carInfo == "  " || self.carInfo.isEmpty)
                {
                    self.carInfoTextField.text! = "No Info Entered"
                }
                else{
                    self.carInfoTextField.text! = self.carInfo
                }
                
                dispatch_semaphore_signal(self.semaphore);
                
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
    * Segue to edit the profile
    */
    @IBAction func editProfileButtonTapped(sender: UIButton) {
        performSegueWithIdentifier("editProfile", sender: self)
    }
    
    
    //Update the userdata with the newly entered data from the Edit Profile
    @IBAction func unwindToProfile(segue: UIStoryboardSegue)
    {
        if segue.identifier == "unwindToProfile" {
            let controller: EditProfileViewController = segue.sourceViewController as! EditProfileViewController
            
            carMakeString = controller.carMakeTextField.text!
            carModelString = controller.carModelTextField.text!
            carColorString = controller.carColorTextField.text!
            self.carInfo = "\(self.carMakeString) \(self.carModelString) \(self.carColorString)"
            
            //Check if they have car data
            if (self.carInfo == "  " || self.carInfo.isEmpty)
            {
                self.carInfoTextField.text! = "No Info Entered"
            }
            else{
                self.carInfoTextField.text! = self.carInfo
            }
            
            let name = profileName.text
            
            let fullNameArr = name?.componentsSeparatedByString(" ")
            
            let JSONObject: [String : AnyObject] = [
                
                "lastName"  : fullNameArr![(fullNameArr?.count)!-1],
                "firstName" : fullNameArr![0],
                "fbTok"     : FBSDKAccessToken.currentAccessToken().userID,
                "id"        : id,
                "phoneNumber" : cellNumberTextField.text!,
                "carMake"   : carMakeString,
                "carModel"  : carModelString,
                "carColor"  : carColorString
            ]
            
            // Sends a POST to the specified URL with the JSON conent
            self.put(JSONObject, url: "http://\(self.appDelegate.baseURL)/Ryde/api/user/\(id)")
        }
    }
    /*
     -------------------------
     MARK: - Prepare for Segue
     -------------------------
     
     This method is called by the system whenever you invoke the method performSegueWithIdentifier:sender:
     You never call this method. It is invoked by the system.
     */
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        
        if segue.identifier == "editProfile" {
            
            // Obtain the object reference of the destination view controller
            let editProfileViewController: EditProfileViewController = segue.destinationViewController as! EditProfileViewController
            
            // Pass the User data to the EditProfile
            editProfileViewController.cellNumber = cellNumberTextField.text!
            editProfileViewController.id = id
            editProfileViewController.carMake = carMakeString
            editProfileViewController.carModel = carModelString
            editProfileViewController.carColor = carColorString
        }
    }

    // MARK: - Facebook Login
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        
        print("This should never be called")
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        
        print("User logged out")
        
        let loginManager = FBSDKLoginManager()
        loginManager.logOut() // this is an instance function
        
        performSegueWithIdentifier("logOut", sender: self)
    }
    
    
    
    // Put the new user data to the server
    func put(params : Dictionary<String, AnyObject>, url : String) {
        
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "PUT"
        
        
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

}

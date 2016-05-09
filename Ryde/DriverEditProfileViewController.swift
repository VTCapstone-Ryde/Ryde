//
//  EditProfileViewController.swift
//  Ryde
//
//  Created by Andrew Mogg on 4/9/16.
//  Copyright © 2016 Jared Deiner. All rights reserved.
//

import UIKit
import FBSDKCoreKit

class DriverEditProfileViewController: UIViewController {
    
    //Outlets
    @IBOutlet var profileImage: UIImageView!
    @IBOutlet var profileName: UILabel!
    @IBOutlet var cellNumberTextField: UITextField!
    @IBOutlet var carMakeTextField: UITextField!
    @IBOutlet var carModelTextField: UITextField!
    @IBOutlet var carColorTextField: UITextField!
    
    //Global values
    var cellNumber = ""
    var FBid = ""
    var id = Int()
    let semaphore = dispatch_semaphore_create(0)
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var cameFromDriverView = false

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileImage.layer.borderWidth = 1
        //profileImage.layer.masksToBounds = false
        profileImage.layer.borderColor = UIColor.clearColor().CGColor
        profileImage.layer.cornerRadius = profileImage.frame.height/2
        profileImage.clipsToBounds = true
        profileName.text! = ""

        
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
        print("id = \(id)")
        
    }
    
    //Api call to get the user data
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
            
            //print("Response: \(response)")
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
                    self.carMakeTextField.text! = (parseJSON["carMake"] as? String)!
                    self.carModelTextField.text! = (parseJSON["carModel"] as? String)!
                    self.carColorTextField.text! = (parseJSON["carColor"] as? String)!
                    
                }
                
                //This id should always be found
                self.id = (parseJSON["id"] as? Int)!
                
                //Set the labels and signal semaphore
                self.cellNumberTextField.text! = (parseJSON["phoneNumber"] as? String)!
                
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

    //Saves the updated values for the profile
    @IBAction func saveButtonTapped(sender: UIButton) {
        let name = profileName.text
        
        let fullNameArr = name?.componentsSeparatedByString(" ")
        
        let JSONObject: [String : AnyObject] = [
            
            "lastName"  : fullNameArr![(fullNameArr?.count)!-1],
            "firstName" : fullNameArr![0],
            "fbTok"     : FBSDKAccessToken.currentAccessToken().userID,
            "id"        : id,
            "phoneNumber" : cellNumberTextField.text!,
            "carMake"   : carMakeTextField.text!,
            "carModel"  : carModelTextField.text!,
            "carColor"  : carColorTextField.text!
        ]
        
        // Sends a POST to the specified URL with the JSON conent
        self.put(JSONObject, url: "http://\(self.appDelegate.baseURL)/Ryde/api/user/\(id)")
        //self.dismissViewControllerAnimated(true, completion: nil);
        //
        //self.navigationController?.popViewControllerAnimated(true)
        performSegueWithIdentifier("unwindToMenu", sender: self)
        
    }
    
    
    // Mark - Generic POST function that takes in a JSON dictinoary and the URL to be POSTed to
    
    
    // SOURCE: http://jamesonquave.com/blog/making-a-post-request-in-swift/
    // Api call to save the updated values to the database
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
    
    
    // Mark - Get Rid of Keyboard when Done Editing
    
    /**
     * Called when 'return' key pressed. return NO to ignore.
     */
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}

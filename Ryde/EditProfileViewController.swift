//
//  EditProfileViewController.swift
//  Ryde
//
//  Created by Andrew Mogg on 4/9/16.
//  Copyright © 2016 Jared Deiner. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class EditProfileViewController: UIViewController {
    
    //Outlets
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var profileImage: UIImageView!
    @IBOutlet var profileName: UILabel!
    @IBOutlet var cellNumberTextField: UITextField!
    @IBOutlet var carMakeTextField: UITextField!
    @IBOutlet var carModelTextField: UITextField!
    @IBOutlet var carColorTextField: UITextField!
    
     // Mark - Fields
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var cellNumber = ""
    var carMake = ""
    var carModel = ""
    var carColor = ""
    var FBid = ""
    var id = Int()
    let loginManager = FBSDKLoginManager()


    override func viewDidLoad() {
        super.viewDidLoad()
                
        //Make the image a circle
        profileImage.layer.borderWidth = 1
        profileImage.layer.borderColor = UIColor.clearColor().CGColor
        profileImage.layer.cornerRadius = profileImage.frame.height/2
        profileImage.clipsToBounds = true
        
        //Set the text fields to the users data that is passed from the ProfileViewController
        cellNumberTextField.text! = cellNumber
        carMakeTextField.text! = carMake
        carModelTextField.text! = carModel
        carColorTextField.text! = carColor
        

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
    
    /*
    * Action for when the user taps the delete button. It should ask the user for confirmation. If yes, it should
    * delete the user from the DB and take the user back to the splash page.
    */
    @IBAction func deleteButtonTapped(sender: UIButton) {
        // Sends a POST to the specified URL with the JSON conent
        
        
        //Confirm Delete Account
        let alertController = UIAlertController(title: "Confirmation",
                                                message: "Are you sure you would like to delete your account?",
                                                preferredStyle: UIAlertControllerStyle.Alert)
        
        // Create a UIAlertAction object and add it to the alert controller
        alertController.addAction(UIAlertAction(title: "Confirm", style: .Default, handler: { (action: UIAlertAction!) in
            
            //Delete account from the server and logout of Facebook
             self.deleteUser("http://\(self.appDelegate.baseURL)/Ryde/api/user/\(self.id)")
             self.loginManager.logOut()
             self.performSegueWithIdentifier("Delete", sender: self)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
        
        // Present the alert controller by calling the presentViewController method
        presentViewController(alertController, animated: true, completion: nil)
        
    }
    
    //Delete the user from the server
    func deleteUser(url: String){
        
        print("DELETING User")
        
        print(url)
        
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "DELETE"
        
        let task = session.dataTaskWithRequest(request, completionHandler: {(data, response, error) in
            guard let _ = data
                else {
                    print("error calling DELETE on group")
                    return
            }
        })
        task.resume()
    }

    //Save The New Data to the Server
    @IBAction func saveButtonTapped(sender: UIButton) {
        if cellNumberTextField.text?.characters.count < 13 {
            
            let alertController = UIAlertController(title: "Invalid Entry",
                                                    message: "You did not enter a valid telephone number.",
                                                    preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
            
            // Present the alert controller by calling the presentViewController method
            presentViewController(alertController, animated: true, completion: nil)
            
            return
        }
        
        performSegueWithIdentifier("unwindToProfile", sender: self)
        
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
    
    /**
    * Ensures that the inputted phone number is formatted correctly
    */
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool
    {
        
        if (textField == cellNumberTextField)
        {
            let newString = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
            let components = newString.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet)
            
            let decimalString = components.joinWithSeparator("") as NSString
            let length = decimalString.length
            let hasLeadingOne = length > 0 && decimalString.characterAtIndex(0) == (1 as unichar)
            
            if length == 0 || (length > 10 && !hasLeadingOne) || length > 11
            {
                let newLength = (textField.text! as NSString).length + (string as NSString).length - range.length as Int
                
                return (newLength > 10) ? false : true
            }
            var index = 0 as Int
            let formattedString = NSMutableString()
            
            if hasLeadingOne
            {
                formattedString.appendString("1 ")
                index += 1
            }
            if (length - index) > 3
            {
                let areaCode = decimalString.substringWithRange(NSMakeRange(index, 3))
                formattedString.appendFormat("(%@)", areaCode)
                index += 3
            }
            if length - index > 3
            {
                let prefix = decimalString.substringWithRange(NSMakeRange(index, 3))
                formattedString.appendFormat("%@-", prefix)
                index += 3
            }
            
            let remainder = decimalString.substringFromIndex(index)
            formattedString.appendString(remainder)
            textField.text = formattedString as String
            return false
        }
        else
        {
            return true
        }
    }
}

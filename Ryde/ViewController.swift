//
//  ViewController.swift
//  Ryde
//
//  Created by Joe Fletcher on 3/29/16.
//  Copyright © 2016 Jared Deiner. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class ViewController: UIViewController, FBSDKLoginButtonDelegate {
    
    @IBOutlet var label: UILabel!
    
    @IBOutlet var loginButton: FBSDKLoginButton!
    
    var baseURL = "172.30.173.109:8080"//"jupiter.cs.vt.edu"

    var responseString = ""
    
    let semaphore = dispatch_semaphore_create(0);
    
    override func viewDidLoad() {
        

        loginButton.readPermissions = ["public_profile", "email", "user_friends"]
        loginButton.delegate = self
        
        label.textAlignment = NSTextAlignment.Center
 
    }
    
    override func viewDidAppear(animated: Bool) {
        
        print("Check if logged in")
        
        checkIfLoggedIn()
    }
    
    func checkIfLoggedIn() {
        
        
        if (FBSDKAccessToken.currentAccessToken() == nil) {
            print("No one has logged in")
        }
        else {
            print("Logged in")
            
            checkIfAccountCreated()
            
            //dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            
            print(self.responseString)
            
            if (self.responseString == "true") {
                
                print("home")
                
                performSegueWithIdentifier("Home", sender: self)
                
            }
            else {
                
                print("create")
                
                
                performSegueWithIdentifier("createAccount", sender: self)
                
            }
        }
    }
    
    // Mark - Check if this user already has an account. If so, bypass this create account page.
    
    func checkIfAccountCreated() {
        
        print("CHECK IF ACCOUNT CREATED")
        
        let url = NSURL(string: "http://\(self.baseURL)/Ryde/api/user/validateToken/\(FBSDKAccessToken.currentAccessToken().userID)")
        
        // Creaste URL Request
        let request = NSMutableURLRequest(URL:url!);

        // Set request HTTP method to GET. It could be POST as well
        request.HTTPMethod = "GET"
        
        // If needed you could add Authorization header value
        //request.addValue("Token token=884288bae150b9f2f68d8dc3a932071d", forHTTPHeaderField: "Authorization")
        
        // Excute HTTP Request
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            
            // Check for error
            if error != nil
            {
                print("error=\(error)")
                return
            }
            
            // Print out response string
            let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding) as! String
            
            print(responseString)
            
            // If Response is TRUE => User exists
            self.responseString = responseString
           
            //dispatch_semaphore_signal(self.semaphore);
            
        }
        
        task.resume()
    }
    
    
    // MARK: - Facebook Login
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        
        if (error == nil) {
            print("Login complete")
            
            checkIfAccountCreated()
            
        }
        else {
            print(error.localizedDescription)
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        
        print("User logged out")
        
    }
    
}

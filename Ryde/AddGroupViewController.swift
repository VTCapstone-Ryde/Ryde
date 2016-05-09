//
//  AddGroupViewController.swift
//  Ryde
//
//  Created by Cody Cummings on 4/11/16.
//  Copyright © 2016 Jared Deiner. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class AddGroupViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate {

    
    // MARK: - Fields
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

    var currentUser: NSDictionary?
    
    //results returned from our query to the server
    var searchBarResults = [NSDictionary]()
    
    //group of members that we have selected to add to the group
    var selectedGroupMembers = [String]()
    
    //our new group being created
    var newGroup = NSDictionary()
    
    //gets a reference to the search bar
    var activeSearchBar: UISearchBar?
    
    // MARK: - IBOutlets
    
    @IBOutlet var scrollView: UIScrollView!

    @IBOutlet var groupNameTextField: UITextField!
    
    @IBOutlet var groupDescriptionTextView: UITextView!
    
    @IBOutlet var groupMemberTableView: UITableView!
    
    @IBOutlet var groupMemberSearchBar: UISearchBar!
    
    var searchActive : Bool = false
    
    // MARK: - IBActions
    
    //adds the group to the database if information is properly filled out
    @IBAction func saveGroup(sender: UIBarButtonItem) {
        
        if (groupNameTextField.text == "") {
            let alertController = UIAlertController(title: "Blank Group Name", message: "Please enter a name for the group!", preferredStyle: UIAlertControllerStyle.Alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: { (action:UIAlertAction) -> Void in
            })
            alertController.addAction(okAction)
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        else if (groupDescriptionTextView.text == "") {
            let alertController = UIAlertController(title: "Blank Description", message: "Please enter a description for the group!", preferredStyle: UIAlertControllerStyle.Alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: { (action:UIAlertAction) -> Void in
            })
            alertController.addAction(okAction)
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        else {
            
            let description = groupDescriptionTextView.text
            let title = groupNameTextField.text
            
            //packages up JSON object and sends it to the server
            let JSONGroupObject: [String : String] = [
                
                "description":  description!,
                "directoryPath": "none",
                "title": title!
            ]
            
            // Sends a POST to the specified URL with the JSON conent
            self.postGroup(JSONGroupObject, url: "http://\(self.appDelegate.baseURL)/Ryde/api/group/createWithReturn")
            
        }
    }
    
    // MARK: - Server interactions
    
    
    //Posts the group to the server
    func postGroup(params : NSDictionary, url : String) {
        
        print("POSTING TO GROUP")
        
        print(url)
        
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
            
            let json: NSDictionary?
            
            do {
                json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as? NSDictionary
            } catch let dataError{
                
                // Did the JSONObjectWithData constructor return an error? If so, log the error to the console
                print("error: \(dataError)")
                return
            }
            
            // The JSONObjectWithData constructor didn't return an error. But, we should still
            // check and make sure that json has a value using optional binding.
            if let parseJSON = json {
                
                print("parseJSON: \(parseJSON)")
                // Okay, the parsedJSON is here, lets get back the group and update the groupuser table
                if let id = parseJSON["id"] {
                    let groupID = String(id)
                    
                    //go through all of the selected members and add them to the group
                    for member in self.selectedGroupMembers {
                        let groupDict = [ "id" : groupID ]
                        let memberDict = [ "id" : member ]
                        
                        let JSONGroupUserObject = [
                            "admin": "0",
                            "groupId": groupDict,
                            "userId": memberDict
                        ]

                        self.postGroupUser(JSONGroupUserObject, url: "http://\(self.appDelegate.baseURL)/Ryde/api/groupuser")
                    }
                    
                    //add the current user to the group as an admin
                    let currentID = String(self.currentUser!["id"]!)
                    
                    let groupDict = [ "id" : groupID ]
                    let memberDict = [ "id" : currentID ]
                    
                    let JSONGroupUserObject = [
                        
                        "admin": "1",
                        "groupId": groupDict,
                        "userId": memberDict
                    ]
                    
                    self.postGroupUser(JSONGroupUserObject, url: "http://\(self.appDelegate.baseURL)/Ryde/api/groupuser")
                    
                    let title = parseJSON["title"]
                    
                    //once we are done adding all of the group users we let the user know the group is created
                    dispatch_async(dispatch_get_main_queue(), {
                        let alertController = UIAlertController(title: "Group Successfully Created!", message: "Your group \"\(title!)\" has been created!", preferredStyle: UIAlertControllerStyle.Alert)
                        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: { (action:UIAlertAction) -> Void in
                            self.performSegueWithIdentifier("UnwindToGroups-Add", sender: nil)
                        })
                        alertController.addAction(okAction)
                        self.presentViewController(alertController, animated: true, completion: nil)
                    })
                }
            }
        })
        
        task.resume()
    }

    //Adds a member to the groupuser table, making them a member of the group
    func postGroupUser(params : NSDictionary, url : String) {
        
        print("POSTING TO GROUPUSER")
        
        print(url)
        
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
            
            let json: NSDictionary?
            
            do {
                json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as? NSDictionary
            } catch let dataError{
                
                // Did the JSONObjectWithData constructor return an error? If so, log the error to the console
                print("error: \(dataError)")
                return
            }
            
            // The JSONObjectWithData constructor didn't return an error. But, we should still
            // check and make sure that json has a value using optional binding.
            if let parseJSON = json {
                // Okay, the parsedJSON is here, let's see what we sent
                print("parseJSON \(parseJSON)")
            }
        })
        
        task.resume()
    }
    

    //MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Designate self as a subscriber to Keyboard Notifications
        registerForKeyboardNotifications()
        
        //print permissions, such as public_profile
        print(FBSDKAccessToken.currentAccessToken().permissions)
        
        // Grab data from FB
        let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields" : "friends"])
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            
            // Set list of friends
            let fbFriends = result.valueForKey("friends")
            print(fbFriends)
        })
        
        selectedGroupMembers.removeAll()
        
        groupMemberTableView.tableFooterView = UIView()

    }


    //MARK: - Textfield delegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if (textField == groupNameTextField) {
            groupNameTextField.resignFirstResponder()
            groupDescriptionTextView.becomeFirstResponder()
            return false
        }
        return true
    }
    
    /*
     * Taken from Keyboard App, developed by Osman Balci
     ---------------------------------------------
     MARK: - Register and Unregister Notifications
     ---------------------------------------------
     */
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.registerForKeyboardNotifications()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
//    /*
//  Taken from Keyboard App, developed by Osman Balci
//     ---------------------------------------
//     MARK: - Handling Keyboard Notifications
//     ---------------------------------------
//     */
//    
    // This method is called in viewDidLoad() to register self for keyboard notifications
    func registerForKeyboardNotifications() {
        
        // "An NSNotificationCenter object (or simply, notification center) provides a
        // mechanism for broadcasting information within a program." [Apple]
        let notificationCenter = NSNotificationCenter.defaultCenter()
        
        notificationCenter.addObserver(self,
                                       selector:   #selector(AddGroupViewController.keyboardWillShow(_:)),    // <-- Call this method upon Keyboard Will SHOW Notification
            name:       UIKeyboardWillShowNotification,
            object:     nil)
        
        notificationCenter.addObserver(self,
                                       selector:   #selector(AddGroupViewController.keyboardWillHide(_:)),    //  <-- Call this method upon Keyboard Will HIDE Notification
            name:       UIKeyboardWillHideNotification,
            object:     nil)
    }
    // Taken from Keyboard App, developed by Osman Balci
    // This method is called upon Keyboard Will SHOW Notification
    func keyboardWillShow(sender: NSNotification) {
        
        if (activeSearchBar != nil) {
            // "userInfo, the user information dictionary stores any additional
            // objects that objects receiving the notification might use." [Apple]
            let info: NSDictionary = sender.userInfo!
            
            /*
             Key     = UIKeyboardFrameBeginUserInfoKey
             Value   = an NSValue object containing a CGRect that identifies the start frame of the keyboard in screen coordinates.
             */
            let value: NSValue = info.valueForKey(UIKeyboardFrameBeginUserInfoKey) as! NSValue
            
            // Obtain the size of the keyboard
            let keyboardSize: CGSize = value.CGRectValue().size
            
            // Create Edge Insets for the view.
            let contentInsets: UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height, 0.0)
            
            // Set the distance that the content view is inset from the enclosing scroll view.
            scrollView.contentInset = contentInsets
            
            // Set the distance the scroll indicators are inset from the edge of the scroll view.
            scrollView.scrollIndicatorInsets = contentInsets
            
            //-----------------------------------------------------------------------------------
            // Scroll the search bar up so it is at the top of the view
            //-----------------------------------------------------------------------------------
            
            // Obtain the frame size of the View
            var selfViewFrameSize: CGRect = self.view.frame
            
            // Subtract the keyboard height from the self's view height
            // and set it as the new height of the self's view
            selfViewFrameSize.size.height -= keyboardSize.height
            
            let searchBarRect = groupMemberSearchBar.frame
            
            let topLayoutGuideBottom = self.topLayoutGuide.length
            
            let offset = CGPointMake(0, searchBarRect.origin.y - topLayoutGuideBottom)
            
            scrollView.contentOffset = offset
        }
    }
    
    //  Taken from Keyboard App, developed by Osman Balci
    // This method is called upon Keyboard Will HIDE Notification
    func keyboardWillHide(sender: NSNotification) {
        
        // Set contentInsets to top=0, left=0, bottom=0, and right=0
        let contentInsets: UIEdgeInsets = UIEdgeInsetsZero
        
        // Set scrollView's contentInsets to top=0, left=0, bottom=0, and right=0
        scrollView.contentInset = contentInsets
        
        // Set scrollView's scrollIndicatorInsets to top=0, left=0, bottom=0, and right=0
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
    // MARK: - Search Bar Delegates
    
    //Delegates to handle what happens during each search bar event
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchActive = true;
        activeSearchBar = searchBar
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchActive = false;
        activeSearchBar = nil
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
        searchBar.resignFirstResponder()
    }
    
    //each time the text is changed, query the server for the list of users containing the searched text
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        //Clear out all old search results
        searchBarResults.removeAll()
        
        if (searchText != "") {
            print("RETRIEVE USERS WITH NAME IN SEARCH BAR")
            
            let searchTextNoSpaces = searchText.stringByReplacingOccurrencesOfString(" ", withString: "+")
            
            let url = NSURL(string: "http://\(self.appDelegate.baseURL)/Ryde/api/user/name/\(searchTextNoSpaces)")
            
            print(url)
            
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
                    self.searchBarResults = parseJSON as [NSDictionary]
                    
                    for (index, result) in self.searchBarResults.enumerate() {
                        let resultID = String(result["id"]!)
                        let currentID = String(self.currentUser!["id"]!)
                        
                        if currentID == resultID {
                            self.searchBarResults.removeAtIndex(index)
                            break
                        }
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        self.groupMemberTableView.reloadData()
                    })
                }
                else {
                    let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                    print("Error could not parse JSON: \(jsonStr!)")
                }
                
                
            })
            
            task.resume()

        }
        else {
            groupMemberTableView.reloadData()
        }
    }
    
    // MARK: - TableView Delegates
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchBarResults.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
       
        let row = indexPath.row
        
        let cell = groupMemberTableView.dequeueReusableCellWithIdentifier("memberCell") as UITableViewCell!
        
        cell.selectionStyle = .None
        
        let memberRow = searchBarResults[row]
        
        //Set the rows textlabel to the full name of the user found
        if let memberFirstName = memberRow["firstName"] as? String {
            if let memberLastName = memberRow["lastName"] as? String {
                cell.textLabel!.text = memberFirstName + " " + memberLastName
                cell.textLabel?.textColor = UIColor.whiteColor()
            }
        }
        
        let memberID = String(memberRow["id"]!)
        if let _ = selectedGroupMembers.indexOf(memberID) {
            //remove the item at the found index
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryType.None
        }
        

        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = indexPath.row
        
        let cell = groupMemberTableView.dequeueReusableCellWithIdentifier("memberCell") as UITableViewCell!
        
        let memberRow = searchBarResults[row]
        let memberID = String(memberRow["id"]!)
        
        //uncheck or check a user if they are selected to join a group
        if let foundIndex = selectedGroupMembers.indexOf(memberID) {
            //remove the item at the found index
            cell.accessoryType = UITableViewCellAccessoryType.None
            selectedGroupMembers.removeAtIndex(foundIndex)
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            selectedGroupMembers.append(memberID)
        }

        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
    }

}

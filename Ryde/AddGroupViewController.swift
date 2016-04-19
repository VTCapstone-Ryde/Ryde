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

class AddGroupViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {

    
    // Mark - Fields
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

    var currentUser: NSDictionary?
    
    var searchBarResults = [NSDictionary]()
    
    var selectedGroupMembers = [String]()
    
    var newGroup = NSDictionary()
    
    // Mark - IBOutlets
    
    @IBOutlet var groupNameTextField: UITextField!
    
    @IBOutlet var groupDescriptionTextView: UITextView!
    
    @IBOutlet var groupMemberTableView: UITableView!
    
    @IBOutlet var groupMemberSearchBar: UISearchBar!
    
    var searchActive : Bool = false
    
    // Mark - IBActions
    
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
            
            let JSONGroupObject: [String : String] = [
                
                "description":  description!,
                "directoryPath": "none",
                "title": title!
            ]
            
            // Sends a POST to the specified URL with the JSON conent
            self.postGroup(JSONGroupObject, url: "http://\(self.appDelegate.baseURL)/Ryde/api/group")
            
        }
    }
    
    // Mark - Generic POST function that takes in a JSON dictinoary and the URL to be POSTed to
    
    
    // SOURCE: http://jamesonquave.com/blog/making-a-post-request-in-swift/
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

                        print(JSONGroupUserObject)
                        self.postGroupUser(JSONGroupUserObject, url: "http://\(self.appDelegate.baseURL)/Ryde/api/groupuser")
                    }
                    
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
                    //remove the group since it didn't work right
                else {
                    
                }
            }
        })
        
        task.resume()
    }

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
    

    // Mark - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    // Mark - Search Bar Delegates
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchActive = true;
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }
    
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
                    // Woa, okay the json object was nil, something went worng. Maybe the server isn't running?
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
    
    // Mark - TableView Delegates
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchBarResults.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
       
        let row = indexPath.row
        
        let cell = groupMemberTableView.dequeueReusableCellWithIdentifier("memberCell") as UITableViewCell!
        
        cell.selectionStyle = .None
        
        let memberRow = searchBarResults[row]
        
        if let memberFirstName = memberRow["firstName"] as? String {
            if let memberLastName = memberRow["lastName"] as? String {
                cell.textLabel!.text = memberFirstName + " " + memberLastName
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

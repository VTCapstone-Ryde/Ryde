//
//  EditGroupDetailsViewController.swift
//  Ryde
//
//  Created by Cody Cummings on 4/12/16.
//  Copyright © 2016 Jared Deiner. All rights reserved.
//

import UIKit
import Foundation

class EditGroupDetailsViewController: UIViewController {

    // MARK: - Fields
    
    var groupInfo: NSDictionary?
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var currentUser: NSDictionary?
    
    var searchBarResults = [NSDictionary]()
    
    //bool to allow new members to be added or not
    var addingNewMembers: Bool = false
    
    //list of admins in the group
    var adminList = [NSDictionary]()
    
    //list of members in the group
    var memberList = [NSDictionary]()
    
    //list of members when the group began being edited
    var initialMemberList = [NSDictionary]()
    
    //list of admins when the group began being edited
    var initialAdminList = [NSDictionary]()
    
    //list of users that are selected at the end of editing
    var selectedGroupMembers = [NSDictionary]()
    
    //reference to the search bar if active
    var activeSearchBar: UISearchBar?
    
    //bool to tell us if the search bar is active
    var searchActive: Bool = false
    
    // MARK: - IBOutlets
    @IBOutlet var scrollView: UIScrollView!
    
    @IBOutlet var groupMemberSearchBar: UISearchBar!
    
    @IBOutlet var groupNameTextField: UITextField!
    
    @IBOutlet var groupDescriptionTextView: UITextView!
    
    @IBOutlet var groupMemberTableView: UITableView!
    
    @IBOutlet var addNewMembersButton: UIButton!
    
    // MARK: - IBActions
    
    //button press that allows new users to be added the group
    @IBAction func addNewMembersPressed(sender: AnyObject) {
        if (addingNewMembers) {
            addingNewMembers = false
            memberList = selectedGroupMembers
            selectedGroupMembers.removeAll()
            searchBarSearchButtonClicked(groupMemberSearchBar)
            searchBarTextDidEndEditing(groupMemberSearchBar)
            addNewMembersButton.setTitle("Add New Members", forState: UIControlState.Normal)
            groupMemberTableView.reloadData()
            
        }
        else {
            addingNewMembers = true
            addNewMembersButton.setTitle("Done Adding New Members", forState: UIControlState.Normal)
            searchBarSearchButtonClicked(groupMemberSearchBar)
            searchBarTextDidEndEditing(groupMemberSearchBar)
            selectedGroupMembers = memberList
            groupMemberTableView.reloadData()
        }
    }
    
    //segue to the edit timeslots page
    @IBAction func editTimeslotsPressed(sender: AnyObject) {
        
        performSegueWithIdentifier("timeslots", sender: self)
        
    }
    
    //checks that all of the groups fields are correctly filled out and valid.
    @IBAction func saveEditedGroupPressed(sender: UIBarButtonItem) {
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
        else if (adminList.count == 0) {
            let alertController = UIAlertController(title: "No Admins", message: "You must select at least one member to be the administrator of the group!", preferredStyle: UIAlertControllerStyle.Alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: { (action:UIAlertAction) -> Void in
            })
            alertController.addAction(okAction)
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        //We have all of the fields ready, now we need to save the group and update the groupuser table
        else {
            
            let description = groupDescriptionTextView.text
            let title = groupNameTextField.text
            let id = String(groupInfo!["id"]!)
            
            //Make the group object
            let JSONGroupObject: [String : String] = [
                
                "description":  description!,
                "directoryPath": "none",
                "id" : id,
                "title": title!
            ]
            
            // Sends a PUT to the specified URL with the JSON conent
            self.putGroup(JSONGroupObject, url: "http://\(self.appDelegate.baseURL)/Ryde/api/group/\(id)")
            
            let adminSet = Set(adminList)
            let initialAdminSet = Set(initialAdminList)
            
            let memberSet = Set(memberList)
            let initialMemberSet = Set(initialMemberList)
            
            //gets all of the old admins that are no longer admins
            let removeAdminStatusSet = initialAdminSet.subtract(adminSet)
            
            //gets all of the new admins that were not admins before
            let addAdminStatusSet = adminSet.subtract(initialAdminSet)
            
            //gets all of the old members that are no longer members
            let removeMemberStatusSet = initialMemberSet.subtract(memberSet)
            
            //gets all of the new members that were not members before
            let addMemberStatusSet = memberSet.subtract(initialMemberSet)
            
            //set the group ID to the group we just updated
            let groupDict = [ "id" : id ]
            
            //add all of the members that were added to the group to the database
            //Do this first so that updates to the admin aren't affected
            for newMember in addMemberStatusSet {
                
                if let memberID = newMember["id"] {
                    let memberIDString = String(memberID)
                    let memberDict = [ "id" : memberIDString ]
                    
                    let JSONGroupUserObject = [
                        
                        "admin": "0",
                        "groupId": groupDict,
                        "userId": memberDict
                    ]
                    
                    self.postGroupUser(JSONGroupUserObject, url: "http://\(self.appDelegate.baseURL)/Ryde/api/groupuser")
                }
            }
            
            //update all of the admin priviledges in the database that were revoked in the group
            //Do this second so that removing members isn't affected
            for initialAdmin in removeAdminStatusSet {
                
                if let memberID = initialAdmin["id"] {
                    let memberIDString = String(memberID)
                    
                    self.putGroupUser("http://\(self.appDelegate.baseURL)/Ryde/api/groupuser/admin/\(memberIDString)/\(id)/0")
                }
            }
            
            //update all of the admin priviledges in the database that were added in the group
            for newAdmin in addAdminStatusSet {
                
                if let memberID = newAdmin["id"] {
                    let memberIDString = String(memberID)

                    self.putGroupUser("http://\(self.appDelegate.baseURL)/Ryde/api/groupuser/admin/\(memberIDString)/\(id)/1")
                }
            }
            
            //remove all of the members from the database that were removed from the group
            for initialMember in removeMemberStatusSet {
                
                if let memberID = initialMember["id"] {
                    
                    self.deleteGroupUser("http://\(self.appDelegate.baseURL)/Ryde/api/removeUserFromGroup//\(memberID)/\(id)")
                }
            }
            
            //display completed message
            let alertController = UIAlertController(title: "Group Successfully Updated!", message: "Your group \(title!) has been updated!", preferredStyle: UIAlertControllerStyle.Alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: { (action:UIAlertAction) -> Void in
                self.performSegueWithIdentifier("UnwindToDetails-Save", sender: nil)
            })
            alertController.addAction(okAction)
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    //removes the group from our group list after the user confirms the action
    @IBAction func deleteGroupPressed(sender: UIButton) {
        let alertController = UIAlertController(title: "Are you sure?", message: "Once a group is deleted, it cannot be recovered", preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.Default, handler: { (action:UIAlertAction) -> Void in
            let id = self.groupInfo!["id"]!
            self.deleteGroup("http://\(self.appDelegate.baseURL)/Ryde/api/group/\(id)")
            self.performSegueWithIdentifier("UnwindToGroups-Delete", sender: nil)
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action:UIAlertAction) -> Void in
        })

        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    //MARK: - HTTP request methods
    
    //adds the new users to the group
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
    
    //updates the admins that were granted new status or taken status away
    func putGroupUser(url : String) {
        print("PUTTING TO GROUPUSER")
        
        print(url)
        
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "PUT"
        
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

    //updates the group in the database
    func putGroup(params : NSDictionary, url : String) {
        print("PUTTING UPDATE TO GROUP")
        
        print(url)
        
        self.groupInfo = params
        
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
            
            if(error != nil) {
                //do nothing
                print("updated group")
            }
            else {
                print(error)
            }
        })
        
        task.resume()

    }
    
    //deletes the group from the database
    func deleteGroup(url: String) {
        print("DELETING GROUP")

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
    
    //removes all of the users of the group from the relational database
    func deleteGroupUser(url: String) {
        print("DELETING GROUP USER")
        
        print(url)
        
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "DELETE"
        
        let task = session.dataTaskWithRequest(request, completionHandler: {(data, response, error) in
            guard let _ = data
                else {
                    print("error calling DELETE on group user")
                    return
            }
        })
        task.resume()

    }
    
    // MARK: -  Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Designate self as a subscriber to Keyboard Notifications
        registerForKeyboardNotifications()
        
        currentUser = appDelegate.currentUser
        
        groupMemberTableView.tableFooterView = UIView()
        
        //sets the title and description of the group on page
        if let dict = groupInfo {
            if let title = dict["title"] as? String {
                groupNameTextField.text = title
            }
            if let description = dict["description"] as? String {
                groupDescriptionTextView.text = description
            }
        }
        
        selectedGroupMembers.removeAll()
        
        initialAdminList = adminList
        initialMemberList = memberList
        
        //get rid of the clear button for the search bar
        for subview in self.groupMemberSearchBar.subviews {
            removeClearButtonFromSearch(subview)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.registerForKeyboardNotifications()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func removeClearButtonFromSearch(view: UIView) {
        
        for subview in view.subviews {
            removeClearButtonFromSearch(subview)
        }
        
        if (view.conformsToProtocol(UITextInputTraits)) {
            let textField = view as! UITextField
            textField.clearButtonMode = UITextFieldViewMode.Never
            
        }
        
        
    }
    
    //    /* // Taken from Keyboard App, developed by Osman Balci
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
    
    // Taken from Keyboard App, developed by Osman Balci
    // This method is called upon Keyboard Will HIDE Notification
    func keyboardWillHide(sender: NSNotification) {
        
        // Set contentInsets to top=0, left=0, bottom=0, and right=0
        let contentInsets: UIEdgeInsets = UIEdgeInsetsZero
        
        // Set scrollView's contentInsets to top=0, left=0, bottom=0, and right=0
        scrollView.contentInset = contentInsets
        
        // Set scrollView's scrollIndicatorInsets to top=0, left=0, bottom=0, and right=0
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
    // Mark: - Search Bar Delegates
    
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
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        //Clear out all old search results
        searchBarResults.removeAll()
        
        if (addingNewMembers) {
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
        else {
            //check if the search bars text is empty
            if(searchText == "") {
                searchBarResults = memberList
            }
            else {
                //sets the tableviews members
                for member in memberList {
                    if let memberFirstName = member["firstName"] as? String {
                        if let memberLastName = member["lastName"] as? String {
                            let queryName = memberFirstName + " " + memberLastName
                            let lowercaseQueryName = queryName.lowercaseString
                            
                            let lowercaseSearch = searchText.lowercaseString
                            
                            if lowercaseQueryName.rangeOfString(lowercaseSearch) != nil {
                                searchBarResults.append(member)
                            }
                        }
                    }
                }

            }
            groupMemberTableView.reloadData()
        }
    }
    

    // MARK: -  TableView Delegates
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (addingNewMembers) {
            return searchBarResults.count
        }
        else if (searchActive) {
            return searchBarResults.count
        }
        return memberList.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let row = indexPath.row
        
        //if we are attempting to add new members, do things this way
        if (addingNewMembers) {
            let cell = groupMemberTableView.dequeueReusableCellWithIdentifier("addedMemberCell") as UITableViewCell!
            
            cell.selectionStyle = .None
            
            let memberRow = searchBarResults[row]
            
            //set the cells textlabel to the full name of the user
            if let memberFirstName = memberRow["firstName"] as? String {
                if let memberLastName = memberRow["lastName"] as? String {
                    cell.textLabel!.text = memberFirstName + " " + memberLastName
                    cell.textLabel?.textColor = UIColor.whiteColor()
                }
            }

            //add or hide a checkmark
            if let _ = selectedGroupMembers.indexOf(memberRow) {
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            }
            else {
                cell.accessoryType = UITableViewCellAccessoryType.None
            }
            
            return cell

        }
        //if we are searching through the existing list of members
        else if (searchActive) {
            let cell = groupMemberTableView.dequeueReusableCellWithIdentifier("memberCell") as! EditGroupDetailsTableViewCell!
            
            cell.selectionStyle = .None
            
            let memberRow = searchBarResults[row]
            
            //set the cells textlabel to the full name of the user
            if let memberFirstName = memberRow["firstName"] as? String {
                if let memberLastName = memberRow["lastName"] as? String {
                    cell.memberNameLabel.text = memberFirstName + " " + memberLastName
                    cell.memberNameLabel.textColor = UIColor.whiteColor()
                }
            }
            //add a button to this cell
            cell.removeMember.tag = row
            cell.removeMember.addTarget(self, action: #selector(EditGroupDetailsViewController.removeMember(_:)), forControlEvents: UIControlEvents.TouchUpInside)
            
            //add the revoke/make admin button
            cell.changeAdminStatusButton.setTitle("Make Admin", forState: UIControlState.Normal)
            if let memberID = memberRow["id"] {
                for admin in adminList {
                    if let adminID = admin["id"] {
                        if String(memberID) == String(adminID) {
                            cell.changeAdminStatusButton.setTitle("Revoke Admin", forState: UIControlState.Normal)
                            break
                        }
                    }
                }
            }
            cell.changeAdminStatusButton.tag = row
            cell.changeAdminStatusButton.addTarget(self, action: #selector(EditGroupDetailsViewController.changeAdminStatus(_:)), forControlEvents: UIControlEvents.TouchUpInside)
            
            return cell

        }
        //we are just presenting members in the group
        else {
            let cell = groupMemberTableView.dequeueReusableCellWithIdentifier("memberCell") as! EditGroupDetailsTableViewCell!
            
            cell.selectionStyle = .None
            
            let memberRow = memberList[row]
            
            if let memberFirstName = memberRow["firstName"] as? String {
                if let memberLastName = memberRow["lastName"] as? String {
                    cell.memberNameLabel.text = memberFirstName + " " + memberLastName
                    cell.memberNameLabel.textColor = UIColor.whiteColor()
                }
            }
            cell.removeMember.tag = row
            cell.removeMember.addTarget(self, action: #selector(EditGroupDetailsViewController.removeMember(_:)), forControlEvents: UIControlEvents.TouchUpInside)
            
            cell.changeAdminStatusButton.setTitle("Make Admin", forState: UIControlState.Normal)
            
            //add the revoke/make admin button
            if let memberID = memberRow["id"] {
                for admin in adminList {
                    if let adminID = admin["id"] {
                        if String(memberID) == String(adminID) {
                            cell.changeAdminStatusButton.setTitle("Revoke Admin", forState: UIControlState.Normal)
                            break
                        }
                    }
                }
            }
            
            cell.changeAdminStatusButton.tag = row
            cell.changeAdminStatusButton.addTarget(self, action: #selector(EditGroupDetailsViewController.changeAdminStatus(_:)), forControlEvents: UIControlEvents.TouchUpInside)
            
            return cell

        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (addingNewMembers) {
            let row = indexPath.row
            
            let cell = groupMemberTableView.dequeueReusableCellWithIdentifier("addedMemberCell") as UITableViewCell!
            
            let memberRow = searchBarResults[row]
            
            //if the member is already in the table, remove them, otherwise add them
            if let foundIndex = selectedGroupMembers.indexOf(memberRow) {
                //remove the item at the found index
                cell.accessoryType = UITableViewCellAccessoryType.None
                selectedGroupMembers.removeAtIndex(foundIndex)
            }
            else {
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                selectedGroupMembers.append(memberRow)
            }
            
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
        }
    }

    //MARK: - Tableview button method
    
    func removeMember(sender: UIButton) {
        let row = sender.tag
        let memberRow = memberList[row]
        if let memberID = memberRow["id"] {
            if let currentUser = appDelegate.currentUser {
                if let currentID = currentUser["id"] {
                    //check to see if the user is current user. if so, do nothing
                    if String(currentID) != String(memberID) {
                        
                        //check to see if the member being removed is admin, if so, remove from admin list as well
                        for (index, admin) in adminList.enumerate() {
                            if let adminID = admin["id"] {
                                if String(memberID) == String(adminID) {
                                    adminList.removeAtIndex(index)
                                    break
                                }
                            }
                        }
                        //now remove user from memberlist and update the tableview
                        memberList.removeAtIndex(row)
                        groupMemberTableView.reloadData()
                    }
                }
            }
        }
    }
    
    //Method to revoke or grant admin status to a member
    func changeAdminStatus(sender: UIButton) {
        let row = sender.tag
        let memberRow = memberList[row]
        if (sender.titleLabel!.text == "Make Admin") {
            adminList.append(memberRow)
            groupMemberTableView.reloadData()
        }
        else if (sender.titleLabel?.text == "Revoke Admin") {
            if let memberID = memberRow["id"] {
                for (index, admin) in adminList.enumerate() {
                    if let adminID = admin["id"] {
                        if String(memberID) == String(adminID) {
                            adminList.removeAtIndex(index)
                            groupMemberTableView.reloadData()
                            break
                        }
                    }
                }

            }
            
        }
    }
    
    //MARK: - prepare for segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //pass on neccessary information to the next view or previous view
        if (segue.identifier == "UnwindToDetails-Save") {
            let dest = segue.destinationViewController as! GroupDetailsTableViewController
            dest.groupInfo = self.groupInfo
            dest.adminList = self.adminList
            dest.memberList = self.memberList
        }
        
        else if (segue.identifier == "timeslots") {
            
            let dest = segue.destinationViewController as! TimeslotsTableViewController
            dest.groupInfo = self.groupInfo
            dest.memberList = self.initialMemberList
            
        }
    }
    
}

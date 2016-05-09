//
//  GroupDetailsTableViewController.swift
//  Ryde
//
//  Created by Cody Cummings on 4/5/16.
//  Copyright © 2016 Jared Deiner. All rights reserved.
//

import UIKit

class GroupDetailsTableViewController: UITableViewController {
    
    // MARK: -  Fields
    
    //the information we get back from the server about the group
    var groupInfo: NSDictionary?
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    //list of admins for this group
    var adminList = [NSDictionary]()
    
    //list of members in this group
    var memberList = [NSDictionary]()
    
    //list of users that have requested to join this group
    var requestList = [NSDictionary]()
    
    //current users information
    var currentUser : NSDictionary?
    
    //check if we are an admin or not
    var admin = false
    
    // MARK: -  IBActions
    
    //unwind segue that refreshes the data on the page
    @IBAction func unwindToGroupDetailsViewController(sender: UIStoryboardSegue) {
        self.editGroupButton.enabled = false
        self.editGroupButton.tintColor = UIColor.clearColor()
        
        getGroupUsers()
        getGroupAdmins()
        
    }
    
    // MARK: -  IBOutlet
    
    @IBOutlet var editGroupButton: UIBarButtonItem!
    
    // MARK: -  Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //adds the refresh control to the page
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(TimeslotsTableViewController.handleRefresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl = refreshControl
        
        self.navigationController!.view.backgroundColor = UIColor.init(patternImage: UIImage(named: "BackgroundMain")!)
        
        tableView.tableFooterView = UIView()
        
    }
    
    //each time the view appears, refresh the data and the nav bar title
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let dict = groupInfo {
            if let groupTitle = dict["title"] as? String {
                self.title = groupTitle
            }
        }
        
        self.editGroupButton.enabled = false
        self.editGroupButton.tintColor = UIColor.clearColor()
        
        getGroupUsers()
        getGroupAdmins()
    }
    
    //MARK: - Refresh method
    
    //function to refresh the contents of this page
    func handleRefresh(refreshControl : UIRefreshControl) {
        
        self.editGroupButton.enabled = false
        self.editGroupButton.tintColor = UIColor.clearColor()
        
        getGroupUsers()
        getGroupAdmins()
        
        refreshControl.endRefreshing()
    }
    
    //retrieves the users that are members of our selected group
    func getGroupUsers() {
        
        print("RETRIEVE GROUPS USERS")
        
        let id = groupInfo!["id"]!
        let url = NSURL(string: "http://\(self.appDelegate.baseURL)/Ryde/api/user/inGroup/\(id)")
        
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
                print(parseJSON)
                self.memberList = parseJSON as [NSDictionary]
                // Reload the table with our new data
                dispatch_async(dispatch_get_main_queue(), {
                    self.tableView.reloadData()
                })
            }
            else {
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Error could not parse JSON: \(jsonStr!)")
            }
            
            
        })
        
        task.resume()
    }
    
    //retreives which users in the group are admins
    func getGroupAdmins() {
        print("RETRIEVE GROUPS ADMINS")
        
        let id = groupInfo!["id"]!
        let url = NSURL(string: "http://\(self.appDelegate.baseURL)/Ryde/api/group/admin/\(id)")
        
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
                print(parseJSON)
                self.adminList = parseJSON as [NSDictionary]
                
                let userID = String(self.currentUser!["id"]!)
                
                //If we find that our current user is an admin, unhide the edit group button and get the requests for the group
                for admin in self.adminList {
                    let adminID = String(admin["id"]!)
                    
                    if (userID == adminID) {
                        self.admin = true
                        self.getGroupRequests()
                        break
                    }
                }
                
                // Okay, the parsedJSON is here, lets store its values into an array
                dispatch_async(dispatch_get_main_queue(), {
                    if (self.admin) {
                        self.editGroupButton.enabled = true
                        self.editGroupButton.tintColor = self.view.tintColor
                    }
                    self.tableView.reloadData()
                })
            }
            else {
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Error could not parse JSON: \(jsonStr!)")
            }
            
            
        })
        
        task.resume()
    }
    
    //retrieves the list of users that have requested to join a group
    func getGroupRequests() {
        print("RETRIEVE GROUPS REQUESTS")
        
        let id = groupInfo!["id"]!
        
        let url = NSURL(string: "http://\(self.appDelegate.baseURL)/Ryde/api/group/findRequestUserForGroup/\(id)")
        
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
                print(parseJSON)
                self.requestList = parseJSON as [NSDictionary]
                // Okay, the parsedJSON is here, lets store its values into an array
                dispatch_async(dispatch_get_main_queue(), {
                    self.tableView.reloadData()
                })
            }
            else {
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Error could not parse JSON: \(jsonStr!)")
            }
            
            
        })
        
        task.resume()
        
    }
    
    // MARK: -  TableView Delegates
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        //if we are an admin, we add the section for requests to join
        if (self.admin) {
            return 4
        }
        else {
            return 3
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //if we are an admin, we add the section for requests to join
        if (self.admin) {
            if (section == 0) {
                return 1
            }
            else if (section == 1) {
                return adminList.count
            }
            else if (section == 2) {
                return requestList.count
            }
            else if (section == 3){
                return memberList.count
            }
            else {
                return 0
            }
            
        }
        else {
            if (section == 0) {
                return 1
            }
            else if (section == 1) {
                return adminList.count
            }
            else if (section == 2) {
                return memberList.count
            }
            else {
                return 0
            }
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        
        let cell = tableView.dequeueReusableCellWithIdentifier("groupDetailCell") as UITableViewCell!
        
        //Set the description and list of admins
        if (section == 0) {
            if let dict = groupInfo {
                print(dict)
                
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.lineBreakMode = NSLineBreakMode.ByWordWrapping
                if let groupDescription = dict["description"] as? String {
                    cell.textLabel!.text = groupDescription
                    cell.textLabel?.textColor = UIColor.whiteColor()
                }
            }
        }
        else if (section == 1) {
            let memberInfo = adminList[row]
            if let firstName = memberInfo["firstName"] as? String {
                if let lastName = memberInfo["lastName"] as? String {
                    cell.textLabel!.text = firstName + " " + lastName
                    cell.textLabel?.textColor = UIColor.whiteColor()
                }
            }
        }
        
        //if we are an admin, we add the section for requests to join
        if (self.admin) {
            
            if (section == 2) {
                
                let otherCell = tableView.dequeueReusableCellWithIdentifier("groupRequestCell") as! GroupDetailsTableViewCell
                
                //allow admins to request or deny users to join the group
                if (requestList.count > 0) {
                    let requestInfo = requestList[row]
                    if let firstName = requestInfo["firstName"] as? String {
                        if let lastName = requestInfo["lastName"] as? String {
                            otherCell.tag = row
                            otherCell.requestMemberName.text = firstName + " " + lastName
                            otherCell.requestMemberName.textColor = UIColor.whiteColor()
                            otherCell.acceptButton.tag = row
                            otherCell.denyButton.tag = row
                            otherCell.acceptButton.addTarget(self, action: #selector(GroupDetailsTableViewController.acceptRequest(_:)), forControlEvents: UIControlEvents.TouchUpInside)
                            otherCell.acceptButton.addTarget(self, action: #selector(GroupDetailsTableViewController.denyRequest(_:)), forControlEvents: UIControlEvents.TouchUpInside)
                            otherCell.denyButton.addTarget(self, action: #selector(GroupDetailsTableViewController.denyRequest(_:)), forControlEvents: UIControlEvents.TouchUpInside)
                            return otherCell
                        }
                    }
                }
                return otherCell

            }
            else if (section == 3) {
                let memberInfo = memberList[row]
                if let firstName = memberInfo["firstName"] as? String {
                    if let lastName = memberInfo["lastName"] as? String {
                        cell.textLabel!.text = firstName + " " + lastName
                        cell.textLabel?.textColor = UIColor.whiteColor()

                    }
                }
            }
            
            return cell
            
        }
        else {
            
            if (section == 2) {
                let memberInfo = memberList[row]
                if let firstName = memberInfo["firstName"] as? String {
                    if let lastName = memberInfo["lastName"] as? String {
                        cell.textLabel!.text = firstName + " " + lastName
                        cell.textLabel?.textColor = UIColor.whiteColor()
                    }
                }
            }
            return cell
            
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let section = indexPath.section
        
        if (section == 0) {
            return 100
        }
        else {
            return 50
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0){
            return "Description"
        }
        else if (section == 1) {
            return "ADMIN(S)"
        }
        
        if (self.admin) {
            if section == 2 {
                return "REQUESTS TO JOIN"
            }
            else if section == 3 {
                return "GROUP MEMBERS"
            }
            else {
                return ""
            }
        }
        else {
            if (section == 2) {
                return "GROUP MEMBERS"
            }
            else {
                return ""
            }
            
        }
        
    }
    
    //MARK: - accept/deny button actions
    
    //tells the server to add the user to the group
    func acceptRequest(sender: UIButton) {
        
        let requestUser = requestList[sender.tag]
        if let requestUserID = requestUser["id"] {
            let requestUserIDString = String(requestUserID)
            
            let url = "http://\(self.appDelegate.baseURL)/Ryde/api/groupuser"
            
            print("POSTING TO GROUPUSER")
            
            print(url)
            
            let request = NSMutableURLRequest(URL: NSURL(string: url)!)
            let session = NSURLSession.sharedSession()
            request.HTTPMethod = "POST"
            
            let id = groupInfo!["id"]!

            let groupDict = [ "id" : id ]
            let memberDict = [ "id" : requestUserIDString ]
            
            //creates a JSON object to send to the server
            let JSONGroupUserObject = [
                "admin": "0",
                "groupId": groupDict,
                "userId": memberDict
            ]
            
            
            do {
                request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(JSONGroupUserObject, options: [])
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
                
                //update the member list
                if let parseJSON = json {
                    self.memberList.append(parseJSON)
                    dispatch_async(dispatch_get_main_queue(), {
                        self.tableView.reloadData()
                    })
                }
                
            })
            
            task.resume()

        }
        
    }
    
    //tells the server that we do not want this user to be a member of the group
    func denyRequest(sender: UIButton) {
        let requestUser = requestList[sender.tag]
        if let requestUserID = requestUser["id"] {
            let requestUserIDString = String(requestUserID)
            
            let id = groupInfo!["id"]!

            let url = "http://\(self.appDelegate.baseURL)/Ryde/api/requestuser/removeByUserAndGroup/\(requestUserIDString)/\(id)"
            
            print("REMOVING FROM REQUEST GROUP")
            
            print(url)
            
            let request = NSMutableURLRequest(URL: NSURL(string: url)!)
            let session = NSURLSession.sharedSession()
            request.HTTPMethod = "DELETE"
            
            let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
                guard let _ = data
                    else {

                        return
                }
                //update the tableview
                dispatch_async(dispatch_get_main_queue(), {
                    self.requestList.removeAtIndex(sender.tag)
                    self.tableView.reloadData()
                })
            })
            
            task.resume()

        }
    }
    
    // MARK: - prepare for segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //if we going to edit the group, send the neccessary information along
        if (segue.identifier == "EditGroup") {
            let dest = segue.destinationViewController as! EditGroupDetailsViewController
            dest.groupInfo = self.groupInfo
            dest.memberList = self.memberList
            dest.adminList = self.adminList
        }
    }
}

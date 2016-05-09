//
//  GroupTableViewController.swift
//  Ryde
//
//  Created by Cody Cummings on 4/5/16.
//  Copyright © 2016 Jared Deiner. All rights reserved.
//

import UIKit

class GroupTableViewController: UITableViewController {
    
    // Mark - Outlets
    
    @IBOutlet var searchBar: UISearchBar!
    
    // Mark - Fields
        
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

    //array of the groups the current user is a member of
    var groupDictionary = [NSDictionary]()
    
    //nsdictionary of the group we have selected to view more about
    var selectedGroupInfo: NSDictionary?
    
    //variable set when user logs in to hold users information
    var currentUser: NSDictionary?
    
    // Mark - IBActions
    
    //action taken when add group is pressed
    @IBAction func addGroupPressed(sender: UIBarButtonItem) {
    }
    
    //action taken when search for group is pressed
    @IBAction func searchForGroupPressed(sender: UIBarButtonItem) {
    }
    
    //unwind segue performed to get back to this page
    @IBAction func unwindToGroupsViewController(sender: UIStoryboardSegue) {
        
    }

    // Mark - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //get rid of extra tableview rows
        tableView.tableFooterView = UIView()
        
        self.navigationController!.view.backgroundColor = UIColor.init(patternImage: UIImage(named: "BackgroundMain")!)

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        getUserInfo()
    }
    
    //retrieves the users information form the server
    func getUserInfo() {
        print("RETRIEVE USER INFO")
        
        let url = NSURL(string: "http://\(self.appDelegate.baseURL)/Ryde/api/user/findByToken/\(appDelegate.FBid)")
        
        print(url)
        
        // Creaste URL Request
        let request = NSMutableURLRequest(URL:url!);
        
        // Set request HTTP method to GET. It could be POST as well
        request.HTTPMethod = "GET"
        
        // Execute HTTP Request
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            
            // Check for error
            if error != nil
            {
                print("error=\(error)")
                return
            }
            
            let json: NSDictionary?
            
            do {
                
                json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? NSDictionary
                
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
                // Okay, the parsedJSON is here, lets store its values into the currentUser variable
                self.currentUser = parseJSON as NSDictionary
                self.appDelegate.currentUser = self.currentUser
                self.getUserGroups()
            }
            else {
                //error handling
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Error could not parse JSON: \(jsonStr!)")
            }
            
            
        })
        
        task.resume()

    }
    
    // Mark - Retrieve the users groups from the server
    func getUserGroups() {
        
        print("RETRIEVE USER GROUPS")
        
        //check that current user is set
        if let userID = currentUser!["id"] {
            
            let url = NSURL(string: "http://\(self.appDelegate.baseURL)/Ryde/api/group/user/\(userID)")
            
            print(url)
            
            // Creaste URL Request
            let request = NSMutableURLRequest(URL:url!);
            
            // Set request HTTP method to GET. It could be POST as well
            request.HTTPMethod = "GET"
            
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
                    self.groupDictionary = parseJSON as [NSDictionary]
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
    }
    
    
    // Mark - TableView Delegates
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupDictionary.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row = indexPath.row
        let cell = tableView.dequeueReusableCellWithIdentifier("groupCell") as UITableViewCell!

        //set the textlabel of the tableviewcell as the title of our group
        if let groupTitle = groupDictionary[row]["title"] as? String {
            print(groupTitle)
            cell.textLabel!.text = groupTitle
            cell.textLabel?.textColor = UIColor.whiteColor()
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = indexPath.row
        
        //since we selected this row, get ready to pass it on to the next view
        selectedGroupInfo = groupDictionary[row]
        performSegueWithIdentifier("GroupSelected", sender: nil)
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //segue to the group details page
        if (segue.identifier == "GroupSelected") {
            let dest = segue.destinationViewController as! GroupDetailsTableViewController
            dest.groupInfo = selectedGroupInfo
            dest.currentUser = currentUser
        }
        //segue to the add group page with our current users information
        else if (segue.identifier == "AddGroup") {
            let dest = segue.destinationViewController as! AddGroupViewController
            dest.currentUser = currentUser
        }
        //segue to the search groups page with the current group dictionary so we do not display groups we already belong to
        else if (segue.identifier == "SearchGroups") {
            let dest = segue.destinationViewController as! SearchGroupsTableViewController
            dest.groupDictionary = self.groupDictionary
        }
    }
}

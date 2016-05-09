//
//  SearchGroupsTableViewController.swift
//  Ryde
//
//  Created by Cody Cummings on 4/12/16.
//  Copyright © 2016 Jared Deiner. All rights reserved.
//

import UIKit

class SearchGroupsTableViewController: UITableViewController, UISearchBarDelegate {
    
    // MARK: - fields
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var currentUser: NSDictionary?
    
    var searchBarResults = [NSDictionary]()
    
    var groupDictionary = [NSDictionary]()
    
    var groupList = [String]()
    
    var selectedGroups = [String]()
    
    var searchActive : Bool = false
    
    // MARK: - IBOutlets
    
    @IBOutlet var searchBar: UISearchBar!
    
    // MARK: - IBActions
    
    @IBAction func sendRequestToGroups(sender: UIBarButtonItem) {
        
        if (selectedGroups.count == 0) {
            let alertController = UIAlertController(title: "No groups selected", message: "You need to select at least one group to request to join!", preferredStyle: UIAlertControllerStyle.Alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: { (action:UIAlertAction) -> Void in
            })
            alertController.addAction(okAction)
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        else {
            
            self.postRequests()
            
            let alertController = UIAlertController(title: "Request Sent", message: "Your request to join the selected groups has been sent!", preferredStyle: UIAlertControllerStyle.Alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: { (action:UIAlertAction) -> Void in
                
                self.performSegueWithIdentifier("UnwindToGroups-Search", sender: nil)
            })
            alertController.addAction(okAction)
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        
        
    }
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController!.view.backgroundColor = UIColor.init(patternImage: UIImage(named: "BackgroundMain")!)
        
        currentUser = appDelegate.currentUser
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: - Post method to post requests to groups
    
    func postRequests() {
        
        print(groupDictionary)
        for group in groupDictionary {
            if let groupID = group["id"] {
                groupList.append(String(groupID))
            }
        }
        
        for group in selectedGroups {
            
            if (!groupList.contains(group)) {
                if let currentID = currentUser!["id"] {
                    let memberID = String(currentID)
                    
                    let url = NSURL(string: "http://\(self.appDelegate.baseURL)/Ryde/api/requestuser/createByUserAndGroup/\(memberID)/\(group)")
                    
                    print(url)
                    // Creaste URL Request
                    let request = NSMutableURLRequest(URL:url!);
                    let session = NSURLSession.sharedSession()
                    request.HTTPMethod = "POST"
                    request.HTTPBody = nil
                    
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.addValue("application/json", forHTTPHeaderField: "Accept")
                    
                    // If needed you could add Authorization header value
                    //request.addValue("Token token=884288bae150b9f2f68d8dc3a932071d", forHTTPHeaderField: "Authorization")
                    
                    // Execute HTTP Request
                    let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
                        
                        // Check for error
                        if error != nil
                        {
                            print("error=\(error)")
                            return
                        }
                        
//                        let json: [NSDictionary]?
//                        
//                        do {
//                            
//                            json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? [NSDictionary]
//                            
//                        } catch let dataError{
//                            
//                            // Did the JSONObjectWithData constructor return an error? If so, log the error to the console
//                            print(dataError)
//                            let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
//                            print("Error could not parse JSON: '\(jsonStr!)'")
//                            // return or throw?
//                            return
//                        }
//                        
//                        // The JSONObjectWithData constructor didn't return an error. But, we should still
//                        // check and make sure that json has a value using optional binding.
//                        if let parseJSON = json {
//                            // Okay, the parsedJSON is here, lets store its values into an array
//                            return
//                        }
//                        else {
//                            // Woa, okay the json object was nil, something went worng. Maybe the server isn't running?
//                            let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
//                            print("Error could not parse JSON: \(jsonStr!)")
//                        }
                        
                        
                    })
                    
                    task.resume()
                    
                }
                
            }
        }
    }
    
    // MARK: - Search Bar Delegates
    
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
        searchBar.resignFirstResponder()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        //Clear out all old search results
        searchBarResults.removeAll()
        
        if (searchText != "") {
            print("RETRIEVE GROUPS WITH TITLE IN SEARCH BAR")
            
            let searchTextNoSpaces = searchText.stringByReplacingOccurrencesOfString(" ", withString: "+")
            
            let url = NSURL(string: "http://\(self.appDelegate.baseURL)/Ryde/api/group/title/\(searchTextNoSpaces)")
            
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
                
                // Print out response string
                //let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
                //print("responseString = \(responseString!)")
                
                
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
        else {
            tableView.reloadData()
        }
    }
    
    // MARK: - TableView Delegates
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchBarResults.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let row = indexPath.row
        
        let cell = tableView.dequeueReusableCellWithIdentifier("groupCell") as UITableViewCell!
        
        cell.selectionStyle = .None
        
        let groupRow = searchBarResults[row]
        
        if let groupTitle = groupRow["title"] as? String {
            cell.textLabel!.text = groupTitle
            cell.textLabel?.textColor = UIColor.whiteColor()
        }
        
        let groupID = String(groupRow["id"]!)
        if let _ = selectedGroups.indexOf(groupID) {
            //remove the item at the found index
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryType.None
        }
        
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = indexPath.row
        
        let cell = tableView.dequeueReusableCellWithIdentifier("groupCell") as UITableViewCell!
        
        let groupRow = searchBarResults[row]
        let groupID = String(groupRow["id"]!)
        
        if let foundIndex = selectedGroups.indexOf(groupID) {
            //remove the item at the found index
            cell.accessoryType = UITableViewCellAccessoryType.None
            selectedGroups.removeAtIndex(foundIndex)
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            selectedGroups.append(groupID)
        }
        
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
    }
    
}

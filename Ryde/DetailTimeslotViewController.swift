//
//  DetailTimeslotViewController.swift
//  Ryde
//
//  Created by Joe Fletcher on 4/27/16.
//  Copyright © 2016 Jared Deiner. All rights reserved.
//

import UIKit

class DetailTimeslotViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UISearchBarDelegate {
    
    
    //MARK: - IBOutlets
    
    @IBOutlet var deleteTimeslotButton: UIButton!
    @IBOutlet var startDateTextField: UITextField!
    @IBOutlet var endDateTextField: UITextField!
    @IBOutlet var groupMemberTableView: UITableView!
    @IBOutlet var groupMemberSearchBar: UISearchBar!
    @IBOutlet var scrollView: UIScrollView!
    
    //MARK: - Fields
    
    //list of members returned by our search
    var searchBarResults = [NSDictionary]()
    //list of members designated to drive for the timeslot
    var selectedGroupMembers = [NSDictionary]()
    //object to represent the timeslot we are creating
    var newTimeslot = NSDictionary()
    //reference to the search bar
    var activeSearchBar: UISearchBar?
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    //bool to tell us if the search bar is active
    var searchActive : Bool = false
    //info of the group
    var groupInfo : NSDictionary?
    //info of the current timeslot. Empty if creating a timeslot
    var timeslotInfo : NSDictionary?
    //list of members in the group
    var memberList = [NSDictionary]()
    //list of drivers selected to be a part of the group
    var driverList = [NSDictionary]()
    //list of drivers that were initially in the timeslot
    var initialDriverList = [NSDictionary]()
    //bool to tell us if we are creating a new group or editing one
    var add = false
    //reference to the textfield being used at this moment
    var activeTextField = UITextField()
    
    //MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.addDoneButtonOnKeyboard()
        
        //We are populating this view with a previously created timeslot
        if (!add) {
            if let tsInfo = self.timeslotInfo {
                
                let df = NSDateFormatter()
                
                if let startTime = tsInfo["startTime"] as? String {
                    df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                    let startTimeNoMinus = startTime[startTime.startIndex..<startTime.endIndex.advancedBy(-6)]
                    let startDate = df.dateFromString(startTimeNoMinus)
                    df.dateFormat = "MM/dd/yy hh:mm a"
                    self.startDateTextField.text = getDate(df.stringFromDate(startDate!))
                    
                }
                if let endTime = tsInfo["endTime"] as? String {
                    df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                    let endTimeNoMinus = endTime[endTime.startIndex..<endTime.endIndex.advancedBy(-6)]
                    df.dateFromString(endTimeNoMinus)
                    let endDate = df.dateFromString(endTimeNoMinus)
                    df.dateFormat = "MM/dd/yy hh:mm a"
                    self.endDateTextField.text = getDate(df.stringFromDate(endDate!))
                }
                if let timeslotID = tsInfo["id"] {
                    let tID = String(timeslotID)
                    getGroupDrivers(tID)
                }
            }
            
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.searchBar(self.groupMemberSearchBar, textDidChange: "")
        
        //if we are adding, hide the delete timeslot button
        if (add) {
            deleteTimeslotButton.hidden = true
        }
        else {
            deleteTimeslotButton.hidden = false
        }
        
    }
    
    //MARK: - IBActions
    
    //Check if this is the users certain action, then delete the timeslot
    @IBAction func deleteTimeslot(sender: UIButton) {
        let alertController = UIAlertController(title: "Are you sure?", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive, handler: { (action:UIAlertAction) -> Void in
            self.deleteTimeslot()
        })
        alertController.addAction(okAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action:UIAlertAction) -> Void in
        })
        alertController.addAction(cancelAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    //Add the timeslot to the database. If editing the timeslot, just update the database
    @IBAction func saveTimeslot(sender: UIBarButtonItem) {
        
        if (startDateTextField.text == "" || endDateTextField.text == "") {
            let alertController = UIAlertController(title: "Select a valid period of time!", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: { (action:UIAlertAction) -> Void in
            })
            alertController.addAction(okAction)
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        else if (selectedGroupMembers.count == 0) {
            let alertController = UIAlertController(title: "No Drivers selected!", message: "You must select at least one group member to drive during a timeslot", preferredStyle: UIAlertControllerStyle.Alert)
            let cancelAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: { (action:UIAlertAction) -> Void in })
            alertController.addAction(cancelAction)
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        else {
            if (add) {
                createTimeslot()
            }
            else {
                updateTimeslot()
            }
        }

    }
    
    //MARK: - database operations
    
    //remove the timeslot from the database
    func deleteTimeslot() {
        print("DELETING TIMESLOT")
        
        if let tID = timeslotInfo!["id"] {
            let timeslotID = String(tID)
            let url = "http://\(self.appDelegate.baseURL)/Ryde/api/timeslot/\(timeslotID)"
            
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
                dispatch_async(dispatch_get_main_queue(), {
                    self.performSegueWithIdentifier("UnwindToTimeslots-Delete", sender: nil)
                })
            })
            task.resume()
        }
    }
    
    //gets the list of drivers in a timeslot (used for edit)
    func getGroupDrivers(id: String) {
        print("RETRIEVE TIMESLOTS DRIVERS")
        
        let url = NSURL(string: "http://\(self.appDelegate.baseURL)/Ryde/api/timeslot/findDriversForTimeslot/\(id)")
        
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
                self.driverList = parseJSON as [NSDictionary]
                // Okay, the parsedJSON is here, lets store its values into an array
                for driver in self.driverList {
                    self.selectedGroupMembers.append(driver)
                }
                
                self.initialDriverList = self.driverList
                
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
    
    //creates a timeslot from the information provided and adds it to the database. Then segues back.
    func createTimeslot() {
        print("CREATING TIMESLOT")
        
        if let groupID = groupInfo!["id"] {
            let gID = String(groupID)
            
            let url = "http://\(self.appDelegate.baseURL)/Ryde/api/timeslot/createTimeslotForGroup/\(gID)"
            
            print(url)
            
            let df = NSDateFormatter()
            df.dateFormat = "MM/dd/yy hh:mm a"
            
            let df2 = NSDateFormatter()
            df2.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'-04:00'"
            
            if let startDate = df.dateFromString(startDateTextField.text!) {
                let formattedStartDate = df2.stringFromDate(startDate)
                if let endDate = df.dateFromString(endDateTextField.text!) {
                    let formattedEndDate = df2.stringFromDate(endDate)
                    
                    let timeslotJSONObject = [
                        "startTime" : formattedStartDate,
                        "endTime" : formattedEndDate
                    ]
                    
                    let request = NSMutableURLRequest(URL: NSURL(string: url)!)
                    let session = NSURLSession.sharedSession()
                    request.HTTPMethod = "POST"
                    
                    do {
                        request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(timeslotJSONObject, options: [])
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
                            if let timeslotID = parseJSON["id"] {
                                let timeslotIDString = String(timeslotID)
                                
                                for member in self.selectedGroupMembers {
                                    if let memberID = member["id"] {
                                        let memberIDString = String(memberID)
                                        self.putDriverForTimeslot(memberIDString, timeslotID: timeslotIDString)
                                    }
                                }
                                
                                print("parseJSON \(parseJSON)")
                                
                                dispatch_async(dispatch_get_main_queue(), {
                                    self.performSegueWithIdentifier("UnwindToTimeslots-Add", sender: nil)
                                })
                            }

                        }
                    })
                    
                    task.resume()
                    
                }
            }
        }
    }
    
    //adds each selected member to the timeslot driver table
    func putDriverForTimeslot(memberID: String, timeslotID: String) {
        print("ADDING DRIVER TO TIMESLOT")
        
        let url = "http://\(self.appDelegate.baseURL)/Ryde/api/timeslot/assignDriverForTimeslot/\(memberID)/\(timeslotID)"
        
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
    
    //performed when editing. Same as add except we dont make a new entry, just update the old
    func updateTimeslot() {
        print("UPDATING TIMESLOT")
        
        if let tID = timeslotInfo!["id"] {
            let timeslotID = String(tID)
            let passcode = String(timeslotInfo!["passcode"]!)
            let url = "http://\(self.appDelegate.baseURL)/Ryde/api/timeslot/\(timeslotID)"
            
            print(url)
            
            let df = NSDateFormatter()
            df.dateFormat = "MM/dd/yy hh:mm a"
            
            let df2 = NSDateFormatter()
            df2.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'-04:00'"
            
            if let startDate = df.dateFromString(startDateTextField.text!) {
                let formattedStartDate = df2.stringFromDate(startDate)
                if let endDate = df.dateFromString(endDateTextField.text!) {
                    let formattedEndDate = df2.stringFromDate(endDate)
                    
                    let timeslotJSONObject = [
                        "id" : timeslotID,
                        "startTime" : formattedStartDate,
                        "endTime" : formattedEndDate,
                        "passcode" : passcode
                    ]
                    
                    let request = NSMutableURLRequest(URL: NSURL(string: url)!)
                    let session = NSURLSession.sharedSession()
                    request.HTTPMethod = "PUT"
                    
                    do {
                        request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(timeslotJSONObject, options: [])
                    } catch {
                        print(error)
                        request.HTTPBody = nil
                    }
                    
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.addValue("application/json", forHTTPHeaderField: "Accept")
                    
                    let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
                        
                        if (error == nil) {
                            let timeslotIDString = String(timeslotID)
                            
                            let initialDriverSet = Set(self.initialDriverList)
                            let selectedGroupMemberSet = Set(self.selectedGroupMembers)
                            
                            let removedDriverStatusSet = initialDriverSet.subtract(selectedGroupMemberSet)
                            
                            for removedDriver in removedDriverStatusSet {
                                if let driverID = removedDriver["id"] {
                                    let driverIDString = String(driverID)
                                    self.deleteDriverForTimeslot(driverIDString, timeslotID: timeslotIDString)
                                }
                            }
                            
                            let addedDriverStatusSet = selectedGroupMemberSet.subtract(initialDriverSet)
                            
                            for addedDriver in addedDriverStatusSet {
                                if let driverID = addedDriver["id"] {
                                    let driverIDString = String(driverID)
                                    self.putDriverForTimeslot(driverIDString, timeslotID: timeslotIDString)
                                }
                            }
                            
                            
                            dispatch_async(dispatch_get_main_queue(), {
                                self.performSegueWithIdentifier("UnwindToTimeslots-Edit", sender: nil)
                            })
                        }
                        else {
                            print(error)
                        }

                    })
                    
                    task.resume()
                    
                }
            }
        }

    }
    
    //removes any drivers that were unselected for a timeslot (edit)
    func deleteDriverForTimeslot(driverID: String, timeslotID: String) {
        print("DELETING DRIVER FOR TIMESLOT")
        
        let url = "http://\(self.appDelegate.baseURL)/Ryde/api/timeslot/removeDriverForTimeslot/\(driverID)/\(timeslotID)"
        
        print(url)
        
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "PUT"
        
        let task = session.dataTaskWithRequest(request, completionHandler: {(data, response, error) in
            guard let _ = data
                else {
                    print("error calling DELETE on group user")
                    return
            }
        })
        task.resume()
    }
    
    
    //MARK: - startDateTextField Done Button
    
    //adds a done button to the top of the keyboard for the date pickers
    func addDoneButtonOnKeyboard()
    {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRectMake(0, 0, 320, 50))
        doneToolbar.barStyle = UIBarStyle.BlackTranslucent
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: #selector(DetailTimeslotViewController.doneButtonAction))
        
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.startDateTextField.inputAccessoryView = doneToolbar
        self.endDateTextField.inputAccessoryView = doneToolbar
        
    }
    
    //hides the keyboard when done is pressed
    func doneButtonAction()
    {
        self.startDateTextField.resignFirstResponder()
        self.endDateTextField.resignFirstResponder()
    }
    
    //MARK: - Textfield delegates
    
    func textFieldDidBeginEditing(textField: UITextField) {
        
        //if we are dealing with the date and time textfields
        if (textField == startDateTextField || textField == endDateTextField)
        {
            //set the format
            let df = NSDateFormatter()
            df.dateFormat = "MM/dd/yy hh:mm a"
            activeTextField = textField
            let thisDate = df.dateFromString(activeTextField.text!)

            //update the date picker to have the prefilled date
            let datePicker:UIDatePicker = UIDatePicker()
            datePicker.datePickerMode = UIDatePickerMode.DateAndTime
            if let defaultDate = thisDate {
                datePicker.setDate(defaultDate, animated: false)
            }
            textField.inputView = datePicker
            datePicker.addTarget(self, action: #selector(DetailTimeslotViewController.updateTextfield(_:textField:)), forControlEvents: UIControlEvents.ValueChanged)
            let components = NSDateComponents()
            components.setValue(1, forComponent: NSCalendarUnit.Year);
            let date: NSDate = NSDate()
            let expirationDate = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: date, options: NSCalendarOptions(rawValue: 0))
            datePicker.maximumDate = expirationDate
            datePicker.minimumDate = NSDate()
        }
    }
    
    //makes the textfield show the date from the database
    func updateTextfield(sender: UIDatePicker, textField: UITextField)
    {
        let dFormatter = NSDateFormatter();
        dFormatter.dateFormat = "MM/dd/yy hh:mm a"
        activeTextField.text = getDate(dFormatter.stringFromDate(sender.date))
    }
    
    //MARK: date functions
    
    func getDate(date: String) -> String
    {
        return date
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
    
    //updates the tableview when the search bars text changes. Only uses local lists so no requests issued
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        //Clear out all old search results
        searchBarResults.removeAll()
        
        if (searchText == "") {
            searchBarResults = memberList
        }
        else {
            for member in memberList {
                if let memberFirstName = member["firstName"] as? String {
                    if let memberLastName = member["lastName"] as? String {
                        let fullName = memberFirstName + " " + memberLastName
                        let lowercaseFullName = fullName.lowercaseString
                        let lowercaseSearch = searchText.lowercaseString
                        if (lowercaseFullName.containsString(lowercaseSearch)) {
                            searchBarResults.append(member)
                        }
                    }
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), {
            self.groupMemberTableView.reloadData()
        })
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
        
        //sets the cells textlabel as the full name of the member of the group
        if let memberFirstName = memberRow["firstName"] as? String {
            if let memberLastName = memberRow["lastName"] as? String {
                cell.textLabel!.text = memberFirstName + " " + memberLastName
                cell.textLabel?.textColor = UIColor.whiteColor()
            }
        }
        
        //show or hide the checkmark next to a driver
        if let _ = selectedGroupMembers.indexOf(memberRow) {
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
        
        //add or hide the checkmark next to a driver
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

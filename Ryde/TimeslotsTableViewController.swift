//
//  TimeslotsTableViewController.swift
//  Ryde
//
//  Created by Joe Fletcher on 4/25/16.
//  Copyright © 2016 Jared Deiner. All rights reserved.
//

import UIKit

class TimeslotsTableViewController: UITableViewController {

    // Mark - Fields
    
    var groupInfo: NSDictionary?
    
    var timeslotInfo = [NSDictionary]()
    
//    var tsIDtoNumDrivers = [Int:Int]()
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var numOfDrivers = 0
    
    var memberList = [NSDictionary]()
    
    var driverList = [NSDictionary]()
    
    var selectedTimeSlot : NSDictionary?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(TimeslotsTableViewController.handleRefresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl = refreshControl
        
        self.view.backgroundColor = UIColor.init(patternImage: UIImage(named: "BackgroundMain")!)
        
        self.title = "\(groupInfo!["title"] as! String): Timeslot"
        
        getData()
        
    }
    
    func handleRefresh(refreshControl : UIRefreshControl) {
        
        getData()
        
        refreshControl.endRefreshing()
    }
    
    // MARK - Get Data
    
    func getData() {
        
        // Fetch All Timeslots (if any) for THIS group
        
        let url = NSURL(string: "http://\(self.appDelegate.baseURL)/Ryde/api/timeslot/timeslotsForGroupSorted/\(String(groupInfo!["id"]!))")
        //        let url = NSURL(string: "http://jupiter.cs.vt.edu/Ryde/api/user")
        
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
            //            let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            //            print("responseString = \(responseString!)")
            
            
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
                self.timeslotInfo = parseJSON as [NSDictionary]
                
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
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return timeslotInfo.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let timeSlotsPerDate = timeslotInfo[section]["timeslots"] {
            return timeSlotsPerDate.count
        }
        else {
            return 0
        }
    
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        let calendar = NSCalendar.currentCalendar()
        calendar.timeZone = NSTimeZone(abbreviation: "GMT")!
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
    
        
        if let timeSlotDate = timeslotInfo[section]["date"] {
            
            let exampleServerStartDateArray = timeSlotDate.componentsSeparatedByString("T")
            let exampleServerStartDate = exampleServerStartDateArray[0]
            
            // Start Date
            let tempDate = dateFormatter.dateFromString(exampleServerStartDate)
            print(tempDate!)
            let comp = calendar.components([.Day, .Month, .Year, .Hour, .Minute], fromDate: tempDate!)
            let startDateComponent = NSDateComponents()
            startDateComponent.year = comp.year
            startDateComponent.month = comp.month
            startDateComponent.day = comp.day
            startDateComponent.hour = comp.hour
            startDateComponent.minute = comp.minute
            // Get NSDate given the above date components
            let startDate = calendar.dateFromComponents(startDateComponent)
            
            // Format Start Date
            dateFormatter.dateStyle = NSDateFormatterStyle.FullStyle
            
            
            //print("Start Date: \(dateFormatter.stringFromDate(startDate!))")
            
            
            // Determine if the Start Date is either today or tomorrow.
            
            var headerTitle = dateFormatter.stringFromDate(startDate!)
            
            // Check if date is today
            
            // get the current date and time
            let currentDateTime = NSDate()
            
            print("Current Date: \(currentDateTime)")
            
            let order = NSCalendar.currentCalendar().compareDate(currentDateTime, toDate: tempDate! ,
                                                                 toUnitGranularity: .Day)
            
            switch order {
            case .OrderedDescending:
                print("DESCENDING")
            case .OrderedAscending:
                print("ASCENDING")
            case .OrderedSame:
                print("SAME")
                headerTitle = "Today"
                
            }
            
            return headerTitle
        }
        else {
           return "N/A"
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("timeslotCell", forIndexPath: indexPath)
        
        if let timeSlotList = timeslotInfo[indexPath.section]["timeslots"] as? [[String: AnyObject]]{
            
            var AMPMLabelStart = "AM"
            var AMPMLabelEnd = "AM"

            let timeSlotDic = (timeSlotList)[indexPath.row]
            
//            let id = timeSlotDic["id"] as! Int
            
//            cell.detailTextLabel?.text = "Driver(s): \(tsIDtoNumDrivers[id]!)"

            
            var startTime = timeSlotDic["startTime"]!.componentsSeparatedByString("T")[1].componentsSeparatedByString("-")[0]
            startTime = startTime[startTime.startIndex..<startTime.endIndex.advancedBy(-3)]
            var startTimeHour = Int(startTime[startTime.startIndex..<startTime.startIndex.advancedBy(2)])
            
            
            if startTimeHour > 12 {
                startTimeHour = startTimeHour! - 12
                AMPMLabelStart = "PM"
                startTime = "\(String(startTimeHour!))\(startTime[startTime.startIndex.advancedBy(2)..<startTime.endIndex])"
            }
            else if startTimeHour == 12 {
                startTime = "Noon"
            }
            else if startTimeHour == 0 {
                startTime = "Midnight"
            }
            
            
            
            
            
            var endTime = timeSlotDic["endTime"]!.componentsSeparatedByString("T")[1].componentsSeparatedByString("-")[0]
            endTime = endTime[endTime.startIndex..<endTime.endIndex.advancedBy(-3)]
            var endTimeHour = Int(endTime[endTime.startIndex..<endTime.startIndex.advancedBy(2)])
            
            if endTimeHour > 12 {
                endTimeHour = endTimeHour! - 12
                AMPMLabelEnd = "PM"
                endTime = "\(String(endTimeHour!))\(endTime[endTime.startIndex.advancedBy(2)..<endTime.endIndex])"
                
            }
            else if endTimeHour == 12 {
                endTime = "Noon"
            }
            else if endTimeHour == 0 {
                endTime = "Midnight"
            }
            
            
            
            if AMPMLabelStart == AMPMLabelEnd {
                cell.textLabel?.text = "\(startTime) - \(endTime) \(AMPMLabelStart)"
            }
                
            else {
            
                cell.textLabel?.text = "\(startTime) \(AMPMLabelStart) - \(endTime) \(AMPMLabelEnd)"
            }
            

        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = indexPath.row
        let section = indexPath.section
        
        let timeslotsForDate = self.timeslotInfo[section]
        let timeslotList = timeslotsForDate["timeslots"] as! [NSDictionary]
        let timeslot = timeslotList[row]
        self.selectedTimeSlot = timeslot
        
        performSegueWithIdentifier("EditTimeslot", sender: self)
    }
    
    //MARK: - Unwind action
    
    @IBAction func unwindToTimeslots(segue: UIStoryboardSegue) {
        getData()
    }
    
    // MARK - Prepare for Segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "EditTimeslot" {
            let dest = segue.destinationViewController as! DetailTimeslotViewController
            dest.groupInfo = self.groupInfo
            dest.memberList = self.memberList
            dest.timeslotInfo = self.selectedTimeSlot
            dest.add = false
        }
        else if (segue.identifier == "CreateTimeslot") {
            let dest = segue.destinationViewController as! DetailTimeslotViewController
            dest.groupInfo = self.groupInfo
            dest.memberList = self.memberList
            dest.add = true
        }
    }

}

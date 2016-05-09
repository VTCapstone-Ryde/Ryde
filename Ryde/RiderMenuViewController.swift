//
//  RiderMenuViewController.swift
//  Ryde
//
//  Created by Franki Yeung on 4/20/16.
//  Copyright © 2016 Jared Deiner. All rights reserved.
//

import UIKit

protocol RiderSlideMenuDelegate {
    func slideMenuItemSelectedAtIndex(index : Int32)
}

class RiderMenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    /**
     *  Array to display menu options
     */
    @IBOutlet var tblMenuOptions : UITableView!
    
    /**
     *  Transparent button to hide menu
     */
    @IBOutlet var btnCloseMenuOverlay : UIButton!
    
    /**
     *  Array containing menu options
     */
    var arrayMenuOptions = [Dictionary<String,String>]()
    
    /**
     *  Menu button which was tapped to display the menu
     */
    var btnMenu : UIButton!
    
    /**
     *  Delegate of the MenuVC
     */
    var delegate : RiderSlideMenuDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set the view appropriately
        tblMenuOptions.tableFooterView = UIView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateArrayMenuOptions()
    }
    
    /**
     *  Method to add items to the array the menu reads from
     */
    func updateArrayMenuOptions(){
        //Adds an item to the array the menu reads from with the item's title and icon path
        arrayMenuOptions.append(["title":"Contact Driver", "icon":"Call"])
        arrayMenuOptions.append(["title":"Cancel Ride", "icon":"Cancel"])
        
        // Reload the table displaying the items after adding new items
        tblMenuOptions.reloadData()
    }
    
    /**
     *   Method for handing menu closing
     *
     *   Removes the menu's view controller when button is pressed
     *   Button is placed on the background of the view controller
     */
    @IBAction func onCloseMenuClick(button:UIButton!){
        btnMenu.tag = 0
        
        // Handles row selection
        if (self.delegate != nil) {
            var index = Int32(button.tag)
            // sets index appropriately if no item was chosen
            if(button == self.btnCloseMenuOverlay){
                index = -1
            }
            // Passes row selection information
            delegate?.slideMenuItemSelectedAtIndex(index)
        }
        
        // Animation for removing menuView and display parent's view
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.view.frame = CGRectMake(-UIScreen.mainScreen().bounds.size.width, 0, UIScreen.mainScreen().bounds.size.width,UIScreen.mainScreen().bounds.size.height)
            self.view.layoutIfNeeded()
            self.view.backgroundColor = UIColor.clearColor()
            }, completion: { (finished) -> Void in
                self.view.removeFromSuperview()
                self.removeFromParentViewController()
        })
    }
    
    /**
     * Populates the table with cells that matches the items in the arrayMenuOptions
     */
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell : UITableViewCell = tableView.dequeueReusableCellWithIdentifier("cellMenu")!
        
        // Sets up cell properties
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        cell.layoutMargins = UIEdgeInsetsZero
        cell.preservesSuperviewLayoutMargins = false
        cell.backgroundColor = UIColor.clearColor()
        
        // Set up links for the cell's Label and Images locally
        let lblTitle : UILabel = cell.contentView.viewWithTag(101) as! UILabel
        let imgIcon : UIImageView = cell.contentView.viewWithTag(100) as! UIImageView
        
        // Set the image for current cell to the one in the current item of the array
        imgIcon.image = UIImage(named: arrayMenuOptions[indexPath.row]["icon"]!)
        // Set the title for current cell to the one in the current item of the array
        lblTitle.text = arrayMenuOptions[indexPath.row]["title"]!
        
        return cell
    }
    
    // Row selection handling
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Creates a temporary button to close menu
        let btn = UIButton(type: UIButtonType.Custom)
        btn.tag = indexPath.row
        // Closes current view when a selection is made
        self.onCloseMenuClick(btn)
    }
    
    // The number of rows in each section
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayMenuOptions.count
    }
    
    // The number of sections in the table view
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1;
    }
}
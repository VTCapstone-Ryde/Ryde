//
//  DriverBaseViewController.swift
//  Ryde
//
//  Created by Blake Duncan on 4/7/16.
//  Copyright © 2016 Jared Deiner. All rights reserved.
//

import UIKit

class DriverBaseViewController: UIViewController, SlideMenuDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func slideMenuItemSelectedAtIndex(index: Int32) {
        let topViewController : UIViewController = self.navigationController!.topViewController!
        print("View Controller is : \(topViewController) \n", terminator: "")
        switch(index){
        case 0:
            //confirm Log out
            let alertController = UIAlertController(title: "Confirmation",
                message: "Are you sure you would like to log out?",
                preferredStyle: UIAlertControllerStyle.Alert)
            
            // Create a UIAlertAction object and add it to the alert controller
            alertController.addAction(UIAlertAction(title: "Confirm", style: .Default, handler: { (action: UIAlertAction!) in
                self.navigationController?.popViewControllerAnimated(true)
            }))
            alertController.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
            
            // Present the alert controller by calling the presentViewController method
            presentViewController(alertController, animated: true, completion: nil)
            break
        case 1:
            print("Play\n", terminator: "")
            break
        default:
            print("default\n", terminator: "")
        }
    }
    
    //Adds the slide menu button
    func addSlideMenuButton(){
        let btnShowMenu = UIButton(type: UIButtonType.System)
        btnShowMenu.setImage(self.defaultMenuImage(), forState: UIControlState.Normal)
        btnShowMenu.frame = CGRectMake(0, 0, 30, 30)
        btnShowMenu.addTarget(self, action: #selector(DriverBaseViewController.onSlideMenuButtonPressed(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        let customBarItem = UIBarButtonItem(customView: btnShowMenu)
        self.navigationItem.leftBarButtonItem = customBarItem;
    }
    
    //Sets the images for the slide menu
    func defaultMenuImage() -> UIImage {
        var defaultMenuImage = UIImage()
        
        struct Static {
            static var onceToken: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.onceToken, { () -> Void in
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(30, 22), false, 0.0)
            
            UIColor.blackColor().setFill()
            UIBezierPath(rect: CGRectMake(0, 3, 30, 1)).fill()
            UIBezierPath(rect: CGRectMake(0, 10, 30, 1)).fill()
            UIBezierPath(rect: CGRectMake(0, 17, 30, 1)).fill()
            
            UIColor.whiteColor().setFill()
            UIBezierPath(rect: CGRectMake(0, 4, 30, 1)).fill()
            UIBezierPath(rect: CGRectMake(0, 11,  30, 1)).fill()
            UIBezierPath(rect: CGRectMake(0, 18, 30, 1)).fill()
            
            defaultMenuImage = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
        })
        
        return defaultMenuImage;
    }
    
    //Opens the slide menu when the slide menu button is pressed
    func onSlideMenuButtonPressed(sender : UIBarButtonItem){
        if (sender.tag == 10)
        {
            // To Hide Menu If it already there
            self.slideMenuItemSelectedAtIndex(-1);
            
            sender.tag = 0;
            
            let viewMenuBack : UIView = view.subviews.last!
            
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                var frameMenu : CGRect = viewMenuBack.frame
                frameMenu.origin.x = -1 * UIScreen.mainScreen().bounds.size.width
                viewMenuBack.frame = frameMenu
                viewMenuBack.layoutIfNeeded()
                viewMenuBack.backgroundColor = UIColor.clearColor()
                }, completion: { (finished) -> Void in
                    viewMenuBack.removeFromSuperview()
            })
            
            return
        }
        
        sender.enabled = false
        sender.tag = 10
        
        let menuVC : DriverMenuViewController = self.storyboard!.instantiateViewControllerWithIdentifier("DriverMenuViewController") as! DriverMenuViewController
        menuVC.btnMenu = sender
        menuVC.delegate = self
        self.view.addSubview(menuVC.view)
        self.addChildViewController(menuVC)
        menuVC.view.layoutIfNeeded()
        
        
        menuVC.view.frame=CGRectMake(0 - UIScreen.mainScreen().bounds.size.width, 0, UIScreen.mainScreen().bounds.size.width, UIScreen.mainScreen().bounds.size.height);
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            menuVC.view.frame=CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width, UIScreen.mainScreen().bounds.size.height);
            sender.enabled = true
            }, completion:nil)
    }

}

//
//  GroupDetailsTableViewCell.swift
//  Ryde
//
//  Created by Cody Cummings on 4/26/16.
//  Copyright © 2016 Jared Deiner. All rights reserved.
//

import UIKit

class GroupDetailsTableViewCell: UITableViewCell {

    //text label to display the name of the user requesting to join the group
    @IBOutlet var requestMemberName: UILabel!
    
    //button used to accept a request
    @IBOutlet var acceptButton: UIButton!
    
    //button used to deny a request
    @IBOutlet var denyButton: UIButton!
}

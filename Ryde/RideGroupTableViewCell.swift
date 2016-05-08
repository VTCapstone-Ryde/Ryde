//
//  RideGroupTableViewCell.swift
//  Ryde
//
//  Created by Franki Yeung on 4/11/16.
//  Copyright © 2016 Jared Deiner. All rights reserved.
//

import UIKit

class RideGroupTableViewCell: UITableViewCell {
    
    @IBOutlet var rowName: UILabel! // the name of the group

    @IBOutlet var numDriverLabel: UILabel!  // The number of drivers
    @IBOutlet var numQueueLabel: UILabel!   // the number of people in queue
}

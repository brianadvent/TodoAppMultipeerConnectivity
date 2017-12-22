//
//  TodoTableViewCell.swift
//  Todo
//
//  Created by Brian Advent on 08.12.17.
//  Copyright © 2017 Brian Advent. All rights reserved.
//

import UIKit

protocol TodoCellDelegate {
    func didRequestDelete(_ cell:TodoTableViewCell)
    func didRequestComplete(_ cell:TodoTableViewCell)
    func didRequestShare(_ cell:TodoTableViewCell)
}

class TodoTableViewCell: UITableViewCell {

    var delegte:TodoCellDelegate?
    
    @IBOutlet weak var todoLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBAction func deleteTodo(_ sender: Any) {
        if let delegateObject = self.delegte {
            delegateObject.didRequestDelete(self)
        }
    }
    
    @IBAction func shareToDo(_ sender: Any) {
        if let delegateObject = self.delegte {
            delegateObject.didRequestShare(self)
        }
    }
    @IBAction func completeTodo(_ sender: Any) {
        if let delegateObject = self.delegte {
            delegateObject.didRequestComplete(self)
        }
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

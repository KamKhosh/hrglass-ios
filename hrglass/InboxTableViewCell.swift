//
//  InboxTableViewCell.swift
//  hrglass
//
//  Created by Justin Hershey on 8/1/17.
//
//

import UIKit

class InboxTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var messageLbl: UILabel!
    @IBOutlet weak var profImageView: UIImageView!
    
    @IBOutlet weak var chevron: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        self.profImageView.layer.cornerRadius = self.profImageView.frame.height/2
        self.profImageView.clipsToBounds = true
        self.chevron.image = UIImage(named: "chevron")?.transform(withNewColor: UIColor.white)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

//
//  AddPostTableViewCell.swift
//  hrglass
//
//  Created by Justin Hershey on 10/10/17.
//
//

import UIKit

class AddPostTableViewCell: UITableViewCell {

    //cell storyboard outlets
    @IBOutlet weak var songImageView: UIImageView!
    @IBOutlet weak var songNameLbl: UILabel!
    @IBOutlet weak var artistLbl: UILabel!
    
    var videoId: String!
    var thumbnailUrl: String!
    
    var videoDictionary: YoutubeVideoData = YoutubeVideoData.init()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

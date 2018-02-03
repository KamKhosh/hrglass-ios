//
//  FeedViewCellDelegate.swift
//  hrglass
//
//  Created by Justin Hershey on 10/3/17.
//
//
import UIKit

protocol TableViewCellDelegate {
    func tableViewCell(singleTapActionDelegatedFrom cell: FeedTableViewCell)
    func tableViewCell(doubleTapActionDelegatedFrom cell: FeedTableViewCell)
}


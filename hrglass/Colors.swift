//
//  FontsAndColors.swift
//  hrglass
//
//  Created by Justin Hershey on 5/10/17.
//
//  Used to retrieve re-occurring colors

import Foundation
import UIKit



class Colors {
    
    let menuColor: String = "#F04863"
    let searchBarColor: String = "#E03F59"
    let searchBarBackgroundColor: String = "#B92B41"
    let purpleColor: String = "#C68FFF"
    let seenPostColor: String = "#DCDADA"
    let audioPostColor: String = "#D5FB89"
    let orangeRed: String = "#FF5F45"
    let videoPostColor: String = ""

    let mainBlueColor: String = "#2295C6"
    let photoPostColor: String = ""
    
    func getGradientLayer() -> CAGradientLayer{
        
        var gl:CAGradientLayer!
        let colorTop = self.getMainBlueColor().cgColor
        let colorBottom = self.getMenuColor().cgColor
        
        gl = CAGradientLayer()
        gl.colors = [colorTop, colorBottom]
        gl.locations = [0.1, 0.9]
        
        return gl
    }
    
    func getMainBlueColor() -> UIColor {
        
        //main light blue color used in the logo and welcome background gradient
        return hexStringToUIColor(hex: self.mainBlueColor)
    }
    
    func getTextPostColor () -> UIColor{
        //main side menu background color
        return UIColor.black
    }
    
    func getMenuColor () -> UIColor{
    //main side menu background color
        return hexStringToUIColor(hex: self.menuColor)
    }
    
    
    func getSearchBarBackgroungColor() -> UIColor{
    //search bar background color
        return hexStringToUIColor(hex: self.searchBarBackgroundColor)
        
    }
    
    
    func getSearchBarColor () -> UIColor{
    //search bar textfield background color
        return hexStringToUIColor(hex: self.searchBarColor)
    
    }
    
    func getSeenPostColor () -> UIColor{
        
        return hexStringToUIColor(hex: self.seenPostColor)
        
    }
    
    func getPurpleColor () -> UIColor{
        
        
        return hexStringToUIColor(hex: self.purpleColor)
    }
    
    func getAudioColor () -> UIColor{
    
        return hexStringToUIColor(hex: self.audioPostColor)
    }
    
    func getOrangeRedColor () -> UIColor{
        
        return hexStringToUIColor(hex: self.orangeRed)
        
        
    }
    
    
    func hexStringToUIColor (hex:String) -> UIColor {
    //converts a hexString into a UIColor and returns the UIColor
        
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.characters.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    

    
    
    
    
    
    
}

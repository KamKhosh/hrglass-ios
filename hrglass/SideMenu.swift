//
//  FeedViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 4/27/17.
//

// Protocol SideMenuDelegate --> parents must conform to register menuTable selection
//
// Class --> designated to cofigure a side menu with a defined width
//
// Initialized with a defined width, menu table titles, parentviewcontroller, and currentUser
//
//

import UIKit


protocol SideMenuDelegate {
    
    func didSelectMenuItem (withTitle title:String, index:Int)
    
    func didSelectProfile()
    
}


enum MenuOptions: String{
    
    case discover = "Discover"
    case messages = "Messages"
    case home = "Home"
    
}



class SideMenu: UIView, UITableViewDelegate, UITableViewDataSource {

    //overlays feed view with a translucent white view
    var backgroundView:UIView!
    
    //image cache
    let imageCache:ImageCache = ImageCache()
    
    
    //table setup for discover, messages, home,
    var menuTable:UITableView!
    
    //top search bar
    var searchBar: UISearchBar!
    
    //secondary profile view
    var profileView: UIView!
    var overlayView: UIView!
    
    //menu table items
    var menuItemTitles = [MenuOptions]()
    
    //dynamic animation handler
    var animator:UIDynamicAnimator!
    
    //side menu colors class
    let uiStyles = Colors()
    
    
    /***************************************
     * VARIABLES PASSED FROM PARENT ON INIT
     **************************************/
    var loggedInUser: User!
    var menuWidth:CGFloat = 0
    var parentViewController = UIViewController()
    
    
    
    /****************
     * MENU DELEGATE
     ****************/
    var menuDelegate:SideMenuDelegate?
    

    /*************************
     *
     * ---- INITIALIZERS ----
     *
     *************************/
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    
    
    init(menuWidth:CGFloat, menuItemTitles:[MenuOptions], parentViewController:FeedViewController, loggedInUser: User) {
        
        super.init(frame: CGRect(x: -menuWidth, y: 0, width: menuWidth, height: parentViewController.view.frame.height))
        
        self.menuWidth = menuWidth
        self.menuItemTitles = menuItemTitles
        self.parentViewController = parentViewController
        self.loggedInUser = loggedInUser
        
        parentViewController.view.addSubview(self)
        
        self.backgroundColor = uiStyles.getMenuColor()
        
        setupMenuView()
        
        animator = UIDynamicAnimator(referenceView: parentViewController.view)
        
        let showMenuRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(SideMenu.handleGestures(recognizer:)))
        
        showMenuRecognizer.direction = .right
        parentViewController.view.addGestureRecognizer(showMenuRecognizer)
        
        let hideMenuRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(SideMenu.handleGestures(recognizer:)))
        
        hideMenuRecognizer.direction = .left
        parentViewController.view.addGestureRecognizer(hideMenuRecognizer)
        
        let closeMenuTap = UITapGestureRecognizer(target: self, action:  #selector (self.closeMenu))
        
        self.backgroundView.addGestureRecognizer(closeMenuTap)
        
        
    }
    
    
    /*****************************************
     *
     * -------- Side MENU CONTROLS -------
     *
     * - swipe gesture support to toggle menu
     *
     *****************************************/
    func handleGestures (recognizer:UISwipeGestureRecognizer) {
        if recognizer.direction == .right {
            
            toggleMenu(open: true)
            
        }else{
            
            toggleMenu(open: false)
        }
    }
    
    
    
    func closeMenu(){
        
        self.toggleMenu(open: false)
    }
    
    
    
    func toggleMenu (open:Bool) {
        
        animator.removeAllBehaviors()
        
        let gravityX:CGFloat = open ? 8 : -8
        let pushMagnitude:CGFloat = open ? 100 : -100
        let boundaryX:CGFloat = open ? menuWidth : -menuWidth - 5
        
        let gravity = UIGravityBehavior(items: [self])
        gravity.gravityDirection = CGVector(dx: gravityX, dy: 0)
        animator.addBehavior(gravity)
        
        let collision = UICollisionBehavior(items: [self])
        collision.addBoundary(withIdentifier: 1 as NSCopying, from: CGPoint(x: boundaryX, y:0), to: CGPoint(x: boundaryX, y: parentViewController.view.bounds.height))
        animator.addBehavior(collision)
        
        let push = UIPushBehavior(items: [self], mode: .instantaneous)
        push.magnitude = pushMagnitude
        animator.addBehavior(push)
        
        let menuBehaviour = UIDynamicItemBehavior(items: [self])
        menuBehaviour.elasticity = 0.0
        animator.addBehavior(menuBehaviour)
        
        UIView.animate(withDuration: 0.2) { 
            self.backgroundView.alpha = open ? 0.85 : 0
        }
    }
    
    
    
    /******************************
     *
     *  ---- SETUP UI METHODS ----
     *
     *  - search bar
     *  - my profile view/button
     *  - menu table
     *
     *****************************/
    
    
    
    func setupSearchBar(){
        
        searchBar = UISearchBar(frame: CGRect(x: self.bounds.minX, y:self.bounds.minY + 20, width:menuWidth, height: 50.0))
        searchBar.backgroundColor = uiStyles.getSearchBarBackgroungColor()
        searchBar.barTintColor = uiStyles.getSearchBarBackgroungColor()
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search"
        searchBar.setTextColor(color: .white)
        searchBar.setTextFieldColor(color: uiStyles.getSearchBarColor())
        searchBar.setPlaceholderTextColor(color: .white)
        searchBar.setSearchImageColor(color: .white)
        searchBar.setTextFieldClearButtonColor(color: .white)
        
    }
    
    
    
    func setupProfileView(){

        let padding:CGFloat = 5.0
        
        
        let profilePicture = UIImageView(frame: CGRect(x: profileView.bounds.minX + 4*padding,y:profileView.bounds.minY + (profileView.bounds.height/4), width: profileView.bounds.height/2,height:profileView.bounds.height/2))
        
        profilePicture.image = UIImage(named: "clearPlaceholderImage")

        //SETTINGS DEMO PROFILE PIC
        profilePicture.image = UIImage(named: "demoProfilePic1")
        
        //image Caching for when initial profile picture upload method is complete
//        self.imageCache.getImage(urlString: loggedInUser.profilePhoto, completion: { image in
//            
//            profilePicture.image = image
//        })
        
        profilePicture.contentMode = .scaleAspectFill
        profilePicture.clipsToBounds = true
        profilePicture.layer.cornerRadius = profilePicture.frame.height/2
        
        let nameLbl = UILabel(frame: CGRect(x: profilePicture.frame.maxX + 2*padding, y:profilePicture.frame.minY, width: profileView.bounds.width / 2, height:profilePicture.bounds.height / 2))
        nameLbl.text = self.loggedInUser.name! as String
        nameLbl.textColor = UIColor.white
        nameLbl.font = UIFont.boldSystemFont(ofSize: 16.0)
        
        let profileLbl = UILabel(frame: CGRect(x: profilePicture.frame.maxX + 2*padding,y:profilePicture.frame.midY, width: profileView.bounds.width / 2, height:profilePicture.bounds.height / 2))
        profileLbl.text = "My Profile"
        profileLbl.textColor = UIColor.white
        profileLbl.font = UIFont.boldSystemFont(ofSize: 12.0)
        
        let arrowImage = UIImageView(frame: CGRect(x: profileView.bounds.maxX - 25, y:profileView.bounds.minY + profileView.bounds.height / 4 + profileView.bounds.height / 8 , width: 20,height:profileView.bounds.height/4))
        
        let image: UIImage = UIImage.init(named: "chevron")!
        arrowImage.image = image.transform(withNewColor: .white)
        arrowImage.alpha = 1.0
        
        self.profileView.addSubview(profilePicture)
        self.profileView.addSubview(profileLbl)
        self.profileView.addSubview(nameLbl)
        self.profileView.addSubview(arrowImage)
        
        
    }
    

    
    func setupMenuView () {
        
        self.setupSearchBar()
        

        backgroundView = UIView(frame: parentViewController.view.bounds)
        backgroundView.backgroundColor = UIColor.white
        backgroundView.alpha = 0
        
        parentViewController.view.insertSubview(backgroundView, belowSubview: self)
        
        self.addSubview(searchBar)
        
        let profileFrame: CGRect = CGRect(x: self.bounds.minX,y: self.searchBar.frame.maxY, width: self.menuWidth,height: self.frame.height / 8)
        
        profileView = UIView(frame: profileFrame)
//        profileView.backgroundColor = UIColor.white
        
        overlayView = UIView(frame: profileFrame)
        overlayView.layer.backgroundColor = UIColor.white.cgColor
        overlayView.alpha = 0.65
        overlayView.isHidden = true
        
        self.addSubview(profileView)
        self.addSubview(overlayView)
        
        menuTable = UITableView(frame: CGRect(x:self.bounds.minX, y:self.profileView.frame.maxY, width: menuWidth, height:self.bounds.height - (searchBar.bounds.height + profileView.bounds.height )), style: .plain)
        
        menuTable.backgroundColor = uiStyles.getMenuColor()
        menuTable.separatorStyle = .none
        menuTable.isScrollEnabled = false
        menuTable.alpha = 1
        
        menuTable.delegate = self
        menuTable.dataSource = self
        menuTable.reloadData()

        self.setupProfileView()
        self.addSubview(menuTable)
        
    }


    
    
    /***************************************
     *
     * ---- TABLE VIEW DELEGATE MEHTODS ---
     *
     **************************************/
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItemTitles.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "Cell")
        
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        }
        
        cell?.textLabel?.text = menuItemTitles[indexPath.row].rawValue
        cell?.textLabel?.textColor = UIColor.white
        cell?.textLabel?.font = UIFont(name: "Avenir-Next", size: 13)
        cell?.textLabel?.textAlignment = .left
        
        cell?.backgroundColor = UIColor.clear
        
        var cellImage: UIImage!
        
        switch menuItemTitles[indexPath.row] {
            
        case .home:
            cellImage = UIImage.init(named: "home")
            
        case .messages:
            
            let viewSize:CGFloat = 20
            
             cellImage = UIImage.init(named: "mail")
            
            let circleFrame: CGRect = CGRect(x:self.bounds.maxX - viewSize, y: self.bounds.midY - viewSize/2, width:viewSize,height:viewSize)
            
            
            let whiteCircle: UIView = UIView(frame:circleFrame)
            
            let labelFrame: CGRect = CGRect(x:whiteCircle.bounds.minX, y: whiteCircle.bounds.minY, width:viewSize,height:viewSize)
            
            whiteCircle.layer.cornerRadius = viewSize/2
            whiteCircle.clipsToBounds = true
            whiteCircle.backgroundColor = UIColor.white
            
            let numberLbl: UILabel = UILabel(frame: labelFrame)
            numberLbl.backgroundColor = UIColor.clear
            numberLbl.textColor = uiStyles.getMenuColor()
            numberLbl.textAlignment = .center
            numberLbl.text = "5"
            
            whiteCircle.addSubview(numberLbl)
            
            cell?.accessoryView = whiteCircle
        
            
        default:
            //default is case: .discover
            cellImage = UIImage.init(named: "users")
        }
        
        
        cellImage = cellImage.transform(withNewColor: .white)
        cell?.imageView?.image = cellImage
        cell?.backgroundColor = UIColor.clear
        
        
        return cell!
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.cellForRow(at: indexPath)?.setSelected(false, animated: true)
        
        if let delegate = menuDelegate {
            
            delegate.didSelectMenuItem(withTitle: menuItemTitles[indexPath.row].rawValue, index: indexPath.row)
        }
        
    }
    
    
    /**************************************************
     *
     * ------------- TOUCH DELEGATE METHODS ------------
     *
     * used for overlays on touch and profile navigation
     *
     **************************************************/
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let touch = touches.first {
            
            let point = touch.preciseLocation(in: self)
            
            if (self.profileView.frame.contains(point)){
            
                showOverlay()
                
            }
          
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let lastTouch = touches.reversed()
        removeOverlay()
        
        if let touch = lastTouch.first{
            
            let point = touch.preciseLocation(in: self)
            
            if (self.profileView.frame.contains(point)){
                
                if let delegate = menuDelegate {
                    delegate.didSelectProfile()
                }
            }
        }
    }
    
    
    func showOverlay(){
        print("Showing Overlay")
        overlayView.isHidden = false
        
    }
    
    
    func removeOverlay(){
        
        print("Removing Overlay")
        overlayView.isHidden = true
        
    }
    
    
    
    
    /*****************************************
     *
     * ------------- NAVIGATION -------------
     *
     *****************************************/
    

}


/******************************************************************************************************************
 *
 *      SEARCH BAR CUSTOMIZATION EXTENSIONS
 *
 * Note: I'm not sure if we are able to manipulate Apple API's this way. If not There are a few open source pods
 *       we could look into using like githubs' Busta117/SBSearchBar to get the color scheme we need
 *
 *******************************************************************************************************************/

extension UISearchBar {
    
    private func getViewElement<T>(type: T.Type) -> T? {
        
        let svs = subviews.flatMap { $0.subviews }
        guard let element = (svs.filter { $0 is T }).first as? T else { return nil }
        return element
    }
    
    func getSearchBarTextField() -> UITextField? {
        
        return getViewElement(type: UITextField.self)
    }
    
    func setTextColor(color: UIColor) {
        
        if let textField = getSearchBarTextField() {
            textField.textColor = color
        }
    }
    
    func setTextFieldColor(color: UIColor) {
        
        if let textField = getViewElement(type: UITextField.self) {
            switch searchBarStyle {
            case .minimal:
                textField.layer.backgroundColor = color.cgColor
                textField.layer.cornerRadius = 6
                
            case .prominent, .default:
                textField.backgroundColor = color
            }
        }
    }
    
    func setPlaceholderTextColor(color: UIColor) {
        
        if let textField = getSearchBarTextField() {
            textField.attributedPlaceholder = NSAttributedString(string: self.placeholder != nil ? self.placeholder! : "", attributes: [NSForegroundColorAttributeName: color])
        }
    }
    
    func setTextFieldClearButtonColor(color: UIColor) {
        
        if let textField = getSearchBarTextField() {
            
            let button = textField.value(forKey: "clearButton") as! UIButton
            if let image = button.imageView?.image {
                button.setImage(image.transform(withNewColor: color), for: .normal)
            }
        }
    }
    
    func setSearchImageColor(color: UIColor) {
        
        if let imageView = getSearchBarTextField()?.leftView as? UIImageView {
            imageView.image = imageView.image?.transform(withNewColor: color)
        }
        
    }
}



//extension UIImage {
//    
//    func transform(withNewColor color: UIColor) -> UIImage {
//        
//        UIGraphicsBeginImageContextWithOptions(size, false, scale)
//        
//        let context = UIGraphicsGetCurrentContext()!
//        context.translateBy(x: 0, y: size.height)
//        context.scaleBy(x: 1.0, y: -1.0)
//        context.setBlendMode(.normal)
//        
//        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
//        context.clip(to: rect, mask: cgImage!)
//        
//        color.setFill()
//        context.fill(rect)
//        
//        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
//        UIGraphicsEndImageContext()
//        return newImage
//    }
//}


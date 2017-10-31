//
//  CommentViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 9/26/17.
//
//

import UIKit
import Firebase

class CommentViewController: UIViewController, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate{

    
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var alphaView: UIView!
    @IBOutlet weak var addCommentTextView: UITextView!
    
    @IBOutlet weak var noCommentsLbl: UILabel!
    @IBOutlet weak var postBtn: UIButton!
    @IBOutlet weak var keyboardHeightLayoutConstraint: NSLayoutConstraint!
    
    var dataManager: DataManager = DataManager()
    var commentData: NSDictionary!
    var viewingUserId: String = ""
    var commentsArray: NSMutableArray = NSMutableArray()
    var currentUserData: User!
    var placeholderText: String = "Say something..."
    var pickHeight: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Keyboard Observer
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardNotification(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        
//        let panGesture: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
//        self.view.addGestureRecognizer(panGesture)
//        panGesture.minimumNumberOfTouches = 1
//        panGesture.delegate = self
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.addCommentTextView.text = placeholderText
        self.addCommentTextView.delegate = self
        
        self.contentView.backgroundColor = UIColor.clear
        self.contentView.clipsToBounds = false
        
        self.viewSetup()
        self.getMyUserData()
        self.setCommentData()
        
        self.tableView.tableFooterView =  UIView.init(frame:CGRect(x:0, y:0, width:self.tableView.frame.size.width, height:1))
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 140
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)

        self.alphaView.frame.size = CGSize(width: self.view.frame.size.width * 3.0 , height: self.view.frame.size.height * 3.0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    func viewSetup(){
        
        self.popupView.layer.cornerRadius = 8.0
        self.popupView.layer.masksToBounds = false
        self.popupView.layer.shadowColor = UIColor.black.cgColor
        self.popupView.layer.shadowOpacity = 0.3
        self.popupView.layer.shadowRadius = 5
        self.popupView.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.popupView.layer.shadowPath = UIBezierPath(rect: self.popupView.bounds).cgPath
        
        self.addCommentTextView.clipsToBounds = true
        self.addCommentTextView.layer.borderWidth = 1.0
        self.addCommentTextView.layer.borderColor = UIColor.lightGray.cgColor
        self.addCommentTextView.layer.cornerRadius = 5.0
    }
    
    
    func getMyUserData(){
        
        dataManager.getUserDataFrom(uid: (Auth.auth().currentUser?.uid)!) { (user) in
            self.currentUserData = user
            
        }
    }
    
    
    func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let duration:TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            if (endFrame?.origin.y)! >= UIScreen.main.bounds.size.height {
                self.keyboardHeightLayoutConstraint?.constant = 0.0
            } else {
                self.keyboardHeightLayoutConstraint?.constant = endFrame?.size.height ?? 0.0
            }
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: { self.view.layoutIfNeeded() },
                           completion: nil)
        }
    }
    
    func setCommentData(){
        
        if self.commentData != nil{
            
            for key in commentData.allKeys{
                commentsArray.add(commentData.value(forKey: key as! String) as! NSDictionary)
            }
            self.tableView.reloadData()
        }else{
            
            
            self.dataManager.getCommentDataFromFirebase(uid: self.viewingUserId, completion: { (snapshot) in
                
                self.commentData = snapshot

                for key in self.commentData.allKeys{
                    self.commentsArray.add(self.commentData.value(forKey: key as! String) as! NSDictionary)
                }
                
                self.tableView.reloadData()
            })
        }
    }
    
    
    
    
    //Transition away from comments view
    @IBAction func minimizeAction(_ sender: Any) {
        
        UIView.animate(withDuration: 0.3, animations: {
            self.view.transform = CGAffineTransform(translationX: 0, y: 100)
            self.view.alpha = 0.0  
        }) { (success) in
            
            self.performSegue(withIdentifier: "unwindToPostView", sender: self)
        }
    }

    
    
    
    
    @IBAction func postAction(_ sender: Any) {
        
        
        if (self.addCommentTextView.text != "" && self.addCommentTextView.text != "Say something..."){
            //if the user has entered text other an the placeholder text or nothing
            
            let comment = self.addCommentTextView.text
            var commentorUid = ""
            var username = ""
            let created = String(format:"%.0f",dataManager.nowInMillis())
            
            if currentUserData != nil{
                commentorUid = currentUserData.userID
                username = currentUserData.username
            }
            
            let newCommentDict:NSMutableDictionary = ["comment":comment ?? "", "username":username, "commentorUid":commentorUid, "created":created]
            
            dataManager.writeCommentData(threadId: self.viewingUserId, commentorUid: commentorUid, comment: comment!, created: created, username: username)
            
            self.commentsArray.add(newCommentDict)
            self.addCommentTextView.text = ""
            self.addCommentTextView.resignFirstResponder()
            self.tableView.reloadData()
        }
        
    }
    
    
    @IBAction func closeBtnAction(_ sender: Any) {
        
        self.willMove(toParentViewController: nil)
        self.view.removeFromSuperview()
        self.removeFromParentViewController()
    }
    
    
    //PAN GESTURE
    func handlePanGesture(panGesture: UIPanGestureRecognizer){
        
        // get translation
        let translation = panGesture.translation(in: self.view)
        panGesture.setTranslation(CGPoint.zero, in: self.view)
        
        let xVel = panGesture.velocity(in: self.view).x
        let yVel = panGesture.velocity(in: self.view).y
        
        print(translation)
        
        if panGesture.state == UIGestureRecognizerState.began {
            // add something you want to happen when the Label Panning has started
            self.popupView.center = self.view.center
        }
        
        if panGesture.state == UIGestureRecognizerState.ended {
            // add something you want to happen when the Label Panning has ended
            
            if (xVel > 1000 || yVel > 1000 || sqrt(xVel * xVel + yVel * yVel) > 1000){
                
                UIView.animate(withDuration: 0.1, animations: {
                    
                    self.popupView.transform = CGAffineTransform(translationX: xVel/2, y: yVel/2)
                    
                }){ (success) in
                    if success{
                        self.willMove(toParentViewController: nil)
                        self.view.removeFromSuperview()
                        self.removeFromParentViewController()
                    }
                }
            }else{
                UIView.animate(withDuration: 0.1, animations: {
                    
                    self.view.center = (self.parent!.view.center)
                })
            }
        }
        
        if panGesture.state == UIGestureRecognizerState.changed {
            
            // add something you want to happen when the Label Panning has been change ( during the moving/panning )
            self.view.center = CGPoint(x:self.view.center.x + translation.x, y: self.view.center.y + translation.y)
            
        } else {
            // or something when its not moving
        }
    }

    
    func findHeightForText(text: String, havingWidth widthValue: CGFloat, andFont font: UIFont) -> CGFloat {
        var size = CGSize.zero
        if text.isEmpty == false {
            let frame = text.boundingRect(with: CGSize(width: widthValue, height:CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
            size = CGSize(width:frame.size.width, height:ceil(frame.size.height))
        }
        return size.height
    }
    
//    func heightForView(text:NSAttributedString, font:UIFont, width:CGFloat) -> CGFloat{
//        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
//        label.numberOfLines = 0
//        label.lineBreakMode = NSLineBreakMode.byWordWrapping
//        label.font = font
//        label.attributedText = text
//        label.sizeToFit()
//        
//        return label.frame.height
//    }
//    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if commentsArray.count == 0{
            self.noCommentsLbl.isHidden = false
        }else{
            self.noCommentsLbl.isHidden = true
        }
        
        return self.commentsArray.count
    }
    
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        
//        let cell: CommentTableViewCell = tableView.dequeueReusableCell(withIdentifier: "commentCell") as! CommentTableViewCell
        
        let data: NSDictionary = self.commentsArray[indexPath.row] as! NSDictionary
        let text = getAttributedCellText(username: data.value(forKey: "username") as! String, comment: data.value(forKey: "comment") as! String)
//
        let height: CGFloat = findHeightForText(text: text.string, havingWidth: self.popupView.frame.width - 40, andFont: UIFont.systemFont(ofSize: 14.0))
        
//
//        cell.commentlbl.frame = cell.contentView.frame
//        print(String(format:"cell height %f",height))
        return height
        
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: CommentTableViewCell = tableView.dequeueReusableCell(withIdentifier: "commentCell") as! CommentTableViewCell
        
        cell.commentlbl.numberOfLines = 0;
        cell.commentlbl.lineBreakMode = NSLineBreakMode.byWordWrapping
        let commentDict:NSDictionary = self.commentsArray[indexPath.row] as! NSDictionary
        let username: String = commentDict.value(forKey: "username") as! String
        let comment: String = commentDict.value(forKey: "comment") as! String
        
        cell.commentlbl.attributedText = getAttributedCellText(username: username, comment: comment)
        
        
        print(String(format:"Label height %f",cell.commentlbl.frame.height))
        print(String(format:"Cell Content height %f",cell.contentView.frame.height))
        
        return cell
    }
    
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    
    func getAttributedCellText(username: String, comment: String) -> NSAttributedString{
        
        let fullString = String(format:"%@ : %@",username, comment)
        
        //Use Attributed text to bold the username
        let attributedString = NSMutableAttributedString(string: fullString, attributes: [NSFontAttributeName:UIFont.systemFont(ofSize: 14.0)])
        let boldFontAttribute = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14.0)]
        
        attributedString.addAttributes(boldFontAttribute, range: NSMakeRange(0, username.characters.count + 2))
        
        return attributedString
    }
    
    
    
    

    
    
    /***********************************
     *
     * ------ TEXTView DELEGATES -----
     *
     ***********************************/
    
    
    
    func textViewDidBeginEditing(_ textView: UITextView){
        
        
        if(textView.text == self.placeholderText){
            textView.text = ""
            textView.textColor = UIColor.black
        }
    }
    
    
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        if(textView.text == ""){
            textView.text = self.placeholderText
            textView.textColor = UIColor.lightGray
        }
        
        let currentWidth: CGFloat = self.addCommentTextView.bounds.width
        
        self.addCommentTextView.frame.size = CGSize (width: self.popupView.frame.width - postBtn.frame.width, height: 30)
        self.addCommentTextView.center = CGPoint(x: self.popupView.bounds.minX + currentWidth/2,y: self.popupView.frame.height - self.addCommentTextView.frame.height/2)
    }
    

    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if(text == "\n")
        {
            self.addCommentTextView.resignFirstResponder
            self.addCommentTextView.endEditing(true)
            return false
        }
        
        return true
    }
    
    
    func textViewDidChange(_ textView: UITextView) {
        let numLines: Int = Int(textView.contentSize.height / textView.font!.lineHeight);
        
        if numLines > 1{
        
            self.adjustUITextViewHeight(arg: textView)
            self.addCommentTextView.center = CGPoint(x: self.addCommentTextView.center.x,y: self.popupView.frame.height - keyboardHeightLayoutConstraint.constant - self.addCommentTextView.frame.height/2)
        }else {
            textView.isScrollEnabled = true
        }
    }
    
    
    func adjustUITextViewHeight(arg : UITextView)
    {
        
        let fixedWidth = arg.frame.size.width
        arg.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        let newSize = arg.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        var newFrame = arg.frame
        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        arg.frame = newFrame
        //        arg.translatesAutoresizingMaskIntoConstraints = true
        //        arg.sizeToFit()
        //        arg.isScrollEnabled = false
    }
    




}

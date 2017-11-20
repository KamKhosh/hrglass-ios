//
//  MessagesViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 7/31/17.
//
//

import UIKit
import Firebase

class MessagesViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UITextViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var loggedInUser: User!
    var messages: NSMutableArray = NSMutableArray()
    var selectedUserId: String!
    var colors: Colors = Colors()
    var nameString: String = ""
    
    @IBOutlet weak var nameLbl: UILabel!
    var parentView: String = "feed"
    
    let placeholderText: String = "Type Message..."
    
    var dataManager: DataManager = DataManager()
    
    @IBOutlet weak var messageTextView: UITextView!
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    @IBOutlet weak var collectionView: UICollectionView!

    @IBOutlet weak var sendBtn: UIButton!
    
    @IBOutlet weak var keyboardHeightLayoutConstraint: NSLayoutConstraint!
    
    var messagesId: String = ""
    
    
    /*******************************************
     *
     * -------------- LIFECYCLE
     *
     *******************************************/
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Keyboard Observer
         NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardNotification(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        
        self.messageTextView.textColor = UIColor(white: 0.0, alpha: 0.7)
        self.messageTextView.tintColor = UIColor.white
        self.messageTextView.text = self.placeholderText
        self.messageTextView.layer.borderColor = UIColor.white.cgColor
        self.messageTextView.layer.borderWidth = 0.5
        self.messageTextView.layer.cornerRadius = 3.0
        
        self.nameLbl.text = nameString
        
        self.messageTextView.delegate = self
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        
        //when coming from the Feed view, messagesId will need to be obtained from Firebae. messageId will already be set when coming from the inbox view
        if messagesId == ""{
            
            self.getMessageThreadId()
        }else{
            
            getMessages()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    @objc func keyboardNotification(notification: NSNotification) {
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
    
    
    
    /*******************************************
     *
     * ---------- MESSAGE METHODS -----------
     *
     *******************************************/
    
    
    func getMessageThreadId(){
        
        let myUid: String = (Auth.auth().currentUser?.uid)!
        let inboxRef: DatabaseReference = Database.database().reference().child("Inbox").child(myUid).child(self.selectedUserId).child("objectId")
        
        inboxRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let id: String = snapshot.value as? String{
                
                self.messagesId = id
                self.getMessages()
            }
        })
    }
    

    
    func getMessages(){
        
        let messagesRef: DatabaseReference = Database.database().reference().child("Messages").child(messagesId)
        
        messagesRef.observe(.childAdded, with: { (snapshot) in
            
            if let message: NSDictionary = snapshot.value as? NSDictionary{
                
                self.messages.add(message)
                
                self.collectionView.reloadData()
                
            }
            
            let lastIndex: IndexPath = IndexPath(item: self.messages.count - 1, section: 0)
            self.collectionView.scrollToItem(at:lastIndex , at: UICollectionViewScrollPosition.bottom, animated: true)
        })
    }
    
    
    
    
    //will create a new inbox entry/Messages Thread if the receipient is new or just send the message to an existing user in the inbox
    @IBAction func sendBtnAction(_ sender: Any) {
        
        //make sure user has entered text before sending
        if (self.messageTextView.text != "" || self.messageTextView.text != self.placeholderText){
            
            let uid: String = (Auth.auth().currentUser?.uid)!
            let body: String = self.messageTextView.text!
            let createdTime: String = String(format:"%.0f", Date().timeIntervalSince1970)
            let messageData: NSMutableDictionary = NSMutableDictionary()
            
            messageData.setValue(uid, forKey: "sender")
            messageData.setValue(self.selectedUserId, forKey: "receiver")
            messageData.setValue(body, forKey:"body")
            messageData.setValue(createdTime, forKey: "created")
            
            if messagesId == ""{
                //create new Id and
                dataManager.updateInboxList(withUid: self.selectedUserId, forUser: self.loggedInUser, completion: { (convoId) in
                    
                    self.messagesId = convoId as String
                    self.postMessage(messageData: messageData)
                })
            }else{
                
                postMessage(messageData: messageData)
            }
        }
    }
    
    
    func postMessage(messageData: NSDictionary){
        
        let objectId: String = messageData.value(forKey: "created") as! String
        
        let messagesRef: DatabaseReference = Database.database().reference().child("Messages").child(self.messagesId).child(objectId)
        
        messagesRef.setValue(messageData)
        
        self.messageTextView.text = ""
        self.messageTextView.resignFirstResponder()
        self.messageTextView.endEditing(true)
        self.collectionView.reloadData()
    }
    
    
    
    
    /***********************************
     *
     * --- COLLECTION VIEW DELEGATES ---
     *
     ***********************************/
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
        var cell: MessageCollectionViewCell = MessageCollectionViewCell()
        
        let messageData: NSDictionary = self.messages[indexPath.row] as! NSDictionary
        let myUid = Auth.auth().currentUser?.uid
        
        let text = messageData.value(forKey: "body") as! String
        let radius: CGFloat = 13.0

        
        if (messageData.value(forKey: "sender") as? String == myUid){
            
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "messageCellRight", for: indexPath) as! MessageCollectionViewCell
            
            cell.textView.backgroundColor = colors.getMenuColor()
            cell.textView.textColor = UIColor.white
            cell.textView.clipsToBounds = true
            cell.textView.layer.cornerRadius = radius
            cell.textView.text = text
            

        }else{
            
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "messageCellLeft", for: indexPath) as! MessageCollectionViewCell
            
            cell.textView.backgroundColor = UIColor.lightGray
            cell.textView.textColor = UIColor.black
            cell.textView.clipsToBounds = true
            cell.textView.layer.cornerRadius = radius
            cell.textView.text = text
        }
        
        return cell
    }
    
    
    func collectionView(_ collectionView : UICollectionView,layout collectionViewLayout:UICollectionViewLayout,sizeForItemAt indexPath:IndexPath) -> CGSize
    {
        
        let messageData: NSDictionary = self.messages[indexPath.row] as! NSDictionary

        let width: CGFloat = self.collectionView.frame.width * 3/4
        let text = messageData.value(forKey: "body") as! String
        
        let height: CGFloat = self.calculateHeight(inString: text, withWidth: width)
        
        let size: CGSize = CGSize(width: self.collectionView.frame.width, height: height + 15)
        //adjust height of cell based on text
        
        return size
        
    }
    
    
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    

    func calculateHeight(inString:String, withWidth: CGFloat) -> CGFloat {
        let messageString = inString
        let attributes : [NSAttributedStringKey : Any] = [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 20.0)]
        
        let attributedString : NSAttributedString = NSAttributedString(string: messageString, attributes: attributes)
        
        let rect : CGRect = attributedString.boundingRect(with: CGSize(width: withWidth, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
        
        let requredSize:CGRect = rect
        return requredSize.height
    }
    
    
    /***********************************
     *
     * ------ TEXTView DELEGATES -----
     *
     ***********************************/
    
    
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        let lastIndex: IndexPath = IndexPath(item: self.messages.count - 1, section: 0)
        
        self.collectionView.scrollToItem(at:lastIndex , at: UICollectionViewScrollPosition.bottom, animated: true)
//        let numLines: Int = Int(textView.contentSize.height / textView.font!.lineHeight);
        
//        if numLines > 1{
//            self.adjustUITextViewHeight(arg: textView)
//           self.messageTextView.center = CGPoint(x: self.view.center.x - sendBtn.frame.width/2,y: self.view.frame.height - keyboardHeightLayoutConstraint.constant - self.messageTextView.frame.height/2)
        
//        }
        
//        self.adjustUITextViewHeight(arg: textView)
        
        
        if(textView.text == self.placeholderText){
            textView.text = ""
            textView.textColor = UIColor.white
        }
    }
    
    
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        if(textView.text == ""){
            textView.text = self.placeholderText
            textView.textColor = UIColor.black
        }
        
        self.messageTextView.frame.size = CGSize (width: self.view.frame.width - sendBtn.frame.width, height: 40)
        self.messageTextView.center = CGPoint(x: self.view.center.x - sendBtn.frame.width/2,y: self.view.frame.height - self.messageTextView.frame.height/2)
    }

    
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
            if(text == "\n")
            {
                self.messageTextView.resignFirstResponder
                self.messageTextView.endEditing(true)
                return false
            }
            
            return true
    }
    

    func textViewDidChange(_ textView: UITextView) {
        let numLines: Int = Int(textView.contentSize.height / textView.font!.lineHeight);
        
        if numLines > 1{
            self.adjustUITextViewHeight(arg: textView)
            self.messageTextView.center = CGPoint(x: self.view.center.x - sendBtn.frame.width/2,y: self.view.frame.height - keyboardHeightLayoutConstraint.constant - self.messageTextView.frame.height/2)
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
    
    

    

    
    /*******************************************
     *
     * -------- ACTIONS ------------
     *
     *******************************************/
    
    
    @IBAction func closeBtnAction(_ sender: Any) {
        
        //remove observer for messages thread
        if self.messagesId != ""{
            Database.database().reference().child("Messages").child(messagesId).removeAllObservers()
        }
        
        if(self.parentView == "feed"){
            
            self.performSegue(withIdentifier: "unwindToFeed", sender: nil)
       
        }else if (self.parentView == "inbox"){
            
            self.performSegue(withIdentifier: "unwindToInbox", sender: nil)
        }
    }
    
    
    
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    

}

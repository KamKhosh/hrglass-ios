//
//  MoodViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 12/16/17.
//

import UIKit

class MoodViewController: UIViewController {
    
    //mood menu options
    var moodMenuIsOpen: Bool = false
    var moodArrayOutside: [UIButton] = [UIButton]()
    var moodArrayInside: [UIButton] = [UIButton]()
    var imageCache: ImageCache = ImageCache()
    
    var selectedObject: AnyObject!
    var selectedCategory: Category = .None
    var selectedMood: Mood = .None
    var selectedThumbnail: UIImage!
    var selectedVideoPath: String = ""
    var selectedMusicItem: String!
    
    
    //set when music is the primary and as an embellishement
    var loggedInUser: User!
    var postWasSaved: Bool = false
    
    @IBOutlet weak var moodBtn: UIButton!
    
    @IBOutlet weak var nextBtn: UIButton!
    @IBOutlet weak var navigationView: UIView!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setupMoodMenu()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.showMoodMenu()
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "toSubmitPostSegue"{
            
            let vc: SubmitPostViewController = segue.destination as! SubmitPostViewController
            vc.selectedMood = self.selectedMood
            vc.selectedObject = self.selectedObject
            vc.selectedCategory = self.selectedCategory
            vc.loggedInUser = self.loggedInUser
            vc.selectedVideoPath = self.selectedVideoPath
            vc.selectedThumbnail = self.selectedThumbnail
            vc.postWasSaved = self.postWasSaved
            vc.selectedMusicItem = self.selectedMusicItem
            vc.imageCache = self.imageCache
        }
    }
 
    
    @IBAction func unwindToMoodSegue(unwindSegue: UIStoryboardSegue) {
        
    }
    
    
    /***********************
     *
     * Mood Button METHODS
     *
     **********************/
    
    func setupMoodMenu(){
        
        let center = self.moodBtn.center
//        moodBtn.setTitle(self.selectedMood.rawValue, for: .normal)
        
        let angry1: UIButton = UIButton(frame: CGRect.zero)
        let angry2: UIButton = UIButton(frame: CGRect.zero)
        let confused1: UIButton = UIButton(frame: CGRect.zero)
        let confused2: UIButton = UIButton(frame: CGRect.zero)
        let crying1: UIButton = UIButton(frame: CGRect.zero)
        let crying2: UIButton = UIButton(frame: CGRect.zero)
        let happy1: UIButton = UIButton(frame: CGRect.zero)
        let happy2: UIButton = UIButton(frame: CGRect.zero)
        let happy3: UIButton = UIButton(frame: CGRect.zero)
        let happy4: UIButton = UIButton(frame: CGRect.zero)
        let ill: UIButton = UIButton(frame: CGRect.zero)
        let inLove: UIButton = UIButton(frame: CGRect.zero)
        let kissing: UIButton = UIButton(frame: CGRect.zero)
        let mad: UIButton = UIButton(frame: CGRect.zero)
        let nerd: UIButton = UIButton(frame: CGRect.zero)
        let ninja: UIButton = UIButton(frame: CGRect.zero)
        let quiet: UIButton = UIButton(frame: CGRect.zero)
        let sad: UIButton = UIButton(frame: CGRect.zero)
        let smart: UIButton = UIButton(frame: CGRect.zero)
        let smile: UIButton = UIButton(frame: CGRect.zero)
        let smiling: UIButton = UIButton(frame: CGRect.zero)
        let surprised1: UIButton = UIButton(frame: CGRect.zero)
        let surprised2: UIButton = UIButton(frame: CGRect.zero)
        let suspicious1: UIButton = UIButton(frame: CGRect.zero)
        let suspicious2: UIButton = UIButton(frame: CGRect.zero)
        let tongueOut: UIButton = UIButton(frame: CGRect.zero)
        let unhappy: UIButton = UIButton(frame: CGRect.zero)
        let wink: UIButton = UIButton(frame: CGRect.zero)
        let noneBtn: UIButton = UIButton(frame: CGRect.zero)
        
        angry1.setImage(UIImage(named: Mood.Angry1.rawValue), for: .normal)
        angry2.setImage(UIImage(named: Mood.Angry2.rawValue), for: .normal)
        confused1.setImage(UIImage(named: Mood.Confused1.rawValue), for: .normal)
        confused2.setImage(UIImage(named: Mood.Confused2.rawValue), for: .normal)
        crying1.setImage(UIImage(named: Mood.Crying1.rawValue), for: .normal)
        crying2.setImage(UIImage(named: Mood.Crying2.rawValue), for: .normal)
        happy1.setImage(UIImage(named: Mood.Happy1.rawValue), for: .normal)
        happy2.setImage(UIImage(named: Mood.Happy2.rawValue), for: .normal)
        happy3.setImage(UIImage(named: Mood.Happy3.rawValue), for: .normal)
        happy4.setImage(UIImage(named: Mood.Happy4.rawValue), for: .normal)
        
        ill.setImage(UIImage(named: Mood.Ill.rawValue), for: .normal)
        inLove.setImage(UIImage(named: Mood.InLove.rawValue), for: .normal)
        kissing.setImage(UIImage(named: Mood.Kissing.rawValue), for: .normal)
        mad.setImage(UIImage(named: Mood.Mad.rawValue), for: .normal)
        nerd.setImage(UIImage(named: Mood.Nerd.rawValue), for: .normal)
        ninja.setImage(UIImage(named: Mood.Ninja.rawValue), for: .normal)
        quiet.setImage(UIImage(named: Mood.Quiet.rawValue), for: .normal)
        sad.setImage(UIImage(named: Mood.Sad.rawValue), for: .normal)
        smart.setImage(UIImage(named: Mood.Smart.rawValue), for: .normal)
        smile.setImage(UIImage(named: Mood.Smile.rawValue), for: .normal)
        smiling.setImage(UIImage(named: Mood.Smiling.rawValue), for: .normal)
        surprised1.setImage(UIImage(named: Mood.Surprised1.rawValue), for: .normal)
        surprised2.setImage(UIImage(named: Mood.Surprised2.rawValue), for: .normal)
        suspicious1.setImage(UIImage(named: Mood.Suspicious1.rawValue), for: .normal)
        suspicious2.setImage(UIImage(named: Mood.Suspicious2.rawValue), for: .normal)
        tongueOut.setImage(UIImage(named: Mood.TongueOut.rawValue), for: .normal)
        unhappy.setImage(UIImage(named: Mood.Unhappy.rawValue), for: .normal)
        wink.setImage(UIImage(named: Mood.Wink.rawValue), for: .normal)
        noneBtn.setImage(UIImage(named: Mood.None.rawValue), for: .normal)
        
        
        
        angry1.center = center
        angry2.center = center
        confused1.center = center
        confused2.center = center
        crying1.center = center
        crying2.center = center
        happy1.center = center
        happy2.center = center
        happy3.center = center
        happy4.center = center
        ill.center = center
        inLove.center = center
        kissing.center = center
        mad.center = center
        nerd.center = center
        ninja.center = center
        quiet.center = center
        sad.center = center
        smart.center = center
        smile.center = center
        smiling.center = center
        surprised1.center = center
        surprised2.center = center
        suspicious1.center = center
        suspicious2.center = center
        tongueOut.center = center
        unhappy.center = center
        wink.center = center
        noneBtn.center = center

        
        noneBtn.tag = 0
        angry1.tag = 1
        angry2.tag = 2
        confused1.tag = 3
        confused2.tag = 4
        crying1.tag = 5
        crying2.tag = 6
        happy1.tag = 7
        happy2.tag = 8
        happy3.tag = 9
        happy4.tag = 10
        surprised1.tag = 11
        surprised2.tag = 12
        suspicious1.tag = 13
        suspicious2.tag = 14
        smile.tag = 15
        
        
        smiling.tag = 1
        ill.tag = 2
        inLove.tag = 3
        kissing.tag = 4
        mad.tag = 5
        nerd.tag = 6
        ninja.tag = 7
        quiet.tag = 8
        sad.tag = 9
        smart.tag = 10
        tongueOut.tag = 11
        unhappy.tag = 12
        wink.tag = 13
        
        
        angry1.addTarget(self, action: #selector(self.angryAction1), for: .touchUpInside)
        angry2.addTarget(self, action: #selector(self.angryAction2), for: .touchUpInside)
        confused1.addTarget(self, action: #selector(self.confusedAction1), for: .touchUpInside)
        confused2.addTarget(self, action: #selector(self.confusedAction2), for: .touchUpInside)
        crying1.addTarget(self, action: #selector(self.cryingAction1), for: .touchUpInside)
        crying2.addTarget(self, action: #selector(self.cryingAction2), for: .touchUpInside)
        happy1.addTarget(self, action: #selector(self.happyAction1), for: .touchUpInside)
        happy2.addTarget(self, action: #selector(self.happyAction2), for: .touchUpInside)
        happy3.addTarget(self, action: #selector(self.happyAction3), for: .touchUpInside)
        happy4.addTarget(self, action: #selector(self.happyAction4), for: .touchUpInside)
        surprised1.addTarget(self, action: #selector(self.surprisedAction1), for: .touchUpInside)
        surprised2.addTarget(self, action: #selector(self.surprisedAction2), for: .touchUpInside)
        suspicious1.addTarget(self, action: #selector(self.suspiciousAction1), for: .touchUpInside)
        suspicious2.addTarget(self, action: #selector(self.suspiciousAction2), for: .touchUpInside)
        smile.addTarget(self, action: #selector(self.smileAction), for: .touchUpInside)
        smiling.addTarget(self, action: #selector(self.smilingAction), for: .touchUpInside)
        
        ill.addTarget(self, action: #selector(self.illAction), for: .touchUpInside)
        inLove.addTarget(self, action: #selector(self.inLoveAction), for: .touchUpInside)
        kissing.addTarget(self, action: #selector(self.kissingAction), for: .touchUpInside)
        mad.addTarget(self, action: #selector(self.madAction), for: .touchUpInside)
        nerd.addTarget(self, action: #selector(self.nerdAction), for: .touchUpInside)
        ninja.addTarget(self, action: #selector(self.ninjaAction), for: .touchUpInside)
        quiet.addTarget(self, action: #selector(self.quietAction), for: .touchUpInside)
        sad.addTarget(self, action: #selector(self.sadAction), for: .touchUpInside)
        smart.addTarget(self, action: #selector(self.smartAction), for: .touchUpInside)
        tongueOut.addTarget(self, action: #selector(self.toungueOutAction), for: .touchUpInside)
        unhappy.addTarget(self, action: #selector(self.unhappyAction), for: .touchUpInside)
        wink.addTarget(self, action: #selector(self.winkAction), for: .touchUpInside)
        
        noneBtn.addTarget(self, action: #selector(self.noneAction), for: .touchUpInside)
        
        
        
        moodArrayOutside = [noneBtn,angry1,angry2,confused1,confused2,crying1,crying2,happy1,happy2,happy3,happy4,surprised1,surprised2,suspicious1,suspicious2,smile,smiling]
        
        
        moodArrayInside = [ill,inLove,kissing,mad,nerd,ninja,quiet,sad,smart,tongueOut,unhappy,wink]
        
        let buttonFrame = CGSize(width: self.view.frame.width/CGFloat(moodArrayOutside.count * 3/5),height:self.view.frame.width/CGFloat(moodArrayOutside.count * 3/5))
        
        
        for button in moodArrayOutside{
            button.frame.size = buttonFrame
            button.isHidden = true
            self.view.addSubview(button)
        }
        
        for button in moodArrayInside{
            
            button.frame.size = buttonFrame
            button.isHidden = true
            self.view.addSubview(button)
        }
    }
    
    
    
    
    
    /***************
     * MOOD ACTIONS
     ***************/
    
    @IBAction func moodBtnAtion(_ sender: Any) {
        //open moodMenu
        if (moodMenuIsOpen){
            self.closeMoodMenu()
        }else{
            
            self.showMoodMenu()
        }
    }
    
    //set mood as afraid emoji
    @objc func angryAction1(){
        
        self.onMoodChosenWith(mood: .Angry1)
    }
    
    //set mood as sad emoji
    @objc func angryAction2(){
        self.onMoodChosenWith(mood: .Angry2)
    }
    
    //set mood as funny emoji
    @objc func confusedAction1(){
        self.onMoodChosenWith(mood: .Confused2)
    }
    
    //set mood as shocked emoji
    @objc func confusedAction2(){
        self.onMoodChosenWith(mood: .Confused2)
    }
    
    //set mood as angry emoji
    @objc func cryingAction1(){
        self.onMoodChosenWith(mood: .Crying1)
    }
    
    @objc func cryingAction2(){
        self.onMoodChosenWith(mood: .Crying2)
    }
    
    @objc func happyAction1(){
       self.onMoodChosenWith(mood: .Happy1)
    }
    
    @objc func happyAction2(){
        self.onMoodChosenWith(mood: .Happy2)
    }
    
    @objc func happyAction3(){
        self.onMoodChosenWith(mood: .Happy3)
    }
    
    @objc func happyAction4(){
        
        self.onMoodChosenWith(mood: .Happy4)
    }
    
    
    @objc func illAction(){
        
        self.onMoodChosenWith(mood: .Ill)
    }
    
    @objc func inLoveAction(){
        
        self.onMoodChosenWith(mood: .InLove)
    }
    @objc func kissingAction(){
        
        self.onMoodChosenWith(mood: .Kissing)
    }
    
    @objc func madAction(){
        
        self.onMoodChosenWith(mood: .Mad)
    }
    
    @objc func nerdAction(){
        
        self.onMoodChosenWith(mood: .Nerd)
    }
    
    
    
    @objc func ninjaAction(){
        
        self.onMoodChosenWith(mood: .Ninja)
    }
    
    @objc func quietAction(){
        
        self.onMoodChosenWith(mood: .Quiet)
    }
    
    @objc func sadAction(){
        
        self.onMoodChosenWith(mood: .Sad)
    }
    
    @objc func smartAction(){
        
        self.onMoodChosenWith(mood: .Smart)
    }
    
    
    @objc func smileAction(){
        
        self.onMoodChosenWith(mood: .Smile)
    }
    
    @objc func smilingAction(){
        
        self.onMoodChosenWith(mood: .Smiling)
    }
    
    
    @objc func surprisedAction1(){
        
        self.onMoodChosenWith(mood: .Surprised1)
    }
    
    @objc func surprisedAction2(){
        
        self.onMoodChosenWith(mood: .Surprised2)
    }
    @objc func suspiciousAction1(){
        
        self.onMoodChosenWith(mood: .Suspicious1)
    }
    
    @objc func suspiciousAction2(){
        
        self.onMoodChosenWith(mood: .Suspicious2)
    }
    
    
    @objc func toungueOutAction(){
        
        self.onMoodChosenWith(mood: .TongueOut)
    }
    
    @objc func unhappyAction(){
        
        self.onMoodChosenWith(mood: .Unhappy)
    }
    @objc func winkAction(){
        
        self.onMoodChosenWith(mood: .Wink)
    }
    

    
    
    
    
    @objc func noneAction(){
        
        self.selectedMood = .None
        self.moodBtn.setImage(UIImage(named: "bwEmoji"), for: .normal)
        self.moodBtn.setTitle("", for: .normal)
        self.closeMoodMenu()
    }
    
    
    func onMoodChosenWith(mood: Mood){
        
        self.selectedMood = mood
        self.moodBtn.setImage(UIImage(named:self.selectedMood.rawValue), for: .normal)
        self.closeMoodMenu()
        
    }
    
    
    func closeMoodMenu(){
        self.moodMenuIsOpen = false
        UIView.animate(withDuration: 0.2, animations: {
            
            for button in self.moodArrayOutside{
                
                button.center = self.moodBtn.center
                button.alpha = 0.0
            }
            
            for button in self.moodArrayInside{
                
                button.center = self.moodBtn.center
                button.alpha = 0.0
            }
            
        }) { (success) in
            if success{
                for button in self.moodArrayOutside{
                    
                    button.isHidden = true
                }
                for button in self.moodArrayInside{
                    
                    button.isHidden = true
                }
            }
        }
        
    }
    
    
    

    func showMoodMenu(){
        
        self.moodMenuIsOpen = true
        for button in self.moodArrayOutside{
            
            button.isHidden = false
        }
        
        for button in self.moodArrayInside{
            
            button.isHidden = false
        }
        
        UIView.animate(withDuration: 0.2) {
            
            for button in self.moodArrayOutside{
                button.alpha = 1.0
                button.center = self.calculateVisibleCenterForOutsideRing(button: button)
            }
            
            for button in self.moodArrayInside{
                button.alpha = 1.0
                button.center = self.calculateVisibleCenterForInsideRing(button: button)
            }
        }
    }
    
    
    
    
    
    //calculate the button center based on the button tag of the outside view
    func calculateVisibleCenterForOutsideRing(button: UIButton) -> CGPoint{
        
        let tag = CGFloat(button.tag)
        let distance = self.moodBtn.frame.width * 4/5
        let origin = self.moodBtn.center
        let slice = (CGFloat.pi * 2.0) / CGFloat(self.moodArrayOutside.count - 1)
        let radians = tag * slice
        
        return pointFromPoint(origin: origin, distance: distance, rad: radians)
    }
    
    
    //calculate the button center based on the button tag of the outside view
    func calculateVisibleCenterForInsideRing(button: UIButton) -> CGPoint{
        
        let tag = CGFloat(button.tag)
        let distance = self.moodBtn.frame.width * 4/9
        let origin = self.moodBtn.center
        let slice = (CGFloat.pi * 2.0) / CGFloat(self.moodArrayInside.count - 1)
        let radians = tag * slice
        
        return pointFromPoint(origin: origin, distance: distance, rad: radians)
    }
    
    
    
    
    func pointFromPoint(origin:CGPoint, distance:CGFloat, rad:CGFloat) -> CGPoint {
        var endPoint = CGPoint()
        endPoint.x = distance * cos(rad) + origin.x
        endPoint.y = distance * sin(rad) + origin.y
        return endPoint
    }
    
    
    
    
    @IBAction func nextAction(_ sender: Any) {
        
        self.performSegue(withIdentifier: "toSubmitPostSegue", sender: self)
    }
    
}

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
    var moodArray: [UIButton] = [UIButton]()
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
        
        let sadBtn: UIButton = UIButton(frame: CGRect.zero)
        let funnyBtn: UIButton = UIButton(frame: CGRect.zero)
        let angryBtn: UIButton = UIButton(frame: CGRect.zero)
        let shockedBtn: UIButton = UIButton(frame: CGRect.zero)
        let afraidBtn: UIButton = UIButton(frame: CGRect.zero)
        let sillyBtn: UIButton = UIButton(frame: CGRect.zero)
        let loveBtn: UIButton = UIButton(frame: CGRect.zero)
        let bravoBtn: UIButton = UIButton(frame: CGRect.zero)
        let fireBtn: UIButton = UIButton(frame: CGRect.zero)
        let coolBtn: UIButton = UIButton(frame: CGRect.zero)
        let okBtn: UIButton = UIButton(frame: CGRect.zero)
        let blessedBtn: UIButton = UIButton(frame: CGRect.zero)
        let noneBtn: UIButton = UIButton(frame: CGRect.zero)
        
        afraidBtn.setTitle(Mood.Afraid.rawValue, for: .normal)
        funnyBtn.setTitle(Mood.Funny.rawValue, for: .normal)
        angryBtn.setTitle(Mood.Angry.rawValue, for: .normal)
        sadBtn.setTitle(Mood.Sad.rawValue, for: .normal)
        shockedBtn.setTitle(Mood.Shocked.rawValue, for: .normal)
        sillyBtn.setTitle(Mood.Silly.rawValue, for: .normal)
        loveBtn.setTitle(Mood.Love.rawValue, for: .normal)
        bravoBtn.setTitle(Mood.Bravo.rawValue, for: .normal)
        fireBtn.setTitle(Mood.Fire.rawValue, for: .normal)
        coolBtn.setTitle(Mood.Cool.rawValue, for: .normal)
        okBtn.setTitle(Mood.Ok.rawValue, for: .normal)
        blessedBtn.setTitle(Mood.Blessed.rawValue, for: .normal)
        noneBtn.setTitle(Mood.None.rawValue, for: .normal)
        
        funnyBtn.center = center
        sadBtn.center = center
        shockedBtn.center = center
        afraidBtn.center = center
        angryBtn.center = center
        sillyBtn.center = center
        loveBtn.center = center
        bravoBtn.center = center
        fireBtn.center = center
        coolBtn.center = center
        noneBtn.center = center
        okBtn.center = center
        blessedBtn.center = center
        
        noneBtn.tag = 0
        funnyBtn.tag = 1
        sadBtn.tag = 2
        angryBtn.tag = 3
        shockedBtn.tag = 4
        afraidBtn.tag = 5
        sillyBtn.tag = 6
        loveBtn.tag = 7
        bravoBtn.tag = 8
        fireBtn.tag = 9
        coolBtn.tag = 10
        okBtn.tag = 11
        blessedBtn.tag = 12
        
        
        afraidBtn.addTarget(self, action: #selector(self.afraidAction), for: .touchUpInside)
        funnyBtn.addTarget(self, action: #selector(self.funnyAction), for: .touchUpInside)
        sadBtn.addTarget(self, action: #selector(self.sadAction), for: .touchUpInside)
        angryBtn.addTarget(self, action: #selector(self.angryAction), for: .touchUpInside)
        shockedBtn.addTarget(self, action: #selector(self.shockedAction), for: .touchUpInside)
        sillyBtn.addTarget(self, action: #selector(self.sillyAction), for: .touchUpInside)
        loveBtn.addTarget(self, action: #selector(self.loveAction), for: .touchUpInside)
        bravoBtn.addTarget(self, action: #selector(self.bravoAction), for: .touchUpInside)
        fireBtn.addTarget(self, action: #selector(self.fireAction), for: .touchUpInside)
        coolBtn.addTarget(self, action: #selector(self.coolAction), for: .touchUpInside)
        okBtn.addTarget(self, action: #selector(self.okAction), for: .touchUpInside)
        blessedBtn.addTarget(self, action: #selector(self.blessedAction), for: .touchUpInside)
        noneBtn.addTarget(self, action: #selector(self.noneAction), for: .touchUpInside)
        
        moodArray = [noneBtn,afraidBtn,funnyBtn,sadBtn,angryBtn,shockedBtn,afraidBtn,sillyBtn,loveBtn,bravoBtn,fireBtn,coolBtn,okBtn,blessedBtn]
        
        for button in moodArray{
            button.frame.size = CGSize(width: self.view.frame.width/CGFloat(moodArray.count/2),height:self.view.frame.width/CGFloat(moodArray.count/2))
            button.isHidden = true
            button.titleLabel?.font = UIFont.systemFont(ofSize: 30.0)
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
    @objc func afraidAction(){
        
        self.onMoodChosenWith(mood: .Afraid)
    }
    
    //set mood as sad emoji
    @objc func sadAction(){
        self.onMoodChosenWith(mood: .Sad)
    }
    
    //set mood as funny emoji
    @objc func funnyAction(){
        self.onMoodChosenWith(mood: .Funny)
    }
    
    //set mood as shocked emoji
    @objc func shockedAction(){
        self.onMoodChosenWith(mood: .Shocked)
    }
    
    //set mood as angry emoji
    @objc func angryAction(){
        self.onMoodChosenWith(mood: .Angry)
    }
    
    @objc func fireAction(){
        self.onMoodChosenWith(mood: .Fire)
    }
    
    @objc func sillyAction(){
       self.onMoodChosenWith(mood: .Silly)
    }
    
    @objc func coolAction(){
        self.onMoodChosenWith(mood: .Cool)
    }
    
    @objc func bravoAction(){
        self.onMoodChosenWith(mood: .Bravo)
    }
    
    @objc func loveAction(){
        
        self.onMoodChosenWith(mood: .Love)
    }
    
    @objc func okAction(){
        
        self.onMoodChosenWith(mood: .Ok)
    }
    
    @objc func blessedAction(){
        
        self.onMoodChosenWith(mood: .Blessed)
    }
    
    
    
    @objc func noneAction(){
        
        self.selectedMood = .None
        self.moodBtn.setImage(UIImage(named: "bwEmoji"), for: .normal)
        self.moodBtn.setTitle("", for: .normal)
        self.closeMoodMenu()
    }
    
    
    func onMoodChosenWith(mood: Mood){
        
        self.selectedMood = mood
        self.moodBtn.setImage(nil, for: .normal)
        self.moodBtn.setTitle(self.selectedMood.rawValue, for: .normal)
        self.closeMoodMenu()
        
    }
    
    
    func closeMoodMenu(){
        self.moodMenuIsOpen = false
        UIView.animate(withDuration: 0.2, animations: {
            for button in self.moodArray{
                
                button.center = self.moodBtn.center
                button.alpha = 0.0
            }
            
        }) { (success) in
            if success{
                for button in self.moodArray{
                    
                    button.isHidden = true
                }
            }
        }
        
    }
    
    
    

    func showMoodMenu(){
        
        self.moodMenuIsOpen = true
        for button in self.moodArray{
            
            button.isHidden = false
        }
        
        UIView.animate(withDuration: 0.2) {
            
            for button in self.moodArray{
                button.alpha = 1.0
                button.center = self.calculateVisibleCenter(button: button)
            }
        }
    }
    
    
    
    
    
    //calculate the button center based on the button tag
    func calculateVisibleCenter(button: UIButton) -> CGPoint{
        
        let tag = CGFloat(button.tag)
        let distance = self.moodBtn.frame.width * 2/3
        let origin = self.moodBtn.center
        let slice = (CGFloat.pi * 2.0) / CGFloat(self.moodArray.count - 1)
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

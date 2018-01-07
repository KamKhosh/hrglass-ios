//
//  SettingsViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 5/5/17.
//
//

import UIKit
import Firebase
import FacebookCore
import FacebookLogin


enum Options: String {
    //Cell Options
    case account = "Account"
    case help = "Help/Support"
    case logout = "Logout"
    case nothing = ""
}



class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let dataManager: DataManager = DataManager()
    var tableOptions = [Options]()
    
    @IBOutlet weak var navigationBar: UINavigationBar!

    @IBOutlet weak var tableView: UITableView!
    
    
    /****************************************
     *
     * ----------- LIFECYCLE ------------
     *
     ******************************************/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        //settings footer to stop the row dividers from continuing to draw
        self.tableView.tableFooterView = UIView.init(frame: CGRect.zero)
        
        
        //tableView data source
        tableOptions = [.nothing,.account,.help,.logout]
        
        self.navigationBar.frame.size = CGSize(width: self.view.frame.width, height: 80)
        
        //removing bottom navigation line
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()

    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    
    
    /*********************************
     *
     * - TABLEVIEW DELEGATE METHODS -
     *
     *********************************/

    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableOptions.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:SettingsTableViewCell = tableView.dequeueReusableCell(withIdentifier: "settingsCell") as! SettingsTableViewCell
        
        if tableOptions[indexPath.row] != .nothing{
            
            cell.title?.text = tableOptions[indexPath.row].rawValue
            cell.title?.textColor = UIColor.white
            cell.title?.textAlignment = .left
        }
        
        return cell
        
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let firstCellHeight:CGFloat = 0.0
        let normalCellHeight:CGFloat = 60.0
        
        // setting the row height to 0 so we get the top cell seperator
        if tableOptions[indexPath.row] == .nothing {
            return firstCellHeight
        }
        return normalCellHeight
    }
    

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //deselect the cell that was just selected
        let cell = self.tableView.cellForRow(at: indexPath)
        cell?.setSelected(false, animated: false)
        
        
        switch tableOptions[indexPath.row] {
            
        case .help:

            let supportView = self.storyboard?.instantiateViewController(withIdentifier: "supportVC") as! SupportViewController
            
            self.navigationController?.pushViewController(supportView, animated: true)
            
        case .logout:
            
            let alert = UIAlertController(title: "", message: "Logout?", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: logout)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            
            alert.addAction(defaultAction)
            alert.addAction(cancelAction)
            
            self.present(alert, animated: true, completion: nil)
            
        case .account:
            
            
            let accountView = self.storyboard?.instantiateViewController(withIdentifier: "accountView") as! AccountViewController
            
            
            self.navigationController?.pushViewController(accountView, animated: true)
            
            
            
        default:
            
            //do nothing
            print("do nothing")
        }
    }
    
    
    
    /*********************************
     *
     * ---------- NAVIGATION ---------
     *
     *********************************/
    
    
    @IBAction func unwindToSettings(unwindSegue: UIStoryboardSegue){
        
        
    }
    
    func logout(alert: UIAlertAction){
        

        do {
            
            //Logout from firebase, then Facebook if necessary
            try Auth.auth().signOut()
            
            if((AccessToken.current) != nil){
                
                let loginManager = LoginManager()
                loginManager.logOut()
            }
            
            //Delete Local domain data
            self.dataManager.deleteLocalDocuments()
            let appDomain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: appDomain)
            
            
            self.performSegue(withIdentifier: "unwindToWelcome", sender: nil)
            
        } catch let signOutError as NSError {
            
            print ("Error signing out: %@", signOutError)
            
            let alert = UIAlertController(title: "Error", message: "Logout Failed", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            
            alert.addAction(defaultAction)
            
            self.present(alert, animated: true, completion: nil)
            
        }
    }
    
    

    
    

}

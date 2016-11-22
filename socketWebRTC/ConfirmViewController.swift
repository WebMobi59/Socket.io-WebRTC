//
//  ConfirmViewController.swift
//  socketWebRTC
//

import UIKit
import SwiftHTTP

class ConfirmViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var confirmTextField: UITextField!
    @IBOutlet weak var confirmBtn: UIButton!
    var mobile_number : String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        mobile_number = UserDefaults.standard.value(forKey: "mobile_number") as! String
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }
    
    func isValidActivationCode(code : String, completionHandler: @escaping (_ _bool: Int) -> ()){
        let urlString = "http://ec2-52-24-49-20.us-west-2.compute.amazonaws.com:2017/tenant-authorization/\(mobile_number)"
        let parameters = ["activationCode" : code]
        
        do {
            let opt = try HTTP.PUT(urlString, parameters: parameters, headers: nil, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                if let err = response.error {
                    print("isValidActivateCode ===> error: \(err.localizedDescription)")
                    completionHandler(1)
                }else {
                    completionHandler(0)
                }
            }
        } catch let error {
            
            completionHandler(2)
            print("got an error creating the request: \(error)")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.confirmBtn.layer.cornerRadius = 5.0
    }

    @IBAction func confirmBtnPressed(_ sender: AnyObject) {
        let activationCode = self.confirmTextField.text
        self.isValidActivationCode(code: activationCode! as String) { (_bool) in
            if _bool == 0 {
                DispatchQueue.main.async(){
                    //code
                    let addUserVC = self.storyboard?.instantiateViewController(withIdentifier: "addUserInfoVC") as! AddUserInfoViewController
                    self.navigationController?.pushViewController(addUserVC, animated: true)
                }
            } else if _bool == 2 {
                DispatchQueue.main.async {
                    let roomVC = self.storyboard?.instantiateViewController(withIdentifier: "roomVC") as! RoomViewController
                    self.navigationController?.pushViewController(roomVC, animated: true)
                }
            } else {
                let alertViewController = UIAlertController(title: "Alert", message: "You have entered an incorrect activation code. Please check your code and try again", preferredStyle: .alert)
                let OkAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertViewController.addAction(OkAction)
                self.present(alertViewController, animated: true, completion: nil)
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

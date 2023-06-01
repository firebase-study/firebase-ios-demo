import SwiftUI
import FirebaseAuth
import FirebaseDatabase
import FirebaseMessaging

class UserViewModel: ObservableObject {
  @AppStorage("isSignedIn") var isSignedIn = false
  @Published var email = ""
  @Published var password = ""
  @Published var userName = ""
  @Published var deviceToken = ""
  @Published var alert = false
  @Published var alertMessage = ""
    
    
  private var ref = Database.root
  private var refHandle: DatabaseHandle?

  private func showAlertMessage(message: String) {
    alertMessage = message
    alert.toggle()
  }

  func login() {
    // check if all fields are inputted correctly
    if email.isEmpty || password.isEmpty {
      showAlertMessage(message: "Neither email nor password can be empty.")
      return
    }
    // sign in with email and password
    Auth.auth().signIn(withEmail: email, password: password) { result, err in
      if let err = err {
        self.alertMessage = err.localizedDescription
        self.alert.toggle()
      } else {
        self.isSignedIn = true
        self.userName = self.userNameForEmail(withEmail: self.email)
        self.saveUser()
      }
    }
  }

  func signUp() {
    // check if all fields are inputted correctly
    if email.isEmpty || password.isEmpty {
      showAlertMessage(message: "Neither email nor password can be empty.")
      return
    }
    // sign up with email and password
    Auth.auth().createUser(withEmail: email, password: password) { result, err in
      if let err = err {
        self.alertMessage = err.localizedDescription
        self.alert.toggle()
      } else {
        self.login()
      }
    }
  }

  func logout() {
    do {
      try Auth.auth().signOut()
      isSignedIn = false
      email = ""
      password = ""
      userName = ""
    } catch {
      print("Error signing out.")
    }
  }
    
    func saveUser(){
     if let userID = getCurrentUserID() {
         let userRef = ref.child("users").child(userID)
         
         let token = Messaging.messaging().fcmToken
         print("FCM token: \(token ?? "")")
         self.deviceToken = (token ?? "")
         
         // [START log_iid_reg_token]
         Messaging.messaging().token { token, error in
           if let error = error {
             print("Error fetching remote FCM registration token: \(error)")
           } else if let token = token {
             print("Remote instance ID token: \(token)")
               self.deviceToken = token
           }
         }
         // [END log_iid_reg_token]
         
         let userInfo = ["email": email,
                        "userName": userName,
                        "deviceToken": deviceToken,
                         "terminalType": "01"
                        ]
         userRef.setValue(userInfo)
        }
    }
    

    
    private func getCurrentUserID() -> String? {
      return Auth.auth().currentUser?.uid
    }
    
    private func userNameForEmail(withEmail: String) -> String {
        if withEmail.contains("@"){
            return withEmail.components(separatedBy: "@")[0]
        }
        return ""
    }
}

let user = UserViewModel()

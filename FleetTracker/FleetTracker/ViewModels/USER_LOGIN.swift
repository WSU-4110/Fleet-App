//
//  USER_LOGIN.swift
//  FleetTracker
//
//  Created by Maher Yousif on 2/18/26.
//
import SwiftUI
import FirebaseAuth
import Combine


class SignInViewModel:ObservableObject{
    @Published var user:User?// tracks our user
    @Published var errorMessage:String?//errors
    
    func signIn(email:String, password:String){
        Auth.auth().signIn(withEmail:email,password:password){[weak self]
            result,error in
            if let error=error{
                self?.errorMessage=error.localizedDescription
                return
            }
            self?.user=result?.user//update state on sucessful login
            
        }
    }
}
struct LoginView:View {
    @State private var email:String=""
    @State private var password:String=""
    @ObservedObject var ViewModel=SignInViewModel()
    var body: some View {
        VStack{
            Text("Login with email")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            TextField("Email", text:$email).textFieldStyle(.roundedBorder).textInputAutocapitalization(.none)
            SecureField("Password", text: $password).textFieldStyle(.roundedBorder).textInputAutocapitalization(.none)
            Button("Login"){
                ViewModel.signIn(email: email, password: password)
            }
            .buttonStyle(.borderedProminent)
            if let errorMessage = ViewModel.errorMessage{
                Text(errorMessage).foregroundStyle(Color.red)
            }
        }
    }
   
}

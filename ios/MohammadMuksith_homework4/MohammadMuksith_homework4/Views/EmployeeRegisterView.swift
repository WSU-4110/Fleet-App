//
//  EmployeeRegisterView.swift
//  FleetTracker
//
//  Created by Mohammad Muksith on 2/18/26.
//

import SwiftUI
import FirebaseAuth
import Firebase
import FirebaseFirestore

struct EmployeeRegisterView: View {
    @State private var password = ""
    @State private var email = ""
    @State private var currentUser: EmployeeModel?
//    @State var employee: EmployeeModel
    @State private var submissionError: String?
    @AppStorage("email-link") var emailLink: String?
    @State var errorMessage = ""
    @Environment(\.dismiss) var dismiss
    @StateObject private var vm = EmployeeViewModel()
    var body: some View {
        switch vm.employeeAuthenticationState{
        case .authenticated :
            EmployeeInputView()
        case .unauthenticated, .authenticating :
            ZStack{
                VStack(spacing: 20) {
                    Text("Register as Employee")
                        .keyboardType(.numberPad)
                        .padding()
                        .fontWeight(.bold)
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.center)
                    VStack(alignment: .leading) {
                        Text("Email")
                        TextField("", text: $vm.email)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .autocapitalization(.none)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .keyboardType(.emailAddress)
                            .foregroundStyle(Color.black)
                            .font(.custom("Chalkduster", size: 20))
                            .onSubmit {
                               // signInWithEmailLink()
                            }
                        Text("Password")
                            .font(.custom("Chalkduster", size: 20))
                        TextField("", text: $vm.password)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .autocapitalization(.none)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .keyboardType(.emailAddress)
                            .foregroundStyle(Color.black)
                            .font(.custom("Chalkduster", size: 20))
                            .onSubmit {
                               // signInWithEmailLink()
                            }
                    }
                    Text(errorMessage)
                    if !vm.errorMessage.isEmpty {
                        VStack {
                            Text(vm.errorMessage)
                                .foregroundColor(Color(UIColor.systemRed))
                        }
                    }
                    
                    
                    Button {
                        vm.register()
                    } label:{
                        if vm.employeeAuthenticationState != .authenticating {
                            Text("Login")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white) // Background color
                                .foregroundColor(.black) // Text color
                                .cornerRadius(8) // Rounded corners
                                .font(.custom("Chalkduster", size: 20)) // Custom font
                        }
                        
                        else {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                        }
                           
                    }
                    .disabled(!vm.isValid)
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                
                Spacer()
                
            }
            .padding()
        }
            }
        }
    
}

//#Preview {
//    EmployeeRegisterView()
//}

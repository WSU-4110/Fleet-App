//
//  EmployeeInputView.swift
//  FleetTracker
//
//  Created by Mohammad Muksith on 2/18/26.
//

import SwiftUI
import CoreLocation
import CoreLocationUI

struct EmployeeInputView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var vm = EmployeeViewModel()
    //@State var employee: EmployeeModel
    var body: some View {
        if vm.isSubmitted {
            VStack{
                if let user = vm.currentUser {
                    EmployeeMapView()
                } else {
                    Text("error no data 1")
                }
                
                
            }
            .onAppear {
                vm.fetchUserData()
            }
            
        } else {
            ZStack{
                if let coordinate = locationManager.lastKnownLocation {
                    let location = CLLocationCoordinate2D(
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude
                    )
                    Text("Latitude: \(coordinate.latitude)")
                    
                    Text("Longitude: \(coordinate.longitude)")
                   
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Enter Student Details")
                            .keyboardType(.numberPad)
                            .padding()
                            .fontWeight(.bold)
                            .foregroundStyle(Color.white)
                            .font(.custom("Chalkduster", size: 60))
                            .multilineTextAlignment(.center)
                        // Name Input
                        TextField("Name", text: $vm.name)
                        //.keyboardType(.numberPad)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .foregroundStyle(Color.black)
                            .font(.custom("Chalkduster", size: 20))
//                        
//                        Button {
//                            vm.submitData()
//                        } label: {
//                            Text("Submit")
//                                .foregroundColor(.black)
//                                .frame(maxWidth: .infinity)
//                                .padding()
//                                .background(Color.white)
//                                .cornerRadius(8)
//                                .foregroundStyle(Color.black)
//                                .font(.custom("Chalkduster", size: 20))
//                        }
                     
                        
                        Spacer()
                        Button {
                            if let coordinate = locationManager.lastKnownLocation {
                                vm.latitude = String(coordinate.latitude)
                                vm.longitude = String(coordinate.longitude)
                                vm.locationTime = vm.dateFormatter.string(from: Date())
                                
                                vm.submitData()
                            } else {
                                vm.submissionError = "Location not available"
                            }
                        } label: {
                            Text("Submit")
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                                .font(.custom("Chalkduster", size: 20))
                        }
                        
                        if let error = vm.submissionError {
                            Text(error)
                                .foregroundColor(.red)
                        }
                        Button{
                            vm.signOut()
                        } label: {
                            Text("Logout")
                        }
                    }
                    .padding()
                    
                } else {
                    Text("Unknown Location")
                }
            }
            .onAppear() {
                locationManager.checkLocationAuthorization()
            }
        }
    }
    
}

//#Preview {
//    EmployeeInputView()
//}

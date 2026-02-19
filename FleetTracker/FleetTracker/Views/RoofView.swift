//
//  RoofView.swift
//  FleetTracker
//
//  Created by Maher Yousif on 2/18/26.
//
import SwiftUI
import FirebaseAuth


struct Rootview:View{
    @StateObject private var viewModel=SignInViewModel()
    
    var body: some View {
        if viewModel.user != nil{
            MapScreen()
        }
        else{
            LoginView(viewModel: viewModel)
        }
    }
}

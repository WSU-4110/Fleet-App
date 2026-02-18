//
//  EmployeeDetailView.swift
//  FleetTracker
//
//  Created by Mohammad Muksith on 2/18/26.
//

import SwiftUI

struct EmployeeDetailView: View {
    var employee: EmployeeModel
    var body: some View {
        Text(employee.name)
    }
}

//#Preview {
//    EmployeeDetailView()
//}

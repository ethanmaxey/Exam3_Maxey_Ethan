//
//  ContentView.swift
//  Exam3_Maxey_Ethan Watch App
//
//  Created by user235933 on 11/14/23.
//

import SwiftUI

struct ContentView: View {
    private var syncService = SyncService()
    @State private var data: String = ""
    @State private var receivedData: [String] = []
    
    var moodArray = ["❓", "🚗", "💻", "🏠"]
    @State var moodIdx = 0
    
    var body: some View {
        VStack {
            Text("Pª ") // Use fn + e
                .foregroundStyle(.red)
                .font(.system(size: 36))
                .bold()
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            Text(moodArray[moodIdx])
                .font(.system(size: 80))
                .foregroundColor(.red)
            
            // Bleeds into TabView
            Rectangle()
                .frame(height: 0)
                .background(Color.clear)
        }
        .background(Color.gray)
        .onAppear {
//            print("Starting Data Service")
            syncService.dataReceived = Receive
//            print("Data Service Passed")
        }
    }
    
    private func Receive(key: String, value: Any) -> Void {
        // Convert value to String and take the first 20 characters
        let stringValue = String(describing: value).prefix(100)
        
        // Append the truncated string along with the current date to the receivedData array
        self.receivedData.append("\(Date().formatted(date: .omitted, time: .standard)) - \(key):\(stringValue)")
        
        // Determine moodIdx based on the content of the string
        if stringValue.contains("car") {
            self.moodIdx = 1
        } else if stringValue.contains("library") {
            self.moodIdx = 2
        } else if stringValue.contains("church") {
            self.moodIdx = 3
        } else {
            self.moodIdx = 0
        }
        
        // Print the key and truncated string value
//        print(key, stringValue)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

import SwiftUI

@main
struct TestRunnerApp: App {
    var body: some Scene {
        WindowGroup {
            TestRunnerView()
        }
    }
}

struct TestRunnerView: View {
    @State private var testResults: String = "Press Run Tests to start testing"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("FocusTracker Test Runner")
                .font(.title)
                .padding()
            
            Button("Run Tests") {
                runTests()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            ScrollView {
                Text(testResults)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding()
        }
        .padding()
    }
    
    private func runTests() {
        // Redirect stdout to capture test output
        let pipe = Pipe()
        let originalStdout = dup(STDOUT_FILENO)
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        
        // Run tests
        TestRunner.runAllTests()
        
        // Restore stdout
        fflush(stdout)
        dup2(originalStdout, STDOUT_FILENO)
        close(originalStdout)
        pipe.fileHandleForWriting.closeFile()
        
        // Get test output
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                self.testResults = output
            }
        }
    }
}
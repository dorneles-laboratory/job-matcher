import SwiftUI

@main
struct EMBERApp: App {
    @StateObject private var vm = JobTinderViewModel()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if !vm.isAuthenticated {
                    AuthView()
                } else if vm.currentUser?.role == .candidate {
                    CandidateMainTabView()
                } else {
                    CompanyMainTabView()
                }
                
                if let match = vm.activeMatchNotification {
                    MatchNotificationOverlay(
                        candidateName: match.candidateName,
                        jobTitle: match.jobTitle
                    ) {
                        vm.activeMatchNotification = nil
                    }
                }
            }
            .environmentObject(vm)
        }
    }
}

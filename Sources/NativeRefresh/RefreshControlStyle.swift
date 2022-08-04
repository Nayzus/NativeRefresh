import SwiftUI
import Combine

@available(iOS 14.3, *)
public protocol RefreshControlStyle {
    typealias Configuration = RefreshControlStyleConfiguration
    @ViewBuilder func makeBody(configuration: Self.Configuration) -> AnyView
}

@available(iOS 14.3, *)
public struct CircularRefreshControlStyle: RefreshControlStyle {
    public func makeBody(configuration: Configuration) -> AnyView {
        AnyView(CircularRefreshControlView(configuration: configuration, color: .gray))
    }
}

@available(iOS 14.3, *)
public class RefreshControlStyleConfiguration: ObservableObject {
    typealias EndRefreshAction = () async -> ()
    typealias RefreshAction = () async -> ()
    typealias OffsetChangeAction = (CGFloat) async -> ()
    @Published var isRefresh: Bool = false
    @Published var pullProgress: Double = 0
    
    let offsetTrigger: Double = 100.0
    var refreshAction: RefreshAction? = nil
    var endRefreshAction: EndRefreshAction? = nil
    var offsetChangeAction: OffsetChangeAction? = nil
    
    @MainActor
    func updateProgress(_ offset: CGPoint) {
        Task {
            await offsetChangeAction?(offset.y)
        }
        if !isRefresh {
            if offset.y < offsetTrigger && offset.y >= 0 {
                self.pullProgress = (offset.y / offsetTrigger) * 100
            } else if offset.y >= offsetTrigger  {
                self.pullProgress = 100.0
                Task {
                    await self.startRefreshAction()
                }
            }
        }
    }
    
    @MainActor
    func startRefreshAction() async {
        self.isRefresh.toggle()
        if let refreshAction = refreshAction {
            await refreshAction()
        }
        await self.endRefreshAction()
    }
    
    @MainActor
    func endRefreshAction() async {
        if let endRefreshAction = endRefreshAction {
            await endRefreshAction()
        }
    
        self.pullProgress = 0
        withAnimation {
            self.isRefresh = false
        }
    }
}
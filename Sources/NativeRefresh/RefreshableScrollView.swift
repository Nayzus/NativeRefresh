import SwiftUI
import Combine

@available(iOS 14.3, *)
public struct RefreshableScrollView<Content: View>: View {
    @ObservedObject private var configuration: RefreshControlStyleConfiguration = .init()
    @State private var currentOffset: CGFloat = 0.0
    
    let content: Content
    var refreshControlStyle: RefreshControlStyle
    
    var dinamicHeight: Double {
        if configuration.isRefresh {
            if currentOffset < 100 {
                return 100
            }
        }
        return currentOffset > 0 ? currentOffset : 0
    }
    
    public init(offsetChangeAction: ((CGFloat) async -> ())? = nil, @ViewBuilder content: () -> Content)  {
        self.content = content()
        self.refreshControlStyle = CircularRefreshControlStyle()
        self.configuration.offsetChangeAction = offsetChangeAction
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            if configuration.refreshAction != nil {
                refreshControlStyle.makeBody(configuration: configuration)
                    .frame(height: 100, alignment: .center)
            }
            ScrollView() {
                GeometryReader { proxy in
                    Color.clear.preference(key: OffsetPreferenceKey.self,
                                           value: proxy.frame(in: .named("ScrollViewOrigin"))
                        .origin)
                }
                
                if #available(iOS 15, *) {
                    VStack(spacing: 0) {
                        Rectangle()
                            .frame(height: dinamicHeight, alignment: .center)
                            .foregroundColor(.clear)
                        content
                    }
                }
                else {
                    content
                        .offset(x: 0, y: dinamicHeight)
                }
                
            }
            .coordinateSpace(name: "ScrollViewOrigin")
            .onPreferenceChange(OffsetPreferenceKey.self, perform: { offset in
                self.currentOffset = offset.y
                self.configuration.updateProgress(offset)
            })
        }
    }
    
    public func refreshControlStyle<S>(_ style: S) -> some View where S : RefreshControlStyle {
        var this = self
        this.refreshControlStyle = style
        return this
    }
    
    // MARK: - View-specific Modifiers
    public func onRefresh(_ action: @escaping () async -> Void) -> Self {
        configuration.refreshAction = action
        return self
    }
}

@available(iOS 14.3, *)
private extension RefreshableScrollView {
    struct Configuration {
        var onOffsetChange: ((CGFloat) -> Void)? = nil
    }
}

@available(iOS 14.3, *)
private struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { }
}

import SwiftUI
import Combine


public struct RefreshableScrollView<Content: View>: View {
    @ObservedObject private var configuration: RefreshControlStyleConfiguration = .init()
    @State private var currentOffset: CGFloat = 0.0
    @Binding var disabledScroll: Bool
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
        self._disabledScroll = .constant(false)
        self.configuration.offsetChangeAction = offsetChangeAction
      
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            if configuration.refreshAction != nil {
                refreshControlStyle.makeBody(configuration: configuration)
                    .frame(height: 100, alignment: .center)
            }
            ScrollView() {
                Group {
                
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
                }.background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: OffsetPreferenceKey.self,
                                               value: proxy.frame(in: .named("ScrollViewOrigin"))
                            .origin)
                    }
                )
            }
            .gesture(DragGesture(minimumDistance: disabledScroll ? 0 : 10000))
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
    
    public func disabledScroll(_ value: Binding<Bool>) -> Self {
        var this = self
        this._disabledScroll = value
        return this
    }
    
}


private extension RefreshableScrollView {
    struct Configuration {
        var onOffsetChange: ((CGFloat) -> Void)? = nil
    }
}


private struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { }
}

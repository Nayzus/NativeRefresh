import SwiftUI
import Combine


public struct RefreshableScrollView<Content: View>: View {
    @PersistentObject private var configuration: RefreshControlStyleConfiguration = .init()
    
    @State private var currentOffset: CGFloat = 0.0
    @Binding var disabledScroll: Bool
    let content: Content
    var refreshControlStyle: RefreshControlStyle
    
    var dynamicHeight: Double {

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
                    .padding()
                    .frame(height: configuration.offsetTrigger, alignment: .top)
            }
            ScrollView() {
                Group {
                
                    if #available(iOS 15, *) {
                        VStack(spacing: 0) {
                            Rectangle()
                                .frame(height: dynamicHeight, alignment: .center)
                                .foregroundColor(.clear)
                            
                            content
                        }
                    }
                    else {
                        content
                            .offset(x: 0, y: dynamicHeight)
                    }
                }.background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: OffsetPreferenceKey.self,
                                               value: proxy.frame(in: .named("ScrollViewOrigin"))
                            .origin)
                    }
                )
                .animation(configuration.isRefresh == false && configuration.pullProgress == 0  ? .easeOut(duration: 0.3) : .none, value: dynamicHeight)
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


@propertyWrapper
public struct PersistentObject<ObjectType: ObservableObject>: DynamicProperty {
    private let thunk: () -> ObjectType
    
    @State private var objectContainer = _OptionalObservedObjectContainer<ObjectType>()
    
    @ObservedObject private var observedObjectContainer = _OptionalObservedObjectContainer<ObjectType>()
    
    public var wrappedValue: ObjectType {
        get {
            if let object = objectContainer.base {
                if observedObjectContainer.base !== object {
                    observedObjectContainer.base = object
                }
                
                return object
            } else {
                let object = thunk()
                
                objectContainer.base = object
                observedObjectContainer.base = object
                
                return object
            }
        } nonmutating set {
            objectContainer.base = newValue
            observedObjectContainer.base = newValue
        }
    }
    
    public var projectedValue: ObservedObject<ObjectType>.Wrapper {
        ObservedObject(wrappedValue: wrappedValue).projectedValue
    }
    
    public init(wrappedValue thunk: @autoclosure @escaping () -> ObjectType) {
        self.thunk = thunk
    }
    
    public mutating func update() {
        _objectContainer.update()
        _observedObjectContainer.update()
    }
}


final class _OptionalObservedObjectContainer<ObjectType: ObservableObject>: ObservableObject {
    private var baseSubscription: AnyCancellable?
    
    var onObjectWillChange: () -> Void = { }
    
    var base: ObjectType? {
        didSet {
            if let oldValue = oldValue, let base = base {
                if oldValue === base, baseSubscription != nil {
                    return
                }
            }
            
            subscribe()
        }
    }
    
    init(base: ObjectType? = nil) {
        self.base = base
        
        subscribe()
    }
    
    private func subscribe() {
        guard let base = base else {
            return
        }
        
        baseSubscription = base
            .objectWillChange
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                guard let `self` = self else {
                    return
                }
                
                DispatchQueue.main.async {
                    `self`.objectWillChange.send()
                    `self`.onObjectWillChange()
                }
            })
    }
}

//
//  CircularRefreshControlView.swift
//  ExampleRefresh
//
//  Created by Pavel Parshutkin on 28.07.2022.
//

import SwiftUI

public struct CircularRefreshControlView: View, Equatable {
    public static func == (lhs: CircularRefreshControlView, rhs: CircularRefreshControlView) -> Bool {
        return lhs.configuration === rhs.configuration
    }
    
    @ObservedObject var configuration: RefreshControlStyleConfiguration
    @State private var opacity: [Double] = [0, 0, 0, 0, 0, 0, 0, 0]
    @State private var rotationEnd: Bool = false
    @State private var scalingEnd: Bool = false
    @State private var id = UUID().uuidString
    let color: Color
    let hintText: String?
    let hintColor: Color?
    let haptic: UIImpactFeedbackGenerator.FeedbackStyle?
    
    public var body: some View {
        VStack {
            Group {
                ZStack {
                    ForEach(0..<8) { idx in
                        VStack {
                            Rectangle()
                                .fill(color)
                                .opacity(self.opacity[idx])
                                .frame(width: 3.5, height: 10)
                                .cornerRadius(2)
                            Spacer()
                        }
                        .rotationEffect(Angle.degrees(Double(idx)/(8) * 360))
                    }
                }
            }
            .id(id)
            .frame(width: 29, height: 29, alignment: .center)
            .rotationEffect(Angle(degrees: configuration.isRefresh ? 180 : 0), anchor: .center)
            .rotationEffect(Angle(degrees: rotationEnd ? 320 : 0), anchor: .center)
            .animation(.timingCurve(0.3, 0.2, 0.1, 1, duration: 1.5), value: configuration.isRefresh)
            .animation(.timingCurve(0.2, 0.2, 0.1, 0, duration: 0.5), value: rotationEnd)
            .drawingGroup()
            
            Text(LocalizedStringKey(hintText ?? ""))
                .font(.system(size: 14, weight: .semibold))
                .fontWeight(.semibold)
                .foregroundColor(hintColor ?? .gray)
                .opacity(configuration.pullProgress / 100)
        
        }
        .scaleEffect(scalingEnd ? 0 : 1)
        .opacity(scalingEnd ? 0 : 1)
        .animation(.easeOut(duration: 0.4), value: scalingEnd)
        .padding(.top, 8)
        .onReceive(configuration.$pullProgress, perform: { progress in
            self.startOpacityPattern(progress)
        })
        .onReceive(configuration.$isRefresh, perform: { isRefresh in
            if isRefresh == true {
                Task {
                    if let haptic = haptic {
                        induceHaptic(style: haptic)                        
                    }
                    self.opacity = [1,1,1,1,1,1,1,1]
                    await asyncRepeater()
                }
            }
        })
    }
    
    public init(configuration: RefreshControlStyleConfiguration,
         color: Color = .gray,
         hintText: String? = nil,
         hintColor: Color? = nil,
         haptic: UIImpactFeedbackGenerator.FeedbackStyle? = .medium) {
        self.configuration = configuration
        self.color = color
        self.hintText = hintText
        self.hintColor = hintColor
        self.haptic = haptic
    }
    
    @MainActor
    private func startOpacityPattern(_ progress: Double) {
        if progress == 0 {
            self.opacity = [0,0,0,0,0,0,0,0]
        }
        let stickZone: Double =  configuration.offsetTrigger / 8
        for key in opacity.indices {
            let stickRange = (stickZone * Double(key))...100.0
            guard stickRange ~= progress else {
                self.opacity[key] = 0
                return
            }
            let onePercent = (stickRange.upperBound - stickRange.lowerBound) * 0.01
            let stickProgress = (progress - stickRange.lowerBound) / onePercent
            let opacity = stickProgress * 0.01
            self.opacity[key] =  opacity
        }
    }
    
    @MainActor
    private func asyncRepeater() async {
        
        configuration.endRefreshAction = {
            rotationEnd = true
            scalingEnd = true
            try? await Task.sleep(nanoseconds: 200_000_000)
         
        }
        var currentCircle: Int = 0
        var _currentKey: Int = 0
        var currentKey: Int  {
            get {
                return _currentKey
            }
            set {
                if newValue < 0 {
                    _currentKey = newValue + 7
                }
                else if newValue > 7 {
                    _currentKey = 0
                    currentCircle += 1
                }
                else {
                    _currentKey = newValue
                }
            }
        }
        
        opacity[currentKey] = 1
        let startFromOpacity = 0.8
        repeat {
            for i in 1...4 {
                if currentCircle > 0 {
                    let index = currentKey - i < 0 ? currentKey - i + 8 : currentKey - i
                    opacity[index] = startFromOpacity - (Double(i) * 0.1)
                } else if currentKey - i > 0 {
                    opacity[currentKey - 1] = startFromOpacity - (Double(i) * 0.1)
                }
            }
            try? await Task.sleep(nanoseconds: 75_000_000)
            currentKey += 1
        } while configuration.isRefresh
        withAnimation {
            rotationEnd = false
            scalingEnd = false
            id = UUID().uuidString
        }
    }
}

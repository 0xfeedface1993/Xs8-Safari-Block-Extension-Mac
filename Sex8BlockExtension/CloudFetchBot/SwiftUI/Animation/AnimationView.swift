//
//  AnimationView.swift
//  CloudFetchBot
//
//  Created by god on 2019/8/19.
//  Copyright © 2019 ascp. All rights reserved.
//

import SwiftUI

struct ScaleFade: ViewModifier {
    var isEnabled: Bool
    func body(content: _ViewModifier_Content<ScaleFade>) -> some View {
        return content.scaleEffect(isEnabled ? 1:0.1).opacity(isEnabled ? 1:0)
    }
}

extension AnyTransition {
    static let scaleAndFade = AnyTransition.modifier(active: ScaleFade(isEnabled: true),
                                                     identity: ScaleFade(isEnabled: false))
}

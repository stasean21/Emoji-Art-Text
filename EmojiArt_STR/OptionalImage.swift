//
//  OptionalImage.swift
//  EmojiArt_STR
//
//  Created by Станислав Мунтяну on 10.12.2023.
//

import SwiftUI


struct OptionalImage: View {
    var uiImage: UIImage?
    
    var body: some View {
        Group {
            if uiImage != nil {
                Image(uiImage: uiImage!)
            }
        }
    }
}


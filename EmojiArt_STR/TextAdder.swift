//
//  TextAdder.swift
//  EmojiArt_STR
//
//  Created by Станислав Мунтяну on 10.12.2023.
//

import SwiftUI

struct TextAdder: View {
    @EnvironmentObject var document: EmojiArtDocument
    @Binding var isShowing: Bool
    @State private var textToAdd: String = ""
    
    var body: some View {
        VStack (spacing: 0) {
            ZStack{
                Text("Добавление текста").font(.headline).padding()
                HStack{
                    Spacer()
                    Button(action: {self.isShowing = false
                        if textToAdd != "" {
                            let location: CGPoint = CGPoint(x: 0,y: 0)
                            self.document.addEmoji(textToAdd, at: location, size: self.document.defaultEmojiSize)
                        }
                    }, label: {
                        Text("Добавить")
                    }).padding()
                }
            }
            Divider()
            Form {
                Section {
                    TextField("Напишите текст", text: $textToAdd, onEditingChanged: { began in
                        //self.chosenPallete = self.document.addEmoji(self.emojisToAdd, toPalette: self.chosenPallete)
                        //self.emojisToAdd = ""
                    })
                }}
        }
    }
}

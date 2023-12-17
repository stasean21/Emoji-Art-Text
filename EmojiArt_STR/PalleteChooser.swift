//
//  PalleteChooser.swift
//  EmojiArt_STR
//
//  Created by Станислав Мунтяну on 09.12.2023.
//

import SwiftUI

struct PalleteChooser: View {
    @ObservedObject var document: EmojiArtDocument
    
    @Binding var chosenPallete: String
    
    @State private var showPaletteEditor = false
    
    var body: some View {
        HStack {
            Stepper( onIncrement: {
                self.chosenPallete = self.document.palette(after: self.chosenPallete)
            }, onDecrement: {
                self.chosenPallete = self.document.palette(before: self.chosenPallete)
            }, label: {EmptyView()})
            Text(self.document.paletteNames[self.chosenPallete] ?? "")
            
            Image(systemName: "keyboard")
                .imageScale(.large)
                .onTapGesture {
                    self.showPaletteEditor = true
                }
                .sheet(isPresented: $showPaletteEditor) { //popover
                    PaletteEditor(isShowing: self.$showPaletteEditor, chosenPallete: $chosenPallete)
                        .environmentObject(self.document)
                        .frame(minWidth: 300, minHeight: 500)
                }
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct PaletteEditor: View {
    @EnvironmentObject var document: EmojiArtDocument
    
    @Binding var isShowing: Bool
    @Binding var chosenPallete: String
    
    @State private var paletteName: String = ""
    @State private var emojisToAdd: String = ""
    
    var body: some View {
        VStack(spacing: 0){
            
            ZStack{
                Text("Редактор наборов эмоджи").font(.headline).padding()
                HStack{
                    Spacer()
                    Button(action: {self.isShowing = false}, label: {
                      Text("Done")
                    }).padding()
                }
            }
            
            Divider()
            
            Form {
                Section {
                    TextField("Имя набора", text: $paletteName, onEditingChanged: { began in
                        self.document.renamePalette(self.chosenPallete, to: self.paletteName)
                    }).padding()
                    
                    TextField("Добавить эмоджи", text: $emojisToAdd, onEditingChanged: { began in
                        self.chosenPallete = self.document.addEmoji(self.emojisToAdd, toPalette: self.chosenPallete)
                        self.emojisToAdd = ""
                    })
                }
                Section (header: Text("Удаление эмоджи")){
                    Grid(chosenPallete.map { String($0) }, id: \.self ) { emoji in
                        Text(emoji).font(Font.system(size: self.fontSize))
                            .onTapGesture {
                                self.chosenPallete = self.document.removeEmoji(emoji, fromPalette: self.chosenPallete)
                            }
                    }
                    .frame(height:self.height)
                }
            }
        }.onAppear {self.paletteName =  self.document.paletteNames[self.chosenPallete] ?? "" }
    }
    
    var height: CGFloat {
        CGFloat((chosenPallete.count - 1) / 6) * 70 + 70
    }
    
    let fontSize: CGFloat = 40
}

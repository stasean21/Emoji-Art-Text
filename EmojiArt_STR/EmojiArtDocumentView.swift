//
//  EmojiArtDocumentView.swift
//  EmojiArt_STR
//
//  Created by Станислав Мунтяну on 06.12.2023.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document : EmojiArtDocument
    
    @State private var chosenPallete: String = ""
    @State private var explainBackgroundPaste = false
    @State private var confirmBackgroundPaste = false
    @State private var showTextAdder = false
    
    init(document: EmojiArtDocument){
        self.document = document
        _chosenPallete = State(wrappedValue: self.document.defaultPalette)
    }
    
    var body: some View {
        VStack {
            HStack {
                PalleteChooser(document: document, chosenPallete: $chosenPallete)
                ScrollView (.horizontal){
                    HStack {
                        ForEach(chosenPallete.map{String($0)}, id : \.self) { emoji in
                            Text(emoji)
                                .font(Font.system(size:self.defaultEmojiSize))
                                .onDrag {NSItemProvider(object: emoji as NSString)}
                        }
                    }
                }
            }
            HStack {
                Button(action: {
                    for emoji in document.selectedEmojis {
                        self.document.deleteEmoji(emoji)
                    }
                }) {
                    Text("Удалить")
                }
                
                Button(action: {
                    document.unSelectAllEmojis()
                }) {
                    Text("Снять выделения")
                }
            }
            .opacity(isSelection() ? 1 : 0)
            .padding()
            
            GeometryReader { geometry in
                ZStack{
                    Color.white.overlay(
                        OptionalImage(uiImage: self.document.backgroundImage)
                            .scaleEffect(!self.isSelection() ? self.zoomScale : document.steadyStateZoomScale)
                            .offset(self.panOffSet)
                    )
                    .gesture(self.doubleTapToZoom(in: geometry.size))
                    if self.isLoading {
                        Image(systemName: "hourglass")
                            .imageScale(.large)
                            .spinning()
                    } else {
                        ForEach(self.document.emojis){ emoji in
                            Text(emoji.text)
                                .border(Color.black, width: self.isEmojiSelected(emoji) ? 3 : 0)
                                .font(animatableWithSize: emoji.fontSize * zoomScale)
                                .scaleEffect(self.isEmojiSelected(emoji) ? self.emojiGestureZoomScale : 1.0)
                                .position(position(for: emoji, in: geometry.size))
                                .offset(self.isEmojiSelected(emoji) ? self.emojiOffset : CGSize(width:0, height:0))
                                .gesture(self.singleTapToSelect(emoji))
                                .gesture(self.isEmojiSelected(emoji) ? self.dragSelection() : nil)
                        }
                    }
                }
                .clipped()
                .gesture(self.panGesture())
                .gesture(self.zoomGesture())
                .edgesIgnoringSafeArea([.horizontal,.bottom])
                .onReceive(self.document.$backgroundImage){ image in
                    self.zoomToFit(image, in: geometry.size)
                }
                .onDrop(of: ["public.image", "public.text"], isTargeted: nil) { providers, location in
                    var location = geometry.convert(location,from: .global)
                    location = CGPoint(x: location.x - geometry.size.width/2, y: location.y - geometry.size.height/2)
                    location = CGPoint(x: location.x - self.panOffSet.width, y: location.y - self.panOffSet.height)
                    location = CGPoint(x: location.x / self.zoomScale, y: location.y / self.zoomScale)
                    return self.drop(providers: providers, at: location)
                }
                .navigationBarItems(trailing:
                                        HStack {
                                            //Кнопка вставки фона
                                            Button(action: {
                                                if let url = UIPasteboard.general.url , url != self.document.backgroundURL {
                                                    self.confirmBackgroundPaste = true
                                                } else{
                                                    self.explainBackgroundPaste = true
                                                }
                                            },
                                            label: {Image(systemName: "doc.on.clipboard").imageScale(.large)
                                                .alert(isPresented: self.$explainBackgroundPaste) { () -> Alert in
                                                    return Alert(title: Text("Вставка фона"),
                                                                 message: Text("Скопируйте URL изображения и нажмите кнопку"),
                                                                 dismissButton: .default(Text("OK")))
                                                }
                                            })
                                            //Кнопка вставки текста
                                         Image(systemName: "pencil")
                                            .imageScale(.large)
                                            .onTapGesture {
                                                self.showTextAdder = true
                                            }
                                            .popover(isPresented: $showTextAdder) {
                                                TextAdder(isShowing: self.$showTextAdder)
                                                    .environmentObject(self.document)
                                                    .frame(minWidth: 500, minHeight: 500)
                                            }
                        }
                )
            }
            .zIndex(-1)
        }
        .alert(isPresented: self.$confirmBackgroundPaste) {
            Alert(title: Text("Вставка фона"),
                  message: Text("Заменить ваш фон \(UIPasteboard.general.url?.absoluteString ?? "nothing")?."),
                  primaryButton: .default(Text("OK")){
                    self.document.backgroundURL = UIPasteboard.general.url
                  },
                  secondaryButton: .cancel()
            )
        }
    }
    
    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        location = CGPoint(x: location.x + size.width/2, y: location.y + size.height/2)
        location = CGPoint(x: location.x + panOffSet.width, y: location.y + panOffSet.height)
        return location
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            self.document.steadyStatePanOffset = .zero
            self.document.steadyStateZoomScale = min(hZoom,vZoom)
        }
    }
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture{
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    self.zoomToFit(self.document.backgroundImage, in: size)
                }
            }
    }
    
    var isLoading : Bool {
        document.backgroundURL != nil && document.backgroundImage == nil
    }
    
    private let defaultEmojiSize: CGFloat = 50
    
    
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    @GestureState private var gesturePanOffset: CGSize = .zero
    //Перетаскивание
    @GestureState private var gestureEmojiOffset: CGSize = .zero
    
    private var emojiOffset: CGSize {
        return  gestureEmojiOffset * zoomScale
    }
    
    private func dragSelection() -> some Gesture {
        DragGesture()
            .updating($gestureEmojiOffset) { latestDragEmojiGestureValue, gestureEmojiOffset, transaction in
                gestureEmojiOffset = latestDragEmojiGestureValue.translation / self.zoomScale
            }
            .onEnded { finalDragGesturePoint in
                for emoji in document.selectedEmojis {
                    self.document.moveEmoji(emoji, by: CGSize(width:finalDragGesturePoint.translation.width / self.zoomScale, height: finalDragGesturePoint.translation.height / self.zoomScale))
                }
            }
    }
    
    private var panOffSet: CGSize {
        (self.document.steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private var zoomScale: CGFloat {
        self.document.steadyStateZoomScale * gestureZoomScale
    }
    
    /* Масштабирование */
    @GestureState private var emojiGestureZoomScale: CGFloat = 1.0
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating(isSelection() ? $emojiGestureZoomScale : $gestureZoomScale) { latestGestureScale, valuezToZoomScale, transaction in
                valuezToZoomScale = latestGestureScale
            }
            .onEnded { finalGestureScale in
                if isSelection() {
                    for emoji in document.selectedEmojis {
                        self.document.scaleEmoji(emoji, by: finalGestureScale)
                    }
                } else {
                    self.document.steadyStateZoomScale *= finalGestureScale
                }
            }
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset){ latestDragGestureValue, gesturePanOffset, transaction in
                gesturePanOffset = latestDragGestureValue.translation / self.zoomScale
            }
            .onEnded { finalDragGestureValue in
                self.document.steadyStatePanOffset = self.document.steadyStatePanOffset + (finalDragGestureValue.translation / self.zoomScale)
            }
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self){ url in
            //print ("dropped \(url)")
            self.document.backgroundURL = url
        }
        if !found {
            found = providers.loadObjects(ofType: String.self){ string in
                self.document.addEmoji(string, at: location, size: defaultEmojiSize)
            }
        }
        return found
    }
    
    //Функции для выборки
    private func isSelection() -> Bool {
        document.selectedEmojis.count > 0
    }
    
    private func isEmojiSelected(_ emoji: EmojiArt.Emoji) -> Bool {
        document.selectedEmojis.contains(matching: emoji)
    }
    
    private func singleTapToUnSelect() -> some Gesture {
        TapGesture(count: 1)
            .onEnded {
                withAnimation(.linear(duration: 0.1)) {
                    self.document.unSelectAllEmojis()
                }
            }
    }
    
    private func singleTapToSelect(_ emoji: EmojiArt.Emoji) -> some Gesture {
        TapGesture(count: 1)
            .onEnded {
                withAnimation(.linear(duration: 0.1)) {
                    self.document.selectEmoji(emoji)
                }
            }
    }
}


//
//  EmojiArt.swift
//  EmojiArt_STR
//
//  Created by Станислав Мунтяну on 11.12.2023.
//

import Foundation

struct EmojiArt: Codable {
    
    var json : Data? {
        return try? JSONEncoder().encode(self)
    }
    
    init? (json: Data?){
        if json != nil,
           let newEmojiArt = try? JSONDecoder().decode(EmojiArt.self, from: json!) {
            self = newEmojiArt
        }
    }
    
    init(){
        
    }
    var backgroundURL: URL?
    var emojis = [Emoji]()
    
    struct Emoji: Identifiable, Codable, Hashable{
        let text: String
        var x: Int
        var y: Int
        var size: Int
        let id : Int
    
    
        fileprivate init (text: String, x:Int, y: Int, size: Int, id: Int){
            self.text = text
            self.x = x
            self.y = y
            self.size = size
            self.id = id
        }
    }
    
    private var uniqieEmojiId = 0
    
    mutating func addEmoji(_ text : String , x: Int , y : Int , size : Int){
        uniqieEmojiId += 1
        emojis.append(Emoji(text: text, x: x, y: y, size: size, id: uniqieEmojiId))
    }
}

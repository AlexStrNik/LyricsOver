//
//  AXUIElement+Attributes.swift
//  LyricsOver
//
//  Created by Aleksandr Strizhnev on 30.12.2024.
//

import ApplicationServices

extension AXUIElement {
    func attribute(_ attribute: String) -> AnyObject? {
        var attributeValue: AnyObject?
        AXUIElementCopyAttributeValue(
            self,
            attribute as CFString,
            &attributeValue
        )
        
        return attributeValue
    }
    
    var attributes: [String: AnyObject] {
        var attributes: CFArray?
        AXUIElementCopyAttributeNames(self, &attributes)
        
        guard let attributes else {
            return [:]
        }
        
        return (attributes as! [String]).reduce(into: [:]) { result, attribute in
            let value = self.attribute(attribute)
            result[attribute as String] = value
        }
    }
    
    var description: String? {
        return attribute(kAXDescription) as? String
    }
    
    var title: String? {
        return attribute(kAXTitleAttribute) as? String
    }
    
    var role: String {
        return attribute(kAXRoleAttribute) as! String
    }
    
    var prefferedLanguage: String? {
        return attribute("AXPreferredLanguage") as? String
    }
    
    var frame: CGRect {
        var frameValue: CFTypeRef?
        AXUIElementCopyAttributeValue(
            self,
            "AXFrame" as CFString,
            &frameValue
        )
        
        var frame = CGRect.zero
        
        guard let frameValue else {
            return frame
        }
        
        AXValueGetValue(
            frameValue as! AXValue,
            AXValueType.cgRect,
            &frame
        )
        
        return frame
    }
    
    var children: [AXUIElement]? {
        var count: CFIndex = 0
        var result = AXUIElementGetAttributeValueCount(self, kAXChildrenAttribute as CFString, &count)
        
        var children: CFArray?
        result = AXUIElementCopyAttributeValues(self, kAXChildrenAttribute as CFString, 0, count, &children)
        if result != .success {
            return nil
        }
        
        return children as? [AXUIElement]
    }
}

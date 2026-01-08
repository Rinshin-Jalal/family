//
//  InputMode.swift
//  StoryRide
//

import Foundation
import SwiftUI

public enum InputMode: String, CaseIterable, Identifiable {
    case recording
    case audioUpload
    case documentUpload
    case imageUpload
    case typing
    
    public var id: String { self.rawValue }
    
    public var icon: String {
        switch self {
        case .recording: return "mic.fill"
        case .audioUpload: return "waveform"
        case .documentUpload: return "doc.fill"
        case .imageUpload: return "photo.fill"
        case .typing: return "text.bubble.fill"
        }
    }
    
    public var title: String {
        switch self {
        case .recording: return "Record"
        case .audioUpload: return "Audio"
        case .documentUpload: return "Document"
        case .imageUpload: return "Photo"
        case .typing: return "Type"
        }
    }
}

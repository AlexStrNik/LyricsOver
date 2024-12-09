//
//  LyricsOverlay.swift
//  LyricsOver
//
//  Created by Aleksandr Strizhnev on 07.12.2024.
//

import Combine
import SwiftUI

struct WaitForLyrics: View {
    @State private var shouldAnimate: Bool = false
    
    var body: some View {
        HStack {
            Circle()
                .frame(width: 8, height: 8)
                .opacity(shouldAnimate ? 1.0 : 0.5)
                .animation(.easeInOut(duration: 0.6).repeatForever(), value: shouldAnimate)
            Circle()
                .frame(width: 8, height: 8)
                .opacity(shouldAnimate ? 1.0 : 0.5)
                .animation(.easeInOut(duration: 0.6).repeatForever().delay(0.2), value: shouldAnimate)
            Circle()
                .frame(width: 8, height: 8)
                .opacity(shouldAnimate ? 1.0 : 0.5)
                .animation(.easeInOut(duration: 0.6).repeatForever().delay(0.4), value: shouldAnimate)
        }
        .onAppear {
            shouldAnimate = true
        }
    }
}

struct LyricsOverlay: View {
    var lyricsPublisher: AnyPublisher<[String], Never>
    var currentPublisher: AnyPublisher<Int, Never>
    
    @State private var lyrics: [String] = []
    @State private var current: Int = 0
    
    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(lyrics.enumerated()), id: \.offset) { offset, lyric in
                        Group {
                            if lyric.isEmpty {
                                WaitForLyrics()
                            } else {
                                Text(lyric)
                                    .font(.largeTitle.weight(.bold))
                                    .opacity(offset == current ? 1.0 : 0.5)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .id(offset)
                    }
                }
                .padding(.bottom, 128)
                .padding(16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .onReceive(lyricsPublisher) { newLyrics in
                lyrics = newLyrics.map {
                    $0.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                withAnimation(.easeInOut(duration: 0.5)) {
                    scrollView.scrollTo(0, anchor: .init(x: 0, y: 0.2))
                    current = 0
                }
            }
            .onReceive(currentPublisher) { newCurrent in
                if current != newCurrent {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        scrollView.scrollTo(newCurrent, anchor: .init(x: 0, y: 0.2))
                        current = newCurrent
                    }
                }
            }
        }
        .compositingGroup()
        .shadow(color: .black, radius: 4)
        .mask {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .black, location: 0.2),
                    .init(color: .black, location: 0.7),
                    .init(color: .clear, location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .disabled(true)
    }
}

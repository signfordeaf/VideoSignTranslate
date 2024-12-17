import AVKit
import Combine
import Foundation
import Kingfisher
import SwiftUI

@available(iOS 14.0, *)
struct GIFPlayerView: View {
    @State private var gifPosition: CGSize = CGSize(width: .zero, height: 150)
    @State private var lastDragPosition: CGSize = CGSize(
        width: .zero, height: 150)
    @State private var isPlaying: Bool = true
    @State private var currentTime: Double = 0.0
    @State private var currentQIndex: Int = 0
    @State private var timeObserverToken: Any?

    let signDataList: [SignData]
    let player: AVPlayer
    let videoGeometry: GeometryProxy

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isPlaying && !signDataList.isEmpty {
                    GIFView(
                        signData: getCurrentSignData(),
                        gifPosition: $gifPosition,
                        lastDragPosition: $lastDragPosition,
                        videoGeometry: videoGeometry,
                        geometrySize: geometry.size,
                        onGifFinished: advanceToNextGif
                    )
                }
            }
        }
        .onAppear {
            startListeningToPlayer()
        }
    }

    private func getCurrentSignData() -> SignData? {
        // SignData listesinin boş olmadığından emin ol
        guard !signDataList.isEmpty else {
            isPlaying = false
            return nil
        }

        let sortedSignData = signDataList.sorted { $0.q ?? 0 < $1.q ?? 0 }

        // Index kontrolü
        guard currentQIndex < sortedSignData.count else {
            isPlaying = false
            return nil
        }

        let currentSignData = sortedSignData[currentQIndex]

        print("-----------------")
        print("Current Q: \(currentSignData.q ?? 0)")
        print("Current VU: \(currentSignData.vu ?? "")")
        print("Current VD: \(currentSignData.vd ?? 0)")

        // Sonraki gif bilgisini yazdır (eğer varsa)
        if currentQIndex + 1 < sortedSignData.count {
            let nextSignData = sortedSignData[currentQIndex + 1]
            print(
                "Sonraki GIF - Q: \(nextSignData.q ?? 0), VU: \(nextSignData.vu ?? "")"
            )
        } else {
            print("Sonraki GIF - Q: YOK, VU: YOK")
        }
        print("-----------------")

        // Video zamanı kontrolü
        guard let st = currentSignData.st, currentTime >= st else {
            return nil
        }

        return currentSignData
    }

    private func advanceToNextGif() {
        // Sonraki indexe geç
        currentQIndex += 1

        // Sıralanmış listeyi tekrar al
        let sortedSignData = signDataList.sorted { $0.q ?? 0 < $1.q ?? 0 }

        // Eğer tüm gif'ler tamamlandıysa
        if currentQIndex >= sortedSignData.count {
            isPlaying = false
            stopListeningToPlayer()
        } else {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + (sortedSignData[currentQIndex].vd ?? 0.0)
            ) {
                advanceToNextGif()
            }
        }
    }

    private func startListeningToPlayer() {
        // Daha sık aralıklarla ve daha uzun süre gözlem yapacak şekilde ayarla
        timeObserverToken = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 10),
            queue: .main
        ) { [self] time in
            Task { @MainActor in
                self.currentTime = time.seconds
                if !self.isPlaying {
                    self.stopListeningToPlayer()
                }
            }
        }
    }

    private func stopListeningToPlayer() {
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }
}

@available(iOS 14.0, *)
struct GIFView: View {
    let signData: SignData?
    @Binding var gifPosition: CGSize
    @Binding var lastDragPosition: CGSize
    let videoGeometry: GeometryProxy
    let geometrySize: CGSize
    var onGifFinished: () -> Void

    // Gif süresi için state ekledik
    @State private var gifDuration: Double = 1.0

    var body: some View {
        if let signData = signData, let vu = signData.vu {
            KFAnimatedImage(URL(string: vu))
                .scaledToFit()
                .frame(width: 150, height: 150)
                .position(
                    x: geometrySize.width / 2 + gifPosition.width,
                    y: geometrySize.height / 2 + gifPosition.height
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let newX =
                                lastDragPosition.width + value.translation.width
                            let newY =
                                lastDragPosition.height
                                + value.translation.height

                            // Sınır kontrolü
                            let gifHalfSize: CGFloat = 50  // GIF'in yarıçapı
                            let videoWidth = videoGeometry.size.width
                            let videoHeight = videoGeometry.size.height

                            // Yeni X ve Y pozisyonlarını video boyutlarıyla sınırla
                            gifPosition.width = min(
                                max(
                                    newX,
                                    -videoWidth / 2 + gifHalfSize),
                                videoWidth / 2 - gifHalfSize)
                            gifPosition.height = min(
                                max(
                                    newY,
                                    -videoHeight / 2 + gifHalfSize),
                                videoHeight / 2 - gifHalfSize)
                        }
                        .onEnded { _ in
                            // Drag bittiğinde son pozisyonu kaydet
                            lastDragPosition = gifPosition
                        }
                )
                .onAppear {
                    print("gifin onAppear fonk giriş yaptı!!")

                    if let vd = signData.vd {
                        DispatchQueue.main.asyncAfter(
                            deadline: .now() + vd
                        ) {
                            onGifFinished()
                        }
                    }
                }
        }
    }
}

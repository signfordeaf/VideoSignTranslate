import AVKit
import ImageIO
import Kingfisher
import SwiftUI

@available(iOS 15.0, *)
public struct CustomVideoPlayerView<Content: View>: View {
    let videoURL: URL
    let gifName: String
    let videoPlayer: Content
    let playerContent: AVPlayer

    @State var storage = StorageManager()
    @State private var gifPosition: CGSize = CGSize(width: .zero, height: 150)
    @State private var lastDragPosition: CGSize = CGSize(
        width: .zero, height: 150)

    let apiService = ApiService.shared

    public init(
        videoURL: URL, videoAssetName: String?, gifName: String,
        videoPlayer: Content, playerC: AVPlayer
    ) {
        self.videoURL = videoURL
        self.gifName = gifName
        self.videoPlayer = videoPlayer
        self.playerContent = playerC
    }

    func fetchSignCache(bundleId: String) {
        let data = storage.find(by: bundleId)
        if data != nil {
            apiService.wesignGet(
                videoBundleId: VideoSignController.shared
                    .initVideoBundleURL(videoURL),
                videoPath:
                    data?.videoPath ?? ""
            ) { result in
                switch result {
                case .success(let signModel):
                    let updateData = data!.copyWith(signModel: signModel)
                    Task {
                        @MainActor in
                        storage.save(model: updateData)
                    }
                case .failure(let error):
                    print(error)
                }

            }
        } else {
            apiService
                .wesignUploadFile(
                    videoBundleURL: videoURL
                ) { result in
                    switch result {
                    case .success(_):
                        return
                    case .failure(_):
                        return
                    }
                }

        }
    }

    func saveSignCacheData() async {
        storage
            .save(
                model: SignCacheModel(
                    videoType: "url",
                    videoPath: videoURL.relativePath,
                    videoURL: videoURL.lastPathComponent,
                    videoBundleId:
                        VideoSignController.shared.initVideoBundleURL(videoURL),
                    signModel: nil
                )
            )
    }

    func getSignData() -> [SignData] {
        //        let signMockData = [
        //            SignData(
        //                st: 1.792, et: 7.936,
        //                vu:
        //                    "https://cdn01.signfordeaf.com/9b34cdd1-32ff-4d3d-b3b5-f1e27dee570a.gif",
        //                vd: 15.16, s: "aa", q: 0
        //            ),
        //            SignData(
        //                st: 8.192, et: 10.752,
        //                vu:
        //                    "https://cdn01.signfordeaf.com/2d26e005-ef6a-4a70-ad12-5420c52f7b35.gif",
        //                vd: 14.86, s: "aa", q: 1
        //            ),
        //            SignData(
        //                st: 11.008, et: 12.032,
        //                vu:
        //                    "https://cdn01.signfordeaf.com/b672094c-7c09-4a7b-b9a2-b36ed6c362a0.gif",
        //                vd: 4.8, s: "aa", q: 2
        //            ),
        //        ]
        let data =
            storage
            .find(
                by:
                    VideoSignController.shared
                    .initVideoBundleURL(videoURL)
            )
        if let data {
            let signData = data.signModel?.data
            return signData ?? []
        }
        return []
    }

    public var body: some View {
        GeometryReader { geometry in
            GeometryReader { videoGeometry in
                ZStack {
                    videoPlayer.onAppear {
                        self.fetchSignCache(
                            bundleId: VideoSignController.shared
                                .initVideoBundleURL(videoURL))
                        //                        apiService.wesignGet(
                        //                            videoBundleId: VideoSignInit.shared
                        //                                .initVideoBundleURL(videoURL),
                        //                            videoPath:
                        //                                "/home/akilliceviribilisim/WeAccessApp/media/uploads/a87e5a5ba0e041c6a05248d14d82f113.mp4"
                        //                        ) { result in
                        //                            switch result {
                        //                            case .success(let signModel):
                        //                                Task { @MainActor in
                        //                                    fetchSignCache(
                        //                                        bundleId: VideoSignInit.shared
                        //                                            .initVideoBundleURL(videoURL),
                        //                                        signModel: signModel
                        //                                    )
                        //                                }
                        //                                print(signModel)
                        //                            case .failure(let error):
                        //                                print(error)
                        //                            }
                        //
                        //                        }
                    }
                    GIFPlayerView(
                        signDataList: getSignData(),
                        player: self.playerContent,
                        videoGeometry: videoGeometry
                    )

                    // GIF Layer
                    //                    KFAnimatedImage(URL(string: "https://cdn01.signfordeaf.com/9b34cdd1-32ff-4d3d-b3b5-f1e27dee570a.gif"))
                    //                        .scaledToFit()
                    //                        .frame(width: 150, height: 150)
                    //                        .offset(gifPosition)
                    //                        .gesture(
                    //                            DragGesture()
                    //                                .onChanged { value in
                    //                                    let newX =
                    //                                        lastDragPosition.width
                    //                                        + value.translation.width
                    //                                    let newY =
                    //                                        lastDragPosition.height
                    //                                        + value.translation.height
                    //                                    // Sınır kontrolü
                    //                                    let gifHalfSize: CGFloat = 50  // GIF'in yarıçapı
                    //                                    let videoWidth = videoGeometry.size
                    //                                        .width
                    //                                    let videoHeight = videoGeometry.size
                    //                                        .height
                    //
                    //                                    // Yeni X ve Y pozisyonlarını video boyutlarıyla sınırla
                    //                                    gifPosition.width = min(
                    //                                        max(
                    //                                            newX,
                    //                                            -videoWidth / 2 + gifHalfSize),
                    //                                        videoWidth / 2 - gifHalfSize)
                    //                                    gifPosition.height = min(
                    //                                        max(
                    //                                            newY,
                    //                                            -videoHeight / 2 + gifHalfSize),
                    //                                        videoHeight / 2 - gifHalfSize)
                    //                                }
                    //                                .onEnded { _ in
                    //                                    // Drag bittiğinde son pozisyonu kaydet
                    //                                    lastDragPosition = gifPosition
                    //                                }
                    //                        )
                }
            }
        }
    }

}

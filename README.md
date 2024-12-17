# Video Sign Translate

## 🛠️ Install Package    
### Swift Package Manager
Add this package to your project using Swift Package Manager in Xcode.

   1. Open your project in Xcode.
   2. Select **Add Packages** from the **File** menu.
   3. Enter the following GitHub repo URL:
        
    https://github.com/signfordeaf/VideoSignTranslate.git
  
### Manual Installation

   1. Clone this repository.
   2. Copy it to your project and include the Swift files in the package into the project.

## ⚙️ Activation
Activate the package with the API key and request URL given to you on this page.
```swift
import VideoSignTranslate

@main
struct WeSignExampleApp: App {

    init() {
        VideoSignController.shared.initialize(apiKey: "YOUR-API-KEY")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

```

## 🧑🏻‍💻 Usage

###  📄UIScreen File
```swift
...
import VideoSignTranslate
...

struct ContentView: View {

    @State private var player: AVPlayer?

    var body: some View {
        VStack {
            ...
            if let player = player {
                SignVideoPlayerView(
                    videoURL:  nil,
                    videoAssetName: Bundle.main.url(forResource: "YOUR-FILE-NAME", withExtension: "mp4")!, // Only .mp4 videos!
                    videoPlayer: VideoPlayer(player: player),
                    playerC: player
                )
            ...
        }
    }
}

#Preview {
    ContentView()
}
```
        

        

        

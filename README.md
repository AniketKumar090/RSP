# Gesture-Based Rock Scissors Paper Game

A real-time computer vision-based iOS game that lets you play rock-paper-scissors using hand gestures.

## Features

- Real-time hand gesture recognition using CoreML
- Live camera feed processing with 30 FPS performance
- 95%+ accuracy in gesture classification
- Efficient multi-threaded frame processing
- Seamless camera integration using AVFoundation

## Technical Stack

- Swift
- CoreML for machine learning implementation
- AVFoundation for video capture and processing
- Multi-threading for optimized performance

## Requirements

- iOS 13.0+
- Xcode 12.0+
- Swift 5.0+
- iPhone with camera access

## Installation

1. Clone the repository
```bash
git clone https://github.com/AniketKumar090/RSP.git
cd RSP
```

2. Open the .xcodeproj file in Xcode
```bash
open RSP.xcodeproj
```
3. Build and run the project on your iOS device

## Usage

1. Launch the app and grant camera permissions
2. Hold your hand in front of the camera
3. Make one of three gestures (rock, paper, or scissors)
4. The app will recognize your gesture and play against you

## Performance Optimization

- Implemented efficient frame processing
- Utilized multi-threading for smooth performance
- Optimized video capture pipeline using AVFoundation
- Achieved consistent 30 FPS processing speed

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License - see the LICENSE.md file for details

## Contact

For any queries or support, please contact:
- Aniket Kumar
- Email: kumaraniket009@gmail.com
- GitHub: @AniketKumar090

## Version History

- 1.0.0
  - Initial release
  - Basic product management functionality
  - Offline support

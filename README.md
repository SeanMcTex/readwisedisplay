# Readwise Quote Display

A beautiful, minimalist app that displays random quotes from your Readwise library with elegant animations and automatic refresh functionality. Available for both macOS and iPad.

![App Screenshot](screenshot.png)

## Features

- **Beautiful Display**: Large, readable typography optimized for different screen sizes
- **Smart Quote Fetching**: Intelligently fetches random quotes from your entire Readwise library
- **Automatic Refresh**: Configurable timer for automatic quote updates (5-300 seconds)
- **Tap to Refresh**: Tap anywhere on the screen to instantly get a new quote
- **Smooth Animations**: Elegant slide-in transitions when quotes change
- **Dynamic Backgrounds**: Subtle color changes with each new quote
- **Cross-Platform**: Native support for both macOS and iPad with responsive design
- **Rich Data**: Automatically fetches missing author/book information when available
- **Secure Storage**: API keys are stored securely in the system keychain

## Installation

### Requirements
- macOS 13.0+ or iPadOS 16.0+
- Xcode 15.0+ (for building from source)
- Active Readwise account with API access

### Building from Source

1. Clone this repository:

```
bash
git clone https://github.com/yourusername/readwise-display.git
cd readwise-display
```

2. Open `ReadwiseDisplay.xcodeproj` in Xcode

3. Select your target platform (macOS or iPad)

4. Build and run the project

## Setup

### Getting Your Readwise API Key

1. Visit [Readwise Access Token page](https://readwise.io/access_token)
2. Log in to your Readwise account
3. Copy your API token

### Configuring the App

**macOS:**
- Use the native Settings menu (ReadwiseDisplay → Settings...)

**iPad:**
- Tap the gear icon in the top-right corner of the main screen

Enter your API key and configure your preferred refresh interval.

## Usage

### Main Interface
- **Tap anywhere** on the main screen to refresh the quote immediately
- The app automatically fetches new quotes based on your configured interval
- Background colors subtly change with each new quote for variety

### Settings
- **Refresh Interval**: Set how often quotes auto-refresh (5-300 seconds)
- **API Key**: Enter and manage your Readwise API token
- **Visibility Toggle**: Show/hide your API key while editing

## Technical Details

### Architecture
- **SwiftUI**: Modern declarative UI framework
- **Async/Await**: Modern concurrency for network operations
- **@AppStorage**: Secure, persistent settings storage
- **Cross-Platform**: Shared codebase with platform-specific optimizations

### Quote Fetching Algorithm
The app uses an intelligent approach to ensure true randomness:

1. **Count Caching**: Fetches total highlight count once and caches it
2. **Random Page Selection**: Calculates total pages and selects a random page
3. **Random Highlight**: Picks a random highlight from the selected page
4. **Data Enrichment**: Automatically fetches missing book/author details when available

### Responsive Design
- **Dynamic Font Scaling**: Automatically adjusts text size based on device and orientation
- **iPad Pro Support**: Larger fonts and spacing for 12.9" displays
- **Orientation Aware**: Different layouts for portrait and landscape modes
- **Safe Area Handling**: Proper support for notches, home indicators, and rounded corners

## Privacy & Security

- **Local Storage**: All settings stored locally on your device
- **Secure API Storage**: API keys stored in system keychain
- **No Tracking**: No analytics, telemetry, or user tracking
- **Network Only**: Only communicates with Readwise API servers

## Troubleshooting

### Common Issues

**"API key required" message:**
- Ensure you've entered your API key in Settings
- Verify the key is correct by checking the Readwise website
- Make sure your internet connection is working

**No quotes appearing:**
- Check that you have highlights in your Readwise library
- Verify your API key has the necessary permissions
- Try refreshing manually by tapping the screen

**App won't compile:**
- Ensure you're using Xcode 15.0 or later
- Check that all required frameworks are available
- Clean build folder and rebuild

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Make your changes
4. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
5. Push to the branch (`git push origin feature/AmazingFeature`)
6. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Readwise](https://readwise.io) for providing the excellent API
- The SwiftUI community for inspiration and best practices
- All contributors who help improve this project

## Support

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/yourusername/readwise-display/issues) page
2. Create a new issue with detailed information about your problem
3. Include your platform (macOS/iPad) and OS version

---

**Enjoy your daily dose of wisdom!** 📚✨

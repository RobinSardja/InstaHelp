# InstaHelp

A faster and more discreet emergency contact solution

## First-Time Setup

### 1. Clone our GitHub repo

The fully functional InstaHelp prototype is available on our [GitHub](https://github.com/RobinSardja/InstaHelp). Visit the link to download our ZIP file or use git to clone our repository with the following command.
```console
git clone https://github.com/RobinSardja/InstaHelp.git
```

### 2. Download the Flutter SDK

Running InstaHelp requires [the Flutter SDK](https://docs.flutter.dev/get-started/install). All instructions for getting started on all major platforms are available through the provided link.

<img src="docs/img/flutter website.png">

### 3. Sign Up with Picovoice

Our voice activation feature requires an access key from [Picovoice](https://console.picovoice.ai/signup). Your account will provide you with your own access key to enable the Picovoice API.

<img src="docs/img/picovoice website.png">

### 4. Flutter run

Open a terminal in the same directory as the InstaHelp repository. You'll first need to get all of our dependencies with the following command.

```console
flutter pub get
```

Now run The Flutter SDK with your Picovoice access key. For example, if "abcd" is your access key, enter the following command into your terminal.
```console
flutter run --dart-define=picovoice=abcd
```
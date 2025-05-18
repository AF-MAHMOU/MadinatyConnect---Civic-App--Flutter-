1. Clone the Repository
Open GitHub Desktop

Go to File > Clone Repository

Paste the repo URL and choose a folder

Click Clone

2. Open the Project
Open the cloned folder in VS Code or Android Studio

3. Install Dependencies
Open a terminal in the project root and run:

flutter clean
flutter pub get
npm install
4. Connect Firebase (1st Time Only)
In the terminal:

firebase login
firebase use --add
Select the project: madinatyconnect

This links the local project to the correct Firebase setup

5. Run the App
Start an emulator or connect a device, then run:


Missing Features / Next Steps:
- Add poll expiration or voting limits
- Messaging system between advertiser and admin
- Messaging system between citizen and admin


flutter run

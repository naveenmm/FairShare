---
description: How to deploy the Split Bills app to Flutter Web
---

# Deploying Split Bills to the Web

There are many ways to host a Flutter web app. The most common free options are **GitHub Pages**, **Firebase Hosting**, and **Vercel**.

## 1. Build the Application
First, you must generate the optimized web files. Run this command in your terminal:

```powershell
flutter build web --release
```
This will create a folder at `build/web/`. These are the files you need to upload to your server.

## 2. Deploy to GitHub Pages (Recommended)
This is free and works directly with your repository.

### Manual Steps:
1. Initialize a Git repository if you haven't (we did this earlier).
2. Install the `gh-pages` package for easier deployment:
   ```powershell
   npm install -g gh-pages
   ```
3. Run the deployment command:
   ```powershell
   gh-pages -d build/web
   ```

### Using GitHub Actions (Automated):
You can also set up a workflow to deploy every time you push to the `master` branch. Let me know if you'd like me to create this for you!

## 3. Local Testing
Before you deploy, you can test the production build locally:
```powershell
# From the project root
cd build/web
python -m http.server 8000
```
Then visit `http://localhost:8000` in your browser.

> [!TIP]
> **Base Href**: If you are deploying to a subfolder (e.g., `username.github.io/split_bills/`), you must build with:
> `flutter build web --release --base-href "/split_bills/"`

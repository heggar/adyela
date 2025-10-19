# Flutter Web Deployment - Adyela Patient

## Running Locally

```bash
# Run in debug mode
flutter run -d chrome

# Run in debug mode with specific port
flutter run -d chrome --web-port=8080

# Run in release mode
flutter run -d chrome --release
```

## Building for Production

```bash
# Build for web
flutter build web --release

# Build with base href (for subdirectory deployment)
flutter build web --release --base-href /patient/

# Build output is in: build/web/
```

## Deployment Options

### Firebase Hosting

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize (first time only)
firebase init hosting

# Deploy
firebase deploy --only hosting
```

### Vercel

```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel --prod
```

### Google Cloud Storage + CDN

```bash
# Build for production
flutter build web --release

# Upload to GCS bucket
gsutil -m rsync -r -d build/web gs://adyela-patient-web

# Set cache control
gsutil -m setmeta -h "Cache-Control:public, max-age=3600" gs://adyela-patient-web/**

# Enable CDN
gcloud compute backend-buckets update adyela-patient-backend \
  --enable-cdn
```

## Progressive Web App (PWA) Support

The app is configured as a PWA:

- ✅ Service Worker for offline support
- ✅ App manifest for install prompt
- ✅ Responsive design
- ✅ Fast loading with code splitting

### Testing PWA

1. Build for production: `flutter build web --release`
2. Serve locally: `python -m http.server 8000 -d build/web`
3. Open Chrome DevTools > Application > Service Workers
4. Test offline mode

## Performance Optimization

### Code Splitting

Flutter web automatically splits code. To optimize further:

```dart
// Use deferred loading
import 'package:flutter/material.dart' deferred as material;

// Load when needed
material.loadLibrary().then((_) {
  // Use material
});
```

### Image Optimization

- Use WebP format for images
- Lazy load images with `cached_network_image`
- Use image CDN (Cloudinary, Imgix)

### Bundle Size

```bash
# Analyze bundle size
flutter build web --release --analyze-size

# Output:
# Size of main.dart.js: 1.2 MB
# Size of flutter_service_worker.js: 500 B
```

## Browser Compatibility

| Browser | Version | Support |
| ------- | ------- | ------- |
| Chrome  | 87+     | ✅ Full |
| Firefox | 78+     | ✅ Full |
| Safari  | 14+     | ✅ Full |
| Edge    | 88+     | ✅ Full |

## Known Limitations

1. **No native features** (camera, bluetooth) without plugins
2. **Larger bundle size** compared to native (~2MB initial)
3. **Performance** slightly lower than native on mobile

## Multi-Platform Shared Code

The app shares **85%+ code** with iOS and Android versions:

- ✅ All business logic (domain + data layers)
- ✅ All UI widgets (presentation layer)
- ✅ Shared packages (flutter-core, flutter-shared)
- ❌ Platform-specific code only for native features

## Environment Variables

```bash
# Development
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000

# Staging
flutter build web --release --dart-define=API_BASE_URL=https://staging.adyela.care

# Production
flutter build web --release --dart-define=API_BASE_URL=https://api.adyela.care
```

## SEO Considerations

Flutter web uses JavaScript rendering. For better SEO:

1. **Use Firebase Hosting** with pre-rendering
2. **Add meta tags** in index.html
3. **Generate sitemap.xml**
4. **Use proper titles** for routes

## Monitoring

### Firebase Analytics

```dart
FirebaseAnalytics.instance.logEvent(
  name: 'page_view',
  parameters: {'page': 'search'},
);
```

### Performance Monitoring

```dart
final trace = FirebasePerformance.instance.newTrace('search_professionals');
await trace.start();
// ... perform search
await trace.stop();
```

## Continuous Deployment

### GitHub Actions

```yaml
name: Deploy Web

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build web --release
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
```

## Version

- **App Version**: 0.1.0
- **Flutter**: 3.24+
- **Target**: Web (Chrome, Firefox, Safari, Edge)
- **Last Updated**: 2025-01-18

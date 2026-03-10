Build a production-ready **Event Photo Finder mobile app** with a clean modular architecture. The project must generate a **basic but complete working structure** that can later scale.

Tech stack:

* Mobile app: Flutter (Android first)
* Backend: Supabase (database + API)
* Image storage: Cloudflare R2 + CDN
* Payments: Razorpay (₹500 one-time event unlock)
* Ads: Start.io (interstitial ads)
* Admin panel: simple web dashboard
* Image format: WebP optimized
* Goal: users search event photos and unlock each photo after watching an ad.

---

APP NAME
Event Photo Finder

---

CORE USER FLOW

1. User opens app.
2. Home screen displays list of events.
3. User selects event.
4. Gallery grid loads thumbnails.
5. User taps photo.
6. Interstitial ad plays.
7. Photo unlocks and displays.
8. Photo can be viewed only once per device.
9. Optional: user can purchase ₹500 event unlock via Razorpay to disable ads.

---

PROJECT STRUCTURE

Flutter structure:

lib/
main.dart
app.dart

core/
config.dart
constants.dart

services/
supabase_service.dart
ads_service.dart
payment_service.dart
photo_service.dart

models/
event_model.dart
photo_model.dart

screens/
splash_screen.dart
home_screen.dart
event_screen.dart
gallery_screen.dart
photo_viewer_screen.dart
payment_screen.dart

widgets/
photo_grid_item.dart
event_card.dart
loading_indicator.dart

utils/
device_helper.dart
image_helper.dart

---

DATABASE STRUCTURE (Supabase)

Table: events

id (uuid)
title (text)
event_date (date)
cover_image (text)
price (integer default 500)
created_at (timestamp)

Table: photos

id (uuid)
event_id (uuid)
image_url (text)
thumbnail_url (text)
created_at (timestamp)

Table: views

id (uuid)
photo_id (uuid)
device_id (text)
viewed_at (timestamp)

Table: users

id (uuid)
device_id (text)
is_subscribed (boolean)
created_at (timestamp)

---

STORAGE STRUCTURE (Cloudflare R2)

Bucket: event-photos

/events/
event1/
thumb/
photo1.webp
photo2.webp

full/
photo1.webp
photo2.webp

---

IMAGE OPTIMIZATION RULES

All uploaded images must be processed before storage.

Full image
width: 1280px
format: WebP
quality: 75
approx size: 200-300KB

Thumbnail
width: 400px
format: WebP
approx size: 30-40KB

---

GALLERY PERFORMANCE RULES

Gallery loads thumbnails only.
Full image loads only after user taps photo.

Use lazy loading and pagination.

---

PHOTO UNLOCK LOGIC

When user taps photo:

1. Check database if device_id already viewed photo.
2. If viewed → show blurred image with message.
3. If not viewed → play interstitial ad.
4. After ad → insert record into views table.
5. Show full photo.

---

ADS IMPLEMENTATION

Use Start.io interstitial ads.

Trigger ads at:

* first photo view
* every next photo view

Ad flow:

Tap photo
→ show ad
→ unlock photo

---

PAYMENT FLOW

Use Razorpay checkout.

₹500 unlock logic:

If payment success:

update users.is_subscribed = true

When subscribed:

* ads disabled
* unlimited photo viewing for that event

---

ADMIN PANEL FEATURES

Simple web dashboard (can run on Netlify).

Features:

Create Event
Upload Photos (ZIP upload)
Auto compress images
Upload to Cloudflare R2
Save URLs in Supabase
View events list
Delete event

---

SECURITY

Image URLs should not be permanent public links.

Use signed URLs generated via backend.

Example:

cdn.domain.com/photo.webp?token=abc123&expire=300

Expire after 5 minutes.

---

SCALABILITY RULES

System must support:

* 10,000+ daily users
* CDN image delivery
* Supabase API calls
* caching for gallery requests

---

UI DESIGN

Minimal and fast.

Screens:

Splash
Home (events list)
Event details
Photo gallery grid
Photo viewer
Subscription page

Use modern card UI and large photo thumbnails.

---

DELIVERABLE

Generate the following:

1. Full Flutter starter project.
2. Supabase API integration.
3. Photo gallery grid.
4. Photo viewer with unlock logic.
5. Razorpay payment integration placeholder.
6. Start.io ad service placeholder.
7. Clean modular folder structure.

# Encore

Encore is an iOS app for keeping photos, notes and details from concerts in one place. It helps people remember the shows they attended and revisit the moments that mattered to them. 

This project was built for Assessment 3 of Advanced iOS Development. 

## Why I built it

After a concert, photos often get buried in the camera roll. Details such as the venue, date and favourite moments can become harder to remember over time. 

Encore groups photos and written memories under each concert, making them easier to find and revisit. 

The app is designed for people who regularly attend concerts and want a personal record of their experiences. 

## Features

- Record concerts with an artist, venue and date. 
- Browse past concerts and filter by year. 
- Edit concert details while keeping their memories attached. 
- Save a written memory, a photo, or both. 
- View memories from newest to oldest. 
- Swipe left to delete a memory. 
- Delete a concert and its memories after confirmation. 
- Share a photo from another app directly into a concert. 
- See the latest memory in a small or medium Home Screen widget.

Each memory currently supports one photo. 

## Screens

1. Concert Library: browse saved concerts and filter by year.
2. Add Concert: enter the details of a concert.
3. Concert Details: view the concert and its memories.
4. Add Memory: add a photo, caption, or both.
5. Edit Concert: update an existing concert’s details.

## Architecture

The main app follows this structure:

**SwiftUI Views → ViewModels → Use Cases → Repository Protocols → Core Data**

SwiftUI views handle the interface, while view models hold screen state and error messages. Use cases handle the actual operations and their rules. For example, a concert needs an artist and venue, its date cannot be in the future, and a memory must contain text or a photo.

The use cases are:

- `RecordAttendedConcert`
- `BrowseConcertHistory`
- `AddConcertMemory`
- `RevisitConcertMemories`
- `EditConcert`
- `DeleteConcertMemory`
- `DeleteConcert`

The domain models are `Concert`, `ConcertMoment` and `FeaturedConcertMemory`. These are separate from the Core Data objects.

Repositories are defined through protocols. This keeps database code out of the view models and allows the tests to use mock storage.

The share extension reuses the browsing and memory-saving use cases. The widget reads through a dedicated repository. Repository wrappers request widget updates when saved data changes.

## Storing concerts and memories

I chose Core Data because Encore needs to save a personal journal locally and work offline. It does not need an account or server for its current features.

There are two main entities:

| Entity | Contents |
| --- | --- |
| `ConcertEntry` | Artist, venue, concert date and creation date |
| `ConcertMemory` | Caption, photo filename and creation date |

Each concert can have several memories. Each memory belongs to one concert. Deleting a concert also removes its memory records through a Cascade delete rule.

The year filter fetches concerts between the start of the selected year and the start of the next year. The details screen fetches memories using their concert’s ID.

Photos are stored separately as JPEG files, with their filenames saved in Core Data. When a memory or concert is deleted, the app removes the database records first and then cleans up the photo files.

Data stays available between launches, but this version does not include cloud sync or guaranteed recovery after uninstalling the app.

## Share extension

The share extension lets someone save a photo while browsing another app, such as Photos. They select one image, choose Encore from the share sheet, select an existing concert and optionally add a caption. 

This makes it possible to attach a photo to a concert as soon as they find it, without reopening Encore and selecting the photo again. 

The extension accepts one image at a time. It saves to the shared database and photo folder, then closes after a successful save.

## Home Screen widget

The widget shows the most recently added memory. It comes in two sizes:

- **Small:** photo or placeholder, artist and concert date.
- **Medium:** the same information, plus the venue and caption.

The idea is to make saved memories visible outside the app, rather than only seeing them when deliberately opening the journal.

The widget reads from the shared container. Saves, edits and deletions request an update, although iOS decides when the refresh happens.

## Shared storage

The app, share extension and widget use the same App Group:

`group.com.yufan.Encore`

The Core Data store and photo files are kept in this shared container. The identifier must match across all three targets.

## Running the project

The project currently targets **iOS 27.0**.

1. Clone the repository.
2. Open `Encore/Encore.xcodeproj` in Xcode.
3. Make sure your Xcode installation includes the iOS 27 SDK and an iOS 27 simulator.
4. Select the **Encore** scheme and an iPhone simulator.
5. Run the main app once to initialise shared storage.
6. Add a concert and a memory before trying the extensions.

For a physical device, set up signing for the app and both extensions with your development team. If you change the App Group, update it in all three entitlement files and in `EncoreSharedStorage.swift`. Update bundle identifiers as needed for your team.

### Testing the share extension

Open Photos, select one image and choose Encore from the share sheet. Choose a concert, save the memory, then open that concert in Encore to check it appears.

### Testing the widget

Long-press the Home Screen, open the widget gallery and find Encore. Add either size, then save another memory in the app and check that it updates.

If the widget asks you to open Encore, launch the main app first and check that the library loads.

## Tests

There are 29 XCTest methods in `EncoreTests.swift`. They use mock repositories and mock photo storage, so they do not read or change the real journal.

The tests cover valid inputs, missing details, date boundaries, saving failures, editing, deletion, photo cleanup and widget refresh requests.

To run them, select the **Encore** scheme and an iPhone simulator, then press **⌘U**.

The extensions, navigation and Core Data relationships also need to be checked in the simulator. The unit tests do not verify the complete interface or extension behaviour.

## Git workflow

Major features were developed on separate branches and merged into `main` through pull requests.

Commit messages follow Conventional Commits, using `feat:`, `fix:`, `test:` and `docs:`.

## Limitations

This version supports one photo per memory and one image per share operation. The widget shows the latest memory; it does not offer shuffle or concert selection.

There is no cross-device sync. If photo cleanup fails, it can be retried from the details screen, but the pending retry information is not saved across app restarts.

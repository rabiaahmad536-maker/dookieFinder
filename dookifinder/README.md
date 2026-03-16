## Project Structure
## DOOKIFINDER

##### !!if anyone runs into the same problems as me: if you are using bash terminal anf flutterfire doesnt work, try flutterfire.bat (for some reason it works)

The project follows a vertical slice architecture (everyone
owns a full feature end-to-end rather than splitting responsibilities by 
frontend and backend).

Code is organized into four main folders under `lib/`:

- **models/** — Dart classes that define the shape of data (e.g., a Bathroom 
  or Review object) and handle conversion to/from Firestore.
- **services/** — Logic for communicating with external dependencies like 
  Firebase and GPS. Screens never interact with Firebase directly; they always 
  go through a service.
- **screens/** — Full pages the user navigates between, each assembling widgets 
  into a complete view.
- **widgets/** — Small, reusable UI components shared across multiple screens.

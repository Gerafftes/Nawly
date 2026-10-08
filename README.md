<p align="center">
  <img src="docs/assets/readme/test1-icon-light.png" width="160" alt="Nawly App-Icon – Hell">
  <img src="docs/assets/readme/test1-icon-dark.png" width="160" alt="Nawly App-Icon – Dunkel">
  <img src="docs/assets/readme/test1-icon-clear.png" width="160" alt="Nawly App-Icon – Transparent">
</p>

<h1 align="center">Nawly</h1>

<p align="center">
  Finde Hilfe in deiner Nähe oder verdiene Geld mit kleinen Jobs und Services.<br>
  Lokal, direkt und unkompliziert.
</p>

<p align="center">
  <a href="#was-ist-nawly">Über Nawly</a> ·
  <a href="#funktionen">Funktionen</a> ·
  <a href="#screenshots">Screenshots</a> ·
  <a href="#lokal-starten">Lokal starten</a> ·
  <a href="#supabase-adapter">Supabase</a> ·
  <a href="#status">Status</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/status-work%20in%20progress-orange" alt="Status: Work in Progress">
  <img src="https://img.shields.io/badge/Flutter-App-02569B?logo=flutter&logoColor=white" alt="Flutter App">
</p>


## Was ist Nawly?

Nawly bringt Menschen zusammen, die im Alltag kurzfristig Hilfe brauchen, und Menschen, die kleine Jobs oder Services anbieten möchten.

Über die App sollen Aufgaben in der Umgebung gefunden, erstellt und angenommen werden. Die aktuelle Version konzentriert sich auf den mobilen Flow für iOS und Android, die Informationsarchitektur und eine realistische Demo mit lokalen Daten. Ein Web-Target ist bewusst nicht Teil des Projekts.

Für Haushaltshilfen soll Nawly den Weg zur legalen Organisation verständlicher machen und auf das [Haushaltsscheckverfahren der Minijob-Zentrale](https://www.minijob-zentrale.de/DE/fuer-haushalte/vorteile-fuer-haushalte) verweisen. Rechtliche und steuerliche Angaben müssen vor einem produktiven Einsatz anhand der aktuellen offiziellen Informationen geprüft werden.

## Funktionen

- **Jobs in deiner Nähe:** Demo-Jobs zeigen Titel, Zeitpunkt, Vergütung, Entfernung und Verifizierungsstatus.
- **Berlin-Karte:** Die erste Demo-Region zeigt drei ungefähre Job-Standorte innerhalb der Berliner Landesgrenze; Bereiche außerhalb werden abgedunkelt.
- **Jobs und Services erstellen:** Auswahl zwischen einem einmaligen Job und einem eigenen Service mit passenden Beispielen.
- **Aktivitäten verfolgen:** Laufende und abgeschlossene Aktivitäten werden gruppiert und mit Status, Fortschritt und Details dargestellt.

## Screenshots

| Start | Erstellen |
| --- | --- |
| <img src="docs/bilder/hauptseiten/start.png" alt="Startseite" width="260"> | <img src="docs/bilder/hauptseiten/create.png" alt="Job oder Service erstellen" width="260"> |

| Aktivität | Profil |
| --- | --- |
| <img src="docs/bilder/hauptseiten/activity.png" alt="Aktivitäten" width="260"> | <img src="docs/bilder/hauptseiten/profile.png" alt="Profil" width="260"> |

[Weitere Ansichten ansehen](docs/bilder/weitere/)

## Lokal starten

Eine öffentliche Demo oder Store-Version gibt es aktuell nicht. Nawly läuft im momentanen Stand lokal als Flutter-App mit Demo-Daten.

### Voraussetzungen

- Flutter mit Dart SDK `>=3.9.2 <4.0.0`
- Für iOS: Xcode und ein iOS-Gerät oder Simulator
- Für Android: Android Studio beziehungsweise das Android SDK und ein Gerät oder Emulator
- Das Paket `mjn_liquid_ui` wird über `pub.dev` bezogen

### Ausführen

```bash
flutter pub get
flutter run
```

### Prüfen

```bash
flutter analyze
flutter test
```

## Supabase-Adapter

Die App verwendet standardmäßig lokale Demo-Daten. Ein optionaler
Supabase-Datenpfad ist im Flutter-Code vorbereitet, aber das Backend mit
Schema, Migrationen, Seed-Daten und Edge Functions ist nicht Teil dieses
Repository-Stands. Ohne separat bereitgestelltes Backend und Auth-Sitzung ist
der Datenpfad nicht produktiv nutzbar. Der `service_role`-Schlüssel gehört
niemals in die Flutter-App.

## Release-Signing und Artefaktprüfung

Android-Release-Builds benötigen eine geschützte `android/key.properties` oder
die CI-Variablen `ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS` und `ANDROID_KEY_PASSWORD`. Eine Vorlage liegt unter
`android/key.properties.example`; Keystore und Passwörter gehören niemals ins
Repository. Das Standard-`~/.android/debug.keystore` wird für Release ebenfalls
abgewiesen. Ohne diese Angaben schlägt ein Release-Build absichtlich fehl.

Für iOS werden Profile und Release über die ignorierte Datei
`ios/Flutter/ReleaseSigning.xcconfig` mit Distribution-Identity, Team und
Provisioning-Profile konfiguriert. Die Vorlage liegt unter
`ios/Flutter/ReleaseSigning.xcconfig.example`. Debug darf weiterhin mit einer
Development-Identity laufen; Profile und Release nicht.

Die statische CI-Prüfung für Release-Signing, Windows-Konvertierung und
Supabase-Transport läuft über:

```bash
bash tool/verify_release_signing.sh --static
```

Nach dem geschützten Build können die Zertifikate des finalen APK/AAB und IPA
gegen freigegebene Werte geprüft werden:

```bash
ANDROID_EXPECTED_CERT_SHA256=... \
IOS_EXPECTED_SIGNING_IDENTITY='Apple Distribution: Example (TEAMID)' \
IOS_EXPECTED_PROFILE_UUID=... \
IOS_EXPECTED_TEAM_ID=... \
bash tool/verify_release_signing.sh \
  --config \
  --android-artifact build/app/outputs/bundle/release/app-release.aab \
  --ios-artifact build/ios/ipa/nawly.ipa
```

Der Workflow `.github/workflows/release-security-gates.yml` prüft zusätzlich
bei jedem veröffentlichten GitHub-Release die angehängten APK/AAB/IPA-Dateien.
Dafür müssen in den Repository-Secrets `ANDROID_EXPECTED_CERT_SHA256`,
`IOS_EXPECTED_SIGNING_IDENTITY`, `IOS_EXPECTED_PROFILE_UUID` und
`IOS_EXPECTED_TEAM_ID` hinterlegt sein. Die iOS-Werte werden im Runner auch
für die aufgelösten Profile/Release-Buildsettings verwendet.

Bereits verteilte Artefakte müssen mit demselben Verifier geprüft werden. Bei
einer Debug- oder Development-Identity ist der Release-Kanal zu sperren, der
Schlüssel zu rotieren und ein neues Artefakt mit der freigegebenen Identity zu
verteilen.

## Technischer Aufbau

- `lib/main.dart` enthält den App-Shell, die Tab-Navigation, Theme-Unterstützung und die Übergänge zwischen Haupt- und Detailansichten.
- Repository-Schnittstellen kapseln die Datenquelle. Standardmäßig laden die Demo-Repositories Jobs, Aktivitäten und Profildaten aus [lokalen JSON-Assets](assets/data/); alternativ stehen Supabase-Adapter bereit.
- `shared_preferences` speichert lokale Einstellungen wie das Theme und den Zustand von Aktivitäts-Erinnerungen.
- `mjn_liquid_ui` liefert die Apple-inspirierten Tab-Bar-, Sheet- und Toast-Bausteine; ergänzende UI- und Skalierungslogik liegt im Projekt selbst.
- Die erste Demo-Region nutzt die für die mobile Darstellung lokal vereinfachte amtliche [ALKIS Berlin Landesgrenze](https://daten.berlin.de/datensaetze/alkis-berlin-landesgrenze-wfs-07b1347b) unter der Datenlizenz Deutschland – Zero – Version 2.0.
- Das iOS-App-Icon ist als [Test1_Icon.icon](Icon/Test1_Icon.icon/) eingebunden. Die README-Vorschauen für Hell, Dunkel und Transparent liegen unter [docs/assets/readme/](docs/assets/readme/).

## Status

Nawly ist aktuell ein **Work in Progress** und sollte als interaktiver UI-Prototyp verstanden werden.

### Im aktuellen Checkout vorhanden

- zentrale Navigation für Start, Aktivität, Profil und Erstellen
- responsive Hauptseiten und Profil-Detailansichten
- lokale Demo-Daten für Jobs, Aktivitäten, Profil, Verifizierung und Auszahlungen
- optionaler Supabase-Adapter im Flutter-Code; Backend und Datenbankdateien sind nicht enthalten
- Statusverläufe und Aktivitäts-Erinnerungen im lokalen App-Zustand
- iOS-App-Icon `Test1_Icon.icon`

### Noch offen

- Login-/Registrierungsoberfläche und produktive Auth-Sitzungen
- Schreib- und Synchronisierungsabläufe für Supabase
- produktive, serverseitig anonymisierte Standortabfragen mit PostGIS
- vollständige Veröffentlichungs-, Buchungs- und Zahlungsabwicklung
- produktive Service- und Job-Daten statt lokaler Demo-Assets
- App-Store- oder Release-Verteilung

## Credits

- [Flutter](https://flutter.dev) und Dart bilden die technische Grundlage.
- [mjn_liquid_ui](https://github.com/Gerafftes/mjn_liquid_ui) ist eine von mir entwickelte Bibliothek für wiederverwendbare Apple-inspirierte Liquid-UI-Komponenten.
- Informationen zum Haushaltsscheckverfahren stammen aus dem offiziellen Angebot der [Minijob-Zentrale](https://www.minijob-zentrale.de/DE/fuer-haushalte/vorteile-fuer-haushalte).

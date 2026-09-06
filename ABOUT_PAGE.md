# Product Requirements Document (PRD)

## MedVerify - About Screen Redesign

**Version:** 1.0
**Status:** Ready for Development
**Platform:** Flutter (Mobile)
**Priority:** Medium
**Author:** ChatGPT

---

# Overview

The current About screen is clean but lacks important information that establishes trust, transparency, and professionalism for a healthcare application.

This redesign aims to transform the About page into a trustworthy information hub that clearly explains:

* What MedVerify does
* Where its data comes from
* What its limitations are
* Who built it
* How users can get support
* Legal resources
* App metadata

The design should remain minimal and consistent with the current visual style.

---

# Goals

## Primary Goals

* Increase user trust
* Improve transparency
* Reduce legal ambiguity
* Provide helpful support links
* Present MedVerify as a professional healthcare application

---

# Non-Goals

This feature will **not** include:

* User profile information
* Settings
* Analytics
* Feedback forms
* Release notes
* Changelog viewer

---

# Design Principles

* Clean
* Medical
* Trustworthy
* Minimal
* Information-first

Continue using the existing:

* White background
* Soft green accent
* Rounded cards
* Consistent spacing
* Current typography hierarchy

---

# Page Structure

```
App Bar

App Logo

App Name
Version Badge

Short Description

------------------------

What MedVerify Does

------------------------

Data Source

------------------------

Important Disclaimer

------------------------

Developer Information

------------------------

Statistics

------------------------

Support

------------------------

Useful Links

------------------------

Footer
```

---

# Section 1 — Header

## Display

Logo

```
MedVerify
```

Version

```
Version 1.0.0 Beta
```

(Automatically populated from app version.)

---

## Description

Replace current marketing copy with something more practical.

Example:

> MedVerify helps you verify whether medicines are registered with the Ghana Food and Drugs Authority (FDA). Scan a barcode or medicine package to compare it against official FDA registration records and make more informed decisions about your medication.

---

# Section 2 — What MedVerify Does

New information card.

Title

```
What MedVerify Does
```

Body

```
• Scan medicine barcodes

• Scan medicine packaging

• Verify FDA registration

• View registration details

• Identify potential issues

• Access official registration information
```

Icons may be used for each bullet.

---

# Section 3 — Official Data Source

Card title

```
Official Data Source
```

Contents

```
Ghana Food and Drugs Authority (FDA)

Verification results are matched against publicly available FDA registration records.

Source:
Official FDA Medicine Registration Database
```

Include:

FDA icon

Optional button

```
Visit FDA Website
```

Opens browser.

---

# Section 4 — Important Disclaimer

This is a high priority addition.

Use a highlighted card.

Suggested icon:

⚠️

Title

```
Important Information
```

Body

```
MedVerify checks whether a medicine appears in official FDA registration records.

A successful match does NOT guarantee that the physical product is genuine.

Counterfeit medicines may imitate legitimate packaging.

Always purchase medicines from licensed pharmacies and consult healthcare professionals when in doubt.
```

This section should visually stand out.

---

# Section 5 — Developer Information

Replace current content.

Instead of:

```
The Laughing Chicken
```

Use

```
Developed by

Versatech Enterprise
```

Optional secondary text

```
Created by
Methuselah Nwodobeh
```

Display:

Developer icon

Website button

Email button

---

# Section 6 — Statistics

New card.

Title

```
Database Information
```

Example fields

```
Registered Medicines
18,000+

Verification Source
Ghana FDA

Database Status
Active

Last Updated
July 2026
```

Future-ready.

All values should come from backend APIs when available.

For beta:

Hardcoded values are acceptable.

---

# Section 7 — Support

New section.

Contents

```
Need Help?

support@medverify.app
```

Buttons

* Contact Support
* Report an Issue

Future:

Report Issue can open GitHub issues or backend feedback endpoint.

---

# Section 8 — Useful Links

Create a grouped card containing:

```
Visit Website

Privacy Policy

Terms of Service

Licenses
```

Each opens an external browser.

Future additions

```
FAQ

Blog

Release Notes
```

---

# Section 9 — Footer

Current footer should be improved.

Display

```
Built in Ghana 🇬🇭

© 2026 MedVerify

All Rights Reserved
```

Optional

```
Made with ❤️ to make Ghana's medicine register easy to check.
```

---

# Version Badge

Instead of

```
Version 1.0.0
```

Display

```
Version 1.0.0

Closed Beta
```

or

```
Version 1.0.0 Beta
```

Badge should use green accent color.

---

# Dynamic Information

Use Flutter package_info_plus.

Retrieve:

```
App Version

Build Number
```

Example

```
Version 1.0.0 (15)
```

---

# Future API Support

Prepare models for:

```
Database statistics

Last sync date

Number of medicines

API status
```

Create a service layer even if currently mocked.

Example:

```
GET /api/about
```

Response

```json
{
  "databaseStatus": "Active",
  "registeredMedicines": 18342,
  "lastUpdated": "2026-07-01",
  "verificationSource": "Ghana FDA"
}
```

---

# Navigation

External links should launch using:

```
url_launcher
```

Required links

* Website
* Privacy Policy
* Terms
* FDA website
* Support email (mailto:)

---

# Accessibility

Support:

* Screen readers
* Dynamic text scaling
* High contrast
* Tap targets ≥48dp

---

# Error Handling

If app version cannot be loaded

Display

```
Unknown Version
```

If URLs fail to launch

Show

```
Unable to open link.
```

using Snackbar.

---

# Technical Requirements

## Flutter Packages

```
package_info_plus

url_launcher
```

---

## Components

Suggested widgets

```
AboutHeader

FeatureCard

DataSourceCard

DisclaimerCard

DeveloperCard

StatisticsCard

SupportCard

UsefulLinksCard

FooterSection
```

---

# Acceptance Criteria

## Header

* Logo displayed
* App name displayed
* Version loaded dynamically
* Beta badge visible

---

## Description

* Updated user-focused description
* No marketing-heavy wording

---

## What MedVerify Does

* New informational card added
* Lists major verification capabilities

---

## Data Source

* Displays Ghana FDA
* Explains verification source
* Includes FDA website link

---

## Disclaimer

* Clearly explains app limitations
* Visually distinguished from other cards

---

## Developer

* Shows Versatech Enterprise
* Shows creator name
* Includes website and support links

---

## Statistics

* Displays database metadata
* Easily replaceable with API values later

---

## Support

* Email support available
* Report Issue action present

---

## Useful Links

Includes:

* Website
* Privacy Policy
* Terms of Service
* Licenses

---

## Footer

Displays:

* Built in Ghana
* Copyright
* Current year

---

# Nice-to-Have Enhancements (Post-Beta)

* Animated version badge
* Database sync indicator
* Live API status
* Changelog viewer
* Open-source acknowledgements
* Contributor list
* Social media links
* "What's New" dialog
* Direct feedback submission from the About screen
* App health status indicator (API connectivity, database freshness)

---

# Success Metrics

* Increased user confidence in the app's legitimacy and data source.
* Reduced support questions about what MedVerify can and cannot verify.
* Improved compliance with transparency expectations for healthcare applications.
* A polished About screen that aligns with the quality of the rest of the MedVerify experience and is ready for public beta release.

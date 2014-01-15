# Ayla, the personal assistant

Ayla is a smart, self-contained, super cool personal assistant. She gets data from a multitude of devices, sensors and services
and tries to make my life easier by automating tasks and reminding me of things.

## The brain: Ayla Home Server

The "homeserver" is the main brain of the system. It runs on top of Node.js, coded mainly in CoffeeScript and Javascript.

## The helper: Ayla Phone

The "phone" is a Windows Phone cliens, always running on the background. It's where most interactions with Ayla happens.
It relies on communications with the "homeserver" to do some things and acts independently to do other.

## The cloud

Ayla currently aggregates and integrates to the following services and devices:

* Electric Imp (Hannah dev board and website API)
* Facebook (website API)
* Fitbit (Flex band and website API)
* Garmin (Forerunner 610 and Connect website API)
* GitHub (website API)
* IFTTT (website API)
* Netatmo (Personal Weather Station and website API)
* Ninja Blocks (Block, RF433 sensors and website API)
* Nokia Lumia 720
* Outlook.com (IMAP and SMTP)
* Philips hue (lamps, light bulbs and bridge API)
* SkyDrive (website API)
* StatusCake (website API)
* Toshl (website API)
* Twitter (website API)
* Weather Underground (website API)
* Withings (Smart Body Scale and website API)
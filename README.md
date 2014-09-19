# Ayla, the personal assistant

##### https://ayla.codeplex.com

Ayla is a smart, self-contained, super cool personal assistant. She gets data from a multitude of devices, sensors and
services and tries to make my life easier by parsing all this data and automating tasks.

## The brain: Ayla Home Server

The "homeserver" is the brain of Ayla. It runs on top of Node.js, coded mainly in CoffeeScript and using
Expresser (https://expresser.codeplex.com) as its base platform. Data is stored in a MongoDB database.

More info at https://ayla.codeplex.com/wikipage?title=Home%20Server

## The helper: Ayla Phone

The "phone" is a Windows Phone 8.1 client, always running on the background. It's where most user interactions with Ayla
happens. It relies on communications with the homeserver to do some things and acts independently to do some others.

More info at https://ayla.codeplex.com/wikipage?title=Phone

# Location management prototype

The shared source of truth is `public/data/restaurant-data.json`.

To add a location, the manager adds a new object to `locations` with a unique `id`, `active: true`, address, coordinates, services, `menuId`, and rewards settings. The customer site should show only active locations and choose the nearest location by comparing the visitor's browser geolocation coordinates against each active location.

For the live product, this file moves unchanged into a database. The manager dashboard writes changes to the database; the customer website and Flutter app read the same records. This avoids duplicated menus, hours, offers, and location content.

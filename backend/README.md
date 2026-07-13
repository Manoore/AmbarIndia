# Ambar multi-location API starter

Run `npm run api` from the `website` directory to start the local API at `http://localhost:3001`.

- `GET /api/locations` returns each restaurant location and its services.
- `GET /api/locations/:id` returns a location with its menu.
- `POST /api/orders` accepts `{ "locationId": "clifton", "items": [{ "id": "saag-paneer", "quantity": 1 }] }`.
- `GET /api/orders` is the initial manager dashboard order feed.

This is intentionally an in-memory development API. Production needs authenticated users, a database, Stripe/processor webhooks, POS integration, and secure role permissions.

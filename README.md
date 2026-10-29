# Billette Assessment

A Rails app that lists upcoming public Billetto events and lets signed-in Clerk users upvote or downvote each event once.

## Setup

- Ruby 3.3.1, Bundler, and PostgreSQL
- `bundle install`
- Configure PostgreSQL in `config/database.yml`, then run `bin/rails db:prepare`
- For local demo content with one demo upvote, run `bin/rails events:seed_preview`
- Start the app with `bin/rails server -p 3003` and open `http://localhost:3003`
- Run the specs with `bundle exec rspec`

## Billetto integration

The adapter defaults to Billetto's documented public event endpoint:
`https://billetto.dk/api/v3/public/events`. It requests the documented maximum of 100 records, maps `id`, `title`, `startdate`, `image_link`, `description`, and `url`, and retains the event URL's Billetto tracking parameters.

Add the API keypair to a git-ignored `.env` or `.env.clerk` file as `BILLETTO_API_KEYPAIR='your-keypair'`. The local development initializer loads it on each Rails process start. You can optionally set `BILLETTO_PUBLIC_EVENTS_URL` there to override the endpoint. Import events through the command bus with:

```sh
bin/rails events:import
```

Billetto's public API reference documents a response shaped as `{ "object": "list", "data": [...] }`, the `Api-Keypair` header, and a 100-record limit. The adapter accepts that response (as well as top-level arrays and `events` or `results` arrays) and raises an error on an incompatible response instead of partially importing it. A live request using a local API keypair succeeded on 2026-10-30 and imported 100 events. Imports upsert returned events and leave other records, including preview data, intact. See [Billetto's public events endpoint](https://api.billetto.com/reference/list-public-events) and [event search object](https://api.billetto.com/reference/search-publicly-available-events).

## Clerk authentication

Create a Clerk application and configure:

- `CLERK_PUBLISHABLE_KEY`
- `CLERK_JWT_KEY` (the PEM public verification key)
- `CLERK_ISSUER` (the exact token issuer)
- `CLERK_AUTHORIZED_PARTIES` (comma-separated permitted browser origins, for example `http://localhost:3003`)

The local development setup reads these values from git-ignored `.env` or `.env.clerk` files. Restart Rails after changing them. Public event browsing does not require an account. Voting requires a valid Clerk session token; the server derives the voter ID from its verified `sub` claim.

## Design

- `app/integrations/billetto` isolates the Billetto HTTP client and response mapping.
- Import and vote actions are dispatched through the Arkency command bus.
- `Events::EventImported` and `Events::VoteRecorded` are stored in Rails Event Store streams for each event.
- A synchronous event subscription projects vote events into the relational `votes` read model. The event list reads event data and grouped vote totals from PostgreSQL.
- A unique database index on `(event_id, user_id)` enforces one current vote per person and event; changing the selection updates the projection.
- The controller validates the Clerk token before dispatching the vote command.

## Test coverage

RSpec examples cover event and vote validations, vote recording and changes, Billetto response mapping and API errors, Clerk token validation, and vote request authorization. Browser-based authentication still requires a configured Clerk test instance and has not been exercised as part of the automated suite.

## References

- [Billetto API developer hub](https://go.billetto.com/resources/developers)
- [Clerk Rails guide](https://clerk.com/docs/reference/ruby/rails)
- [Clerk JavaScript quickstart](https://clerk.com/docs/js-frontend/getting-started/quickstart)
- [Clerk manual JWT verification](https://clerk.com/docs/guides/sessions/manual-jwt-verification)

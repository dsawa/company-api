# Company API

Example of some Rails 8 features. API Application for managing companies and it's addresses.

* Rails 8
* PostgreSQL
* Docker

## Development

### Devcontainer

This app was created with command `rails new company-api --api --devcontainer --database=postgresql`.
VSCode should detect devcontainer config for easy development.

### Traditional 

Setup PostgreSQL database on Your machine. Example with docker: `docker run --name postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432  postgres`

Run `rails server` and go to localhost:3000.


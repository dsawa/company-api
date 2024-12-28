# Company API

Example of some Rails 8 features. API Application for managing companies and it's addresses.

Tech stack:
* [Ruby 3.3](https://www.ruby-lang.org/)
* [Rails 8](https://rubyonrails.org)
* [PostgreSQL 16](https://www.postgresql.org)
* [Docker](https://www.docker.com)
* [VSCode](https://code.visualstudio.com)

## Development Setup

For running app You can use devcontainer or traditional method.

### Devcontainer

This app was created with command `rails new company-api --api --devcontainer --database=postgresql`.
VSCode should detect devcontainer config for easy development.

Using database GUI for managing DB. Run `docker ps` and find Your container postgresql name. That name will be host, for example: `company_api-postgres-1`.

Connect to DB with:
* host: company_api-postgres-1
* user: postgres
* password: postgres

In VSCode containered terminal run: `rails server`

### Traditional 

Setup PostgreSQL database on Your machine. Example with docker: `docker run --name postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432  postgres`

Run `rails server` and go to localhost:3000.

### Debugger

Running app with `bundle exec rdbg -O -n -c -- bin/rails server -p 3000` will give You possibility to connect to VSCode debugger. Debug configurations are placed under `.vscode/launch.json`
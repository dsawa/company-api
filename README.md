# Company API

Example of some Rails 8 features. API Application for managing companies and it's addresses.

Tech stack:
* [Ruby 3.3](https://www.ruby-lang.org/)
* [Rails 8](https://rubyonrails.org)
* [PostgreSQL 16](https://www.postgresql.org)
* [Docker](https://www.docker.com)
* [Pre-commit](https://pre-commit.com)
* [VSCode](https://code.visualstudio.com)

## Development Setup

For running app You can use devcontainer or traditional method.

### Devcontainer

This app was created with command `rails new company-api --api --devcontainer --database=postgresql`.
VSCode should detect devcontainer config for easy development.

If using database GUI for managing DB (like: [Database Client JDBC for VSCode](https://marketplace.visualstudio.com/items?itemName=cweijan.dbclient-jdbc)): Run `docker ps` and find Your container postgresql name. That name will be host, for example: `company_api-postgres-1`.

Connect to DB with:
* host: company_api-postgres-1
* user: postgres
* password: postgres

In VSCode containered terminal run: `rails server`

### Traditional

Setup PostgreSQL database on Your machine. Example with docker: `docker run --name postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres`

Then freely run
```
rails db:create db:migrate
```

Run `rails server` and try app (see API Authentication section).

### Debugger

Running app with `bundle exec rdbg -O -n -c -- bin/rails server -p 3000` will give You possibility to connect to VSCode debugger. Debug configurations are placed under `.vscode/launch.json`

### Pre-commit

Project uses pre-commit hooks. Install `pre-commit` (MacOS: brew install pre-commit) and then in project run `pre-commit install`.

To run hook manually: `pre-commit run --all-files`

## API Authentication

App uses simple token authentication with use of popular [devise](https://github.com/heartcombo/devise) and [tiddle](https://github.com/adamniedzielski/tiddle) gems.

Base API user is prepared in seeds file so run:
```
rails db:seed
```

Obtain authentication token with:
```
curl --request POST \
  --url http://localhost:3000/users/sign_in \
  --header 'Content-Type: application/json' \
  --data '{
	"user": {
		"email": "company@api.com",
		"password": "123456"
	}
}'
```

After that you will receive authentication token
```
{
  "message": "Authenticated",
  "authentication_token": "YOUR_TOKEN"
}
```

Send additional headers to every next request:
* X-USER-EMAIL: company@api.com
* X-USER-TOKEN: YOUR_TOKEN

## Example requests:

* Create company with addresses:
```
curl --request POST \
  --url http://localhost:3000/api/v1/companies \
  --header 'Content-Type: application/json' \
  --header 'X-USER-EMAIL: company@api.com' \
  --header 'X-USER-TOKEN: YOUR_TOKEN' \
  --data '{
	"company": {
		"name": "Global Co",
		"registration_number": 12345,
		"addresses_attributes": [
			{
				"street": "Gdanska 1",
				"city": "Reda",
				"postal_code": "90-124",
				"country": "Poland"
			},
			{
				"street": "Wiejska 4",
				"city": "Warsaw",
				"postal_code": "10-123",
				"country": "Poland"
			}
		]
	}
}'
```

* Import companies with addresses from file:
```
curl --request POST \
 --header 'X-USER-EMAIL: company@api.com' \
 --header 'X-USER-TOKEN: YOUR_TOKEN' \
 -F "file=@spec/fixtures/files/companies.csv" \
 --url http://localhost:3000/api/v1/companies/import
```

* List companies and addresses:
```
curl --request GET \
  --url http://localhost:3000/api/v1/companies \
  --header 'X-USER-EMAIL: company@api.com' \
  --header 'X-USER-TOKEN: YOUR_TOKEN' \
  --header 'Content-Type: application/json'
```

* Show details of single company
```
curl --request GET \
  --url http://localhost:3000/api/v1/companies/2 \
  --header 'X-USER-EMAIL: company@api.com' \
  --header 'X-USER-TOKEN: YOUR_TOKEN' \
  --header 'Content-Type: application/json'
```

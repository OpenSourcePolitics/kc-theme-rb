# Keycloak theme generator

Generate simple Keycloak customized theme using thor cli

## Requirements
* Ruby 2.7+
* Thor gem
* HTTParty gem
* ERB gem

## Getting started

1. Execute main.rb : `$ ruby main.rb theme --name <theme_name> --color <color> --logo <logo>`

Help is available with `$ ruby main.rb help theme`

2. Copy the generated theme to the Keycloak theme directory

A new directory should be present in `./data/` directory. Copy the content of this directory to the Keycloak theme directory.

## Resources

* [Keycloak themes documentation](https://www.keycloak.org/docs/latest/server_development/#_themes)
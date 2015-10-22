# Luke Antins, float64 website and blog

## Cheat Sheet

```bash
# Run a 'live reloading' copy of the site for local development
bundle exec middleman

# Deploy to server
bundle exec middleman deploy
```

## TODO

    [ ] Add contact form.

## Nginx Redirects

    rewrite ^/hire(.*)$ $scheme://float64.uk/services/ permanent;

## Notes

  - fontello.com used to pull out required icons from fontawesome.io

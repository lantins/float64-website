---
title: Dynamic development area with Apache 2.4 and PHP-FPM
date: 2014-08-22 03:10 UTC
tags: apache, php, howto
keywords: ubuntu, apache, php, howto, mod_proxy_fcgi, php-fpm, tutorial
description: Guide to setting up a dynamic development area using Apache mod_vhost_alias and PHP-FPM.
---

## Introduction

Today I'm going show you to setup a _dynamic development area_
using Apache [`mod_vhost_alias`][mod_vhost_alias] and PHP-FPM.
Once setup you can quickly add and delete Apache virtual hosts
without having to edit configuration files or restart services.

~~~ bash
# Add dynamic virtual hosts
mkdir -p /srv/dev/client1/public_html  # client1.dev.float64.uk
mkdir -p /srv/dev/spectra/public_html  # spectra.dev.float64.uk
mkdir -p /srv/dev/temp/public_html     #    temp.dev.float64.uk

# Delete dynamic virtual hosts
rm -rf /srv/dev/temp
rm -rf /srv/dev/spectra
~~~

You could use this for development purposes or allowing a client to preview
changes before deploying them into production.

> This module creates dynamically configured virtual hosts, by allowing the
> IP address and/or the Host: header of the HTTP request to be used as part
> of the pathname to determine what files to serve. This allows for easy use of
> a huge number of virtual hosts with similar configurations.
> <cite>[Summary from `mod_vhost_alias` module documentation][mod_vhost_alias]</cite>

## Example -- Dynamic subdomain virtual hosts

You can map each subdomain to its own `DocumentRoot` within a directory
hierarchy you define.

The URL `client1.dev.float64.uk` could have
`DocumentRoot` dynamically set to `/srv/dev/client1/public_html`

### DNS wildcard

You need a [wildcard DNS record][wildcard] pointing at your server, here we want
to allow `<subdomain>.dev.float64.uk`

~~~ conf
; Wildcard record for dynamic virtual hosts 

*.dev.float64.uk.   IN A    178.79.187.51
~~~

There is no requirement run a setup like this on the public internet, you can
configure Apache on your own machine and host a local DNS zone to allow `<subdomain>.local`

### Example Apache 2.4 configuration with PHP-FPM

~~~ conf

<VirtualHost *:80>
  ServerName dev.float64.uk
  ServerAlias *.dev.float64.uk
  VirtualDocumentRoot /srv/dev/%1/public_html

  # Virtual host permissions
  <Directory "/srv/dev/%1/public_html">
    Options +SymLinksIfOwnerMatch
    AllowOverride AuthConfig FileInfo Indexes Limit Options=Indexes,MultiViews
    Require all granted
  </Directory>

  # n.b. Needs Apache 2.4.10 or newer.
  <FilesMatch \.php$>
    SetHandler "proxy:unix:/var/run/php5-fpm.sock|fcgi://localhost"
  </FilesMatch>

  # n.b. Remove `FilesMatch` section above and uncomment this for older Apache.
  # ProxyPassMatch ^/(.*\.php(/.*)?)$ unix:/var/run/php5-fpm.sock|fcgi://./srv/dev/%1/public_html/$1
</VirtualHost>
~~~

In the example above dynamic virtual hosts will share the same PHP-FPM pool.

[mod_vhost_alias]:http://httpd.apache.org/docs/2.4/mod/mod_vhost_alias.html
[VirtualDocumentRoot]: http://httpd.apache.org/docs/2.4/mod/mod_vhost_alias.html#virtualdocumentroot
[wildcard]: http://en.wikipedia.org/wiki/Wildcard_DNS_record

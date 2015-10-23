---
title: PHP-FPM sockets with Apache 2.4 and mod_proxy_fcgi on Ubuntu 14.04 LTS
date: 2014-08-20 06:00 UTC
tags: ubuntu, apache, php, howto
keywords: ubuntu, apache, php, howto, mod_proxy_fcgi, php-fpm, tutorial
description: Guide to setup PHP-FPM unix socket pools with Apache 2.4 and mod_proxy_fcgi on Ubuntu 14.04 LTS
canonical: http://float64.uk/blog/2014/08/20/php-fpm-sockets-apache-mod-proxy-fcgi-ubuntu/
---

[If you don't feel like reading skip to the instructions](#instructions).

## The status quo

Apache running `mod_php` has been the status quo for years, this embeds a PHP
interpreter in each Apache process, sharing the interpreter between many
virtual hosts, the major problem is a single virtual host can bring it all
crashing down!

If you have ever been bitten by this you likely locked down your
`php.ini` and Apache configs *(and you always should)*. You have possibly played
around with [suphp][suphp], [mod_suexec][mod_suexec] or [mod_fastcgi][mod_fastcgi],
but this always seems messy!

## Why not use nginx?

Using nginx and FastCGI is a popular alternative, getting this up and running
is not always easy.

Many apps have been built around Apache and the modules it provides
like .htaccess files, mod_rewrite or multiviews, without these the app may
not work correctly, if at all.

You may need to adjust application code or nginx config files to get things working,
this becomes a problem when you have thousands of virtual hosts.

If what I've just mentioned does not affect you, stop reading and go use nginx.

## Apache 2.4 and mod_proxy_fcgi

Apache 2.4 and `mod_proxy_fcgi` has worked nicely with PHP-FPM using TCP/IP sockets
for some time with just the stock Apache httpd and php.net releases.

I'm pleased to see a couple of recent improvements:

- Apache 2.4.9 (March 2014) [mod_proxy_fcgi: Support unix domain sockets as backend server endpoint.](http://httpd.apache.org/docs/current/mod/mod_proxy.html#proxypass)
- Apache 2.4.10 (July 2014) [mod_proxy: Allow reverse-proxy to be set via explicit handler.](http://httpd.apache.org/docs/current/mod/mod_proxy.html#handler)

I personally don't like things listening on the network (local or not) unless it
needs to, unix socket support was a big win for me.

<a name="instructions"></a>

## Enough flapping, how do we set this up? (Ubuntu 14.04 LTS)

Okay okay... below we are going to setup:

- A PHP-FPM pool running with its own user and group (example).
- A Apache virtual host (example.com) that reverse proxies .php files to a PHP-FPM socket.

You need **Apache 2.4.10** or newer, currently available from a
[PPA by Ondřej Surý's][ondrej].

The instructions below are all bundled together so you _can_ copy them
into your text editor and replace occurrences of `example` and `example.com`
with your own settings then paste into a terminal window. But I suggest you do it
one step at a time to see what's going on.

~~~ bash
# Install packages
sudo add-apt-repository -y ppa:ondrej/apache2
sudo apt-get update
sudo apt-get -y install apache2 php5-fpm

# Create directory to contain multiple apache vhosts
sudo mkdir /srv/vhost
chmod 0751 /srv/vhost
chown www-data:www-data /srv/vhost

# Create user (example) and group (example) that the PHP-FPM pool will use
sudo groupadd example
sudo useradd -m -g example -d /srv/vhost/example -c 'vhost runtime' example
sudo mkdir /srv/vhost/example/public_html
sudo chown example:example /srv/vhost/example/public_html

# Create PHP-FPM pool configuration (example)
sudo bash -c 'cat > /etc/php5/fpm/pool.d/example.conf <<EOF
[example]
chdir = /

user = example
group = example

listen = /var/run/php5-fpm.sock.example
listen.owner = www-data
listen.group = www-data

pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3

EOF'

# Allow files to be served from our virtual hosts `public_html` directory
sudo bash -c 'cat > /etc/apache2/conf-available/vhost-permissions.conf <<EOF
<Directory "/srv/vhost/*/public_html">
  Options +SymLinksIfOwnerMatch
  AllowOverride AuthConfig FileInfo Indexes Limit Options=Indexes,MultiViews
  Require all granted
</Directory>

EOF'

# Create Apache virtual host configuration
sudo bash -c 'cat > /etc/apache2/sites-available/example.conf <<EOF
<VirtualHost *:80>
  ServerName example.com
  DocumentRoot /srv/vhost/example/public_html

  <FilesMatch \.php$>
    SetHandler "proxy:unix:/var/run/php5-fpm.sock.example|fcgi://localhost"
  </FilesMatch>
</VirtualHost>

EOF'

# Enable Apache modules, config files and virtual hosts
sudo a2enmod -m proxy_fcgi
sudo a2enconf -m vhost-permissions.conf
sudo a2ensite -m example

# **n.b.** If your testing using an IP address (and not a domain) you need
#          to disable the default apache virtual host, or better yet replace
#          it with your own.
sudo rm /etc/apache2/sites-enabled/000-default.conf

# Restart services to pickup config changes
sudo service php5-fpm restart
sudo service apache2 restart

# Drop in a phpinfo() file to test it works
sudo bash -c 'echo "<?php phpinfo(); ?>" > /srv/vhost/example/public_html/index.php'
sudo chown example:example /srv/vhost/example/public_html/index.php
~~~

If everything restarted without error you are ready to roll and test it out!

Fin.

[suphp]: http://www.suphp.org/
[mod_suexec]: http://httpd.apache.org/docs/2.2/mod/mod_suexec.html
[mod_fastcgi]: http://www.fastcgi.com/mod_fastcgi/docs/mod_fastcgi.html
[ondrej]: https://launchpad.net/~ondrej/+archive/ubuntu/apache2
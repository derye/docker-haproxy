# Dockerized HAProxy with Let's Encrypt

This container provides a HAProxy 2.3 application with Let's Encrypt certificates(or any acme SSL cert service)
generated at startup, as well as renewed (if necessary) once a week.
support HTTP2

## Usage

```
docker run \
    -e CERTS=my.domain,my.other.domain \
    -e EMAIL=my.email@my.domain \
    -e URL=https://acme-v02.api.letsencrypt.org/directory \
    -v /etc/letsencrypt:/etc/letsencrypt \
    -p 80:80 -p 443:443 \
    bradjonesllc/docker-haproxy-letsencrypt
```

You will almost certainly want to create an image `FROM` this image or
mount your `haproxy.cfg` at `/usr/local/etc/haproxy/haproxy.cfg`.

### Alternatives

HAProxy is powerful, but notoriously difficult to configure. If you don't require
HAProxy's functionality per se, consider [this similar image for Nginx](https://github.com/BradJonesLLC/docker-nginx-letsencrypt).

### License and Copyright

&copy; Brad Jones LLC, Licensed under GPL-2. Some components MIT license.

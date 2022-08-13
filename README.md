# Nginx image (based on the official Nginx image) with ACME.sh script for free and automated Let's Encrypt certs

**Nginx container image with the the [acme.sh](https://github.com/acmesh-official/acme.sh) ACME client installed for free and automated Let's Encrypt SSL certificates.**

For now, this image is based on the nginx:stable-alpine image, to make it easy for me to generate up to date images when
new versions of the base Nginx images are released.
TODO: Using e.g. GitHub actions, automate the building and publishing of new images when new versions of the Nginx image are released.

## HOWTO get an Nxinx reverse proxy up and running in a container with SSL certificates


1. Create Docker volume that holds the /etc/nginx configuration directory so we can keep the container stateless
   ```sh
   docker volume create nginx-acme-etc-vol
   ```

2. Create Docker volume that holds the nginx logs
   ```sh
   docker volume create nginx-acme-log-vol
   ```

3. Create a new user-defined docker bridged network
   ```sh
   docker network create nginx-acme-net
   ```

4. Start the container
   ```sh
   docker run \
	   -d \
	   --restart unless-stopped \
	   --name nginx-acme \
	   --hostname nginx-acme \
	   --network nginx-acme-net \
	   --publish 80:80/TCP \
	   --publish 443:443/TCP \
	   -e ACCOUNT_CONF_PATH=/etc/nginx/ssl/acme.sh.conf \
	   -v nginx-acme-etc-vol:/etc/nginx \
	   -v nginx-acme-log-vol:/var/log/nginx \
      mraming/docker-nginx-acme:stable-alpine
   ```

5. Edit the ssl/acme.sh.conf file that now resides on the `nginx-acme-etc-vol` volume and update the email address.
   (On my Ubuntu 22.04 test system, this file can be found in `/var/lib/docker/volumes/nginx-acme-etc-vol/_data/ssl` as root (sudo))

6. Generate Diffie-Hellman-Parameter to further improve security, we generate Diffie-Hellman parameter with 4096 bits. This
   will take a while (depending on hardware speed).
   ```sh
   docker exec -it nginx-acme openssl dhparam -out /etc/nginx/ssl/dhparam.pem 4096
   ```

   TODO: Automate this step so the dhparam.pem file is automatically generated the first time a container is started.

6. Configure an http server by adding a configuration file to the `conf.d` folder on the `nginx-acme-etc-vol` volume.
   (see `sample-conf.d/example.com.conf` in this repository for a template).
   Note: You must ommit the https server section initially when generating the associated SSL certificate for the first time, otherwise Nginx will not load the configuration due to the missing certificate files.

   Note: Mozilla has a great [SSL Configuration Generator](https://mozilla.github.io/server-side-tls/ssl-config-generator/) tool to help generate this configuration and the settings that we have in our default ssl/ssl.conf file.

7. Test the new Nginx configuration and when no issues are found, reload it:
   ```sh
   docker exec nginx-acme nginx -t
   docker exec nginx-acme nginx -s reload
   ```

8. Request the certificate from Let's Encrypt using one of the following commands:

   When using HTTP-01 validation:
   ```sh
   docker exec nginx-acme acme.sh --issue -w /var/www/example.com -d example.com --server letsencrypt
   ```

   When using DNS-01 validation, for example using Hurricane Electric's free DNS service.
   This example assumes that the username and password are set using additional environment variables on the `docker run` command:
      ```
      -e HE_Username="MyHeNetUserName" \
      -e HE_Password="LongAndSecureRandomPassword" \
      ```
   The example below uses the Let's Encrypt staging CA - it's always a good idea to do your initial testing with the staging CA to prevent hitting rate limits for too many failed validations for example. Once you successfully obtained a certificate from the staging CA, you re-request the certificate from the production CA (which will require the --force parameter because the certificate is not due for renewal yet)

   ```sh
   docker exec nginx-acme \
      acme.sh --issue \
      --dns dns_he \
      -d example.com -d '*.example.com' \
      --server letsencrypt_test \
      --force \
      --ocsp-must-staple
   ```

## HOWTO Build and publish this docker container image

1. Clone the git repo on a Linux machine with Docker installed - I used WSL2 on my Windows 10 machine with Docker Desktop
   for Windows installed and configured for use with WSL2:
   ```sh
   git clone https://github.com/mraming/docker-nginx-acme.git
   ```

2. Ensure you're logged in to the Docker Hub with the `docker login` command so you don't hit rate limits and can publish the
   image.

2. Make the `alpline` folder (that holds the `Dockerfile`) the current directory

3. Build the image with the following command, noting the --no-cache option to ensure the latest Nginx base image is
   downloaded
   ```sh
   docker build --no-cache -t mraming/docker-nginx-acme .
   ```

   Note: The first time I got an error message (which I unfortunately forgot to capture); the solution/workaround was to use the following command to build the image. On subsequent attempts I used the command above without problems:
   ```sh
   DOCKER_BUILDKIT=0  docker build --no-cache -t mraming/docker-nginx-acme . 
   ```

4. Tag the image you just build (adjust the version number to match the version for the current *stable* version of the 
   [Docker official Nginx image](https://hub.docker.com/_/nginx/)) and update the command as required:
   ```sh
   docker tag mraming/docker-nginx-acme mraming/docker-nginx-acme:1.22.0-alpine
   docker tag mraming/docker-nginx-acme mraming/docker-nginx-acme:stable-alpine
   ```

5. Finally, you can publish the image in Docker Hub with the following commands:
   ```sh
   docker push mraming/docker-nginx-acme:1.22.0-alpine
   docker push mraming/docker-nginx-acme:stable-alpine
   ```
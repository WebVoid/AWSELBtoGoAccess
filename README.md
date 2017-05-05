# Elastic LoadBalancer to GoAccess gate
## Introduction
This Docker container provides a bridge between the logs produced by the [AWS Elastic LoadBalancer](https://aws.amazon.com/fr/elasticloadbalancing/) and the [real-time web log analyzer GoAccess](https://goaccess.io/). It basically fetches all the log files stocked on an [AWS S3](https://aws.amazon.com/fr/s3/) Bucket and generates html reports on these datas.

## Prerequisites
This tutorial considers that you already have an AWS Elastic LoadBalancer configured and that he already writes it's logs to an S3 Bucket. If your ELB is not already storing it's logs to an S3 Bucket, you can activate it by following these few simple steps (2 minutes):
* Go to your [AWS Management Console](https://console.aws.amazon.com/console/home)
* Go to your EC2 management console
* In the left panel, click on **Load Balancers** under *LOAD BALANCING*
* Select yout load balancer
* On the very bottom of the *Description* tab, click the last button
* Check the **Enable access logs** checkbox
* Give your bucket an unique name
* Check the last checkbox, which is a magic one and is not explained in the AWS tutorials but will create for you the destination bucket with all the good permissions to write in it
* Click **Save**
* Et voilà ! Your ELB will now write it's logs to S3 =D

## How it works
### What is already in the container
All these tools are already presents in the container (sorted from logs to client)
* [S3cmd](http://s3tools.org/s3cmd) to fetch logs the AWS ELB logs from the S3 Bucket
* [ZCat](http://www.fichepratique.com/linux/zcat.php) to give GoAccess logs without uncompressing them manually
* [GoAccess](https://goaccess.io/) to generate reports from given logs
* [**Nginx web server**](https://www.nginx.com/) to serve static files and provide basic authentication
### What is done at runtime
Once at runtime and then every $REFRESH_DELAY (explained in the Installation part of this doc) seconds, is done the following:
* Sync logs from the S3 Bucket to the `/data` directory
* Generate reports and export them into the `/var/www/html/index/html` file

## Installation
### Considerations
Before using this image, we invite you to consider that mounting a volume to the `/data` folder is an unnecessary step. On the other hand, this will permit you having a **persistent logs folder**, resulting in not having to sync down **all** the log files from your S3 Bucket each time you will start the service. These files will be numerous. Very, very, numerous, so we really recommand mounting a volume to the /data folder.

### A point on environment variables
The following environment variables are required for running this container:
* **AWS_ACCESS_KEY**: this is the access key given by amazon to you to manage your services from external services like the [AWS Cli](https://aws.amazon.com/fr/cli/). Accesses can be managed using [this AWS Guide](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)
* **AWS_SECRET_KEY**: same as above
* **HTTP_USER**: as the GoAccess service has no authentication system, we use nginx to provide you a [Basic Authentication](https://en.wikipedia.org/wiki/Basic_access_authentication). This is the user used to authenticate to the metrics panel
* **HTTP_PASSWD**: same as above, but this will be the password
* **REFRESH_DELAY**: this value, expressed in seconds, is the amount of time the server will wait to refresh data (fetch logs from S3 and generate reports). A long time will make less API calls and cost less, but will be less real-time alike. We use 600 (10 minutes) for this value.
* **S3_LINK**: this is the link S3cmd will use to fetch your log files. It's format looks like `s3://<Bucket>/<Prefix>/AWSLogs/<account_id>/elasticloadbalancing/<region>`, where the *Bucket* is the Bucket in which you configured your ELB to store your log files, *Prefix* is mandatory, *account_id* is the id of the account owning the ELB (you can go to your S3 Bucket and check it out) and *region* is mandatory. In fact you could stop at the `s3://<Bucket>/<Prefix>/` but we recommand at least going down to the `elasticloadbalancing` folder.

### Installing on your own host
* Get the image by running a `docker pull <image>`
* Put yourself in the folder where you want to keep your log files persistent
* Run the following command:
```
docker run \
        -p 80:80 \
        -v ./data:/data \
        -e AWS_ACCESS_KEY="<aws_api_access_key>" \
        -e AWS_SECRET_KEY="<aws_api_secret_key>" \
        -e HTTP_USER="<user_for_http_basic_auth>" \
        -e HTTP_PASSWD="<password_for_http_basic_auth>" \
        -e REFRESH_DELAY="<server_refresh_delay_in_seconds>" \
        -e S3_LINK="<your_s3_bucket_link>" \
        <image>
```

### Installing using a container service (like [Google Cloud](https://cloud.google.com/) or [AWS ECS](https://aws.amazon.com/fr/documentation/ecs/))
This image does not require any high cpu or ram amount to run, as it's only composed of a very basic nginx server with a few things around. The weakest configuration you can have will be more than enough.
* Exposed ports:
    * The nginx is listening to port 80
* Volumes:
    * A volume to the `/data` folder
* Environment variables:
    * AWS_ACCESS_KEY: <aws_api_access_key>
    * AWS_SECRET_KEY: <aws_api_secret_key>
    * HTTP_USER: <user_for_http_basic_auth>
    * HTTP_PASSWD: <password_for_http_basic_auth>
    * REFRESH_DELAY: <server_refresh_delay_in_seconds>
    * S3_LINK: <your_s3_bucket_link>

## Usage
### Basic
Once the container is fully launched, you can access it using `http://<host>`.

### Using the aut-reload feature
The auto-reload feature reloads automatically the page at regular intervals. To use it, simply go to `http://<host>/?r=<interval>` where interval is the number of seconds between each reload.

## Building the image
You can fetch and build this image from the associated github repository.

### Files
The files in the repository are organized as following:
* **custom.js**: this file will be included in the report page, it basically provides support for auto-refresh
* **default.conf**: nginx vhost configuration file
* **Dockerfile**: no need to explain, if you read this part you shall know what this is
* **goaccess.conf**: file that contains the log parsing patterns for GoAccess - the given file is up to date for current ELB logs format (2017-05-05)
* **README.md**: I dare you to ask what this file is for
* **start.sh**: script that runs all the logic of fetching logs and generating reports (also created Basic Authentication users)

### Building
You can build the image by browsing into the cloned directory with your terminal and run `docker build . -t <image_tag>`. More info on how to build an image on the [Docker Reference](https://docs.docker.com/engine/reference/commandline/build/).

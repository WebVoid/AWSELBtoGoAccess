FROM debian

# Install required packages
RUN apt-get update
RUN apt-get install -y lsb-release wget python3 nginx zutils apache2-utils

# Install s3cmd
RUN wget https://bootstrap.pypa.io/get-pip.py
RUN python get-pip.py
RUN pip install s3cmd

# Install GoAccess
RUN echo "deb http://deb.goaccess.io/ $(lsb_release -cs) main" | tee -a /etc/apt/sources.list.d/goaccess.list
RUN wget -O - https://deb.goaccess.io/gnugpg.key | apt-key add -
RUN apt-get update
RUN apt-get -y install goaccess

# Configure GoAccess
ADD goaccess.conf /etc/
RUN mkdir /data

# Export nginx config
ADD default.conf /etc/nginx/sites-available/default

# Add sart script
ADD start.sh /root
RUN chmod +x /root/start.sh

# Add custom.js file, for auto refresh feature from dashboard
ADD custom.js /var/www/html

# Add waiting file
RUN echo "Please wait while reports are generating, you will be redirected automatically... <script>setTimeout(() => { window.location.reload(); }, 10000)</script>" > /var/www/html/index.html

EXPOSE 80

CMD ["/root/start.sh"]

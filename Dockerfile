FROM centos:8
MAINTAINER Daniel Gehrlein <d.gehrlein@outlook.com>
WORKDIR /tmp
RUN dnf clean all \
   ;dnf install -y epel-release \
   ;dnf makecache \
   ;dnf install -y python3-django \
                   python3-lxml \
                   python3-libvirt \
                   python3-pytz \
                   python3-libguestfs \
                   cyrus-sasl-md5 \
                   supervisor \
                   nginx \
                   openssh-clients \
    ;dnf clean all

RUN pip3 install websockify==0.9.0 gunicorn==20.0 rwlock

RUN curl -L https://github.com/retspen/webvirtcloud/tarball/master | tar xzC /opt/ \
   ;mv /opt/retspen-webvirtcloud* /opt/webvirtcloud \
   ;cp -f /opt/webvirtcloud/conf/supervisor/webvirtcloud.conf /etc/supervisord.d/webvirtcloud.ini \
   ;sed -i 's/\/srv/\/opt/g' /etc/supervisord.d/webvirtcloud.ini \
   ;sed -i 's/\/opt\/webvirtcloud\/venv\/bin\/gunicorn/\/usr\/local\/bin\/gunicorn/' /etc/supervisord.d/webvirtcloud.ini \
   ;sed -i 's/\/opt\/webvirtcloud\/venv\/bin\/python3/\/usr\/bin\/python3/' /etc/supervisord.d/webvirtcloud.ini \
   ;sed -i 's/user=www-data/user=root/g' -i /etc/supervisord.d/webvirtcloud.ini \
   ;mkdir -p /run/supervisor/ \
   ;cp /opt/webvirtcloud/conf/nginx/webvirtcloud.conf /etc/nginx/conf.d/webvirtcloud.conf \
   ;sed -i 's/\/srv\/webvirtcloud/\/opt\/webvirtcloud/' /etc/nginx/conf.d/webvirtcloud.conf \
   ;ln -sf /dev/stdout /var/log/nginx/access.log \
   ;ln -sf /dev/stderr /var/log/nginx/error.log \
   ;head -n $(grep -n 'include /etc/nginx/conf.d' /etc/nginx/nginx.conf | cut -f1 -d:) \
         /etc/nginx/nginx.conf > /etc/nginx/nginx.conf.2 \
   ;echo '}' >> /etc/nginx/nginx.conf.2 \
   ;mv -f /etc/nginx/nginx.conf.2 /etc/nginx/nginx.conf \
   ;exit 0

RUN echo "*" >> /root/.ssh/config \
   ;echo "  StrictHostKeyChecking no" >> /root/.ssh/config

ADD entrypoint.sh /opt/entrypoint.sh
ADD conf/supervisord.ini /etc/supervisord.d/webvirtcloud.ini

WORKDIR /opt
ENTRYPOINT ["/usr/bin/bash", "/opt/entrypoint.sh"]
EXPOSE 80
EXPOSE 6080
CMD /usr/bin/supervisord -c /etc/supervisord.conf -n

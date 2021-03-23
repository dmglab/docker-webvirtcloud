FROM centos:8
MAINTAINER Daniel Gehrlein <d.gehrlein@outlook.com>
WORKDIR /tmp
RUN dnf clean all \
   ;dnf install -y epel-release \
   ;dnf makecache \
   ;dnf install -y python3-devel \
                   python3-libguestfs \
                   python3-lxml \
                   cyrus-sasl-md5 \
                   gcc \
                   glibc \
                   libvirt-devel \
                   iproute-tc \
                   nginx \
                   supervisor \
                   git \
                   openssh-clients \
   ;dnf clean all

RUN curl -L https://github.com/retspen/webvirtcloud/tarball/master | tar xzC /opt/ \
   ;mv /opt/retspen-webvirtcloud* /opt/webvirtcloud \
   ;pip3 install -r /opt/webvirtcloud/conf/requirements.txt \
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

RUN mkdir -p /root/.ssh \
   ;echo "Host *" >> /root/.ssh/config \
   ;echo "  StrictHostKeyChecking no" >> /root/.ssh/config

ADD entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh
ADD conf/supervisord.ini /etc/supervisord.d/webvirtcloud.ini

WORKDIR /opt
ENTRYPOINT ["/opt/entrypoint.sh"]
EXPOSE 80
EXPOSE 6080
CMD /usr/bin/supervisord -c /etc/supervisord.conf -n

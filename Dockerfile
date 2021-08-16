FROM debian:buster-slim

# culr (optional) for downloading/browsing stuff
# openssh-client (required) for creating ssh tunnel
# psmisc (optional) I needed it to test port binding after ssh tunnel (eg: netstat -ntlp | grep 6443)
# nano (required) buster-slim doesn't even have less. so I needed an editor to view/edit file (eg: /etc/hosts) 
# jq for parsing json (output of az commands, kubectl output etc)
# groff needed for aws cli
RUN apt-get update && apt-get install -y \
	apt-transport-https \
	ca-certificates \
	curl \
    openssh-client \
	psmisc \
	nano \
	less \
	net-tools \
	groff \
	unzip \
	&& curl -L https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
	&& chmod +x /usr/local/bin/kubectl

RUN curl -o /usr/local/bin/jq -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
  	chmod +x /usr/local/bin/jq

RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip

# ENV DOCKERVERSION=20.10.8
# RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKERVERSION}.tgz \
#   && tar xzvf docker-${DOCKERVERSION}.tgz --strip 1 \
#                  -C /usr/local/bin docker/docker \
#   && rm docker-${DOCKERVERSION}.tgz

# COPY .ssh/id_rsa /root/.ssh/
# COPY .ssh/known_hosts /root/.ssh/
# RUN chmod 600 /root/.ssh/id_rsa

COPY binaries/init.sh /usr/local/
RUN chmod +x /usr/local/init.sh

COPY binaries/tmc /usr/local/bin/
RUN chmod +x /usr/local/bin/tmc


ENTRYPOINT [ "/usr/local/init.sh"]
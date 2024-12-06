### OCP Mon plugins 

Ready image available (prasenforu/ocp-monplug:v1)

- Download & Build [REF](https://github.com/openshift/console/issues/14093#issuecomment-2518248425)

```
wget https://github.com/openshift/monitoring-plugin/archive/refs/heads/release-4.16.zip
unzip release-4.16.zip
cd monitoring-plugin-release-4.16/

cat <<EOF | tee Dockerfile
FROM node:18.1.0-alpine AS builder

WORKDIR /usr/src/app

#RUN npm install --global yarn

ENV HUSKY=0

COPY package.json .
COPY yarn.lock .
RUN yarn

COPY ./console-extensions.json .
COPY ./tsconfig.json .
COPY ./webpack.config.ts .
COPY ./locales ./locales
COPY ./src ./src
RUN yarn build

FROM amazonlinux:2023.6.20241121.0

RUN INSTALL_PKGS="nginx" && \
    dnf install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum -y clean all --enablerepo='*' && \
    chown -R 1001:0 /var/lib/nginx /var/log/nginx /run && \
    chmod -R ug+rwX /var/lib/nginx /var/log/nginx /run

#USER 1001

COPY --from=builder /usr/src/app/dist /usr/share/nginx/html

ENTRYPOINT ["nginx", "-g", "daemon off;"]
EOF

docker build -t prasenforu/ocp-monplug:v2 .
docker login
docker push prasenforu/ocp-monplug:v2
```

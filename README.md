# buildInDocker
# Valint in Docker

# Background

Nowadays, many devops prefere to perform bulid steps as part of a `docker build` process. 

Following we shall see how to use Scribe tools to generate attestation in this use case.

We shall address two usecases:

1. The Dockerfile specifies the the built image. In this case, `valint` can create attestations along the build process, but cannot create an attestation of the final docker image (because it is running whithin it while being built).
2. The Dockerfile is used to build another image. This use case requires running Docker within Docker, and is not recommended due to security concerns.

# Use Case

Lets take as a use case the following Dockerfile of a typical node project:

```docker
# Stage 1: Build Vue project
FROM node:lts-alpine as build-stage

# Install Vue CLI
RUN npm install -g @vue/cli

# Set working directory
WORKDIR /app

# Create new Vue project
RUN vue create -d my-app

# Navigate into the project directory
WORKDIR /app/my-app

# Build the Vue app in production mode
RUN npm run build

# Stage 2: Setup Nginx
FROM nginx:stable-alpine as production-stage

# Copy built app to Nginx serve directory
COPY --from=build-stage /app/my-app/dist /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
```

This Dockerfile builds a minimal vue project. Typical to a frontend javascript project, the final artifacts are packed to a small set of files which are later uploaded to a web-server. In this docker file, first the vue project is built, and later, the artifacts are copied into a web-server image.

 To build it run the following command (assuming the docker is in your current folder:

```bash
docker build -t my-app:1.0 .
```

You can run the image with the following command:

```bash
docker run -p 8080:80 my-vue-app
```

You can open your browser at `http://localhost:8080` to see the results.

# Instrumenting the Docker with `valint`

To instrument the docker with `valint` we need to install it within the docker. Assuming we do not need `valint` running in the production image, we should install it to the `builder` stage of the Docker file:

```docker
# Stage 1: Build Vue project
FROM node:lts-alpine as build-stage

# Install Scribe CLI - valint
RUN apk update && apk add curl && apk add tar
RUN curl -sSfL https://get.scribesecurity.com/install.sh  | sh -s -- -t valint

# Install Vue CLI 
RUN npm install -g @vue/cli

# Set working directory
WORKDIR /app

# Create new Vue project
RUN vue create -d my-app 

# Navigate into the project directory
WORKDIR /app/my-app

# Build the Vue app in production mode
RUN npm run build

# Use valint to create an SBOM of the project with dependencies
RUN /root/.scribe/bin/valint bom dir:. --output-file my-app-sbom.json

# Stage 2: Setup Nginx
FROM nginx:stable-alpine as production-stage

# Copy built app to Nginx serve directory
COPY --from=build-stage /app/my-app/dist /usr/share/nginx/html

# Copy SBOM to final image
COPY --from=build-stage /app/my-app/my-app-sbom.json /usr/share/nginx/html/sbom.json

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
```

Explanation:

The the valint tool is installed at the beginning of the Dockerfile. It is used to generate an SBOM of the npm project after build; such an SBOM provides visibility to the packages that where later built into the final javascript files pushed to the NGINX web server. Such visibility would be lost had we just created an SBOM of the final docker image; The final image does not have all these dependencies in a recognizable way.

Building and running the image is done as done before. Running the image and directing you browser to `http://localhost:8080/sbom.json` will reviel the SBOM created.

To upload the SBOM to Scribe-Hub you will need to add arguments to the Dockerfile, as follows:

```docker
# Stage 1: Build Vue project
FROM node:lts-alpine as build-stage

# Install Scribe CLI - valint
RUN apk update && apk add curl && apk add tar
RUN curl -sSfL https://get.scribesecurity.com/install.sh  | sh -s -- -t valint

# Scribe Hub params
ARG SCRIBE_CLIENT_ID
ARG SCRIBE_CLIENT_SECRET
# Install Vue CLI 
RUN npm install -g @vue/cli

# Set working directory
WORKDIR /app

# Create new Vue project
RUN vue create -d my-app 

# Navigate into the project directory
WORKDIR /app/my-app

# Build the Vue app in production mode
RUN npm run build

# Use valint to create an SBOM of the project with dependencies
RUN /root/.scribe/bin/valint bom dir:. --output-file my-app-sbom.json -U ${SCRIBE_CLIENT_ID} -P ${SCRIBE_CLIENT_SECRET}

# Stage 2: Setup Nginx
FROM nginx:stable-alpine as production-stage

# Copy built app to Nginx serve directory
COPY --from=build-stage /app/my-app/dist /usr/share/nginx/html

# Copy SBOM to final image
COPY --from=build-stage /app/my-app/my-app-sbom.json /usr/share/nginx/html/sbom.json

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
```

And when building you will need to provide ScribeHub credentials:

```bash
docker build -t my-app:1.0 --build-arg SCRIBE_CLIENT_ID=$SCRIBE_CLIENT_ID --build-arg SCRIBE_CLIENT_SECRET=$SCRIBE_CLIENT_SECRET .
```

This will both upload the the SBOM to Scribe, and will aslo produce the file that can be accessed from the web server.

Additional parameters for `valint` such as signing keys, output type etc. can be passed using additional args, in a same manner.

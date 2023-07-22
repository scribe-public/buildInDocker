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

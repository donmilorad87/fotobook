# =============================================================================
# Fotobook Web Application - Multi-Stage Dockerfile
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Node.js - Build Frontend Assets
# -----------------------------------------------------------------------------
FROM node:20-alpine AS node-builder

WORKDIR /build

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production=false

# Copy source files
COPY vite.config.js ./
COPY resources/ ./resources/

# Build production assets
RUN npm run build

# -----------------------------------------------------------------------------
# Stage 2: Composer - Install PHP Dependencies
# -----------------------------------------------------------------------------
FROM composer:2 AS composer-builder

WORKDIR /build

# Copy composer files
COPY composer.json composer.lock ./

# Install dependencies without dev packages
RUN composer install \
    --no-dev \
    --no-scripts \
    --no-autoloader \
    --prefer-dist \
    --ignore-platform-reqs

# Copy application code
COPY . .

# Generate optimized autoloader
RUN composer dump-autoload --optimize --no-dev

# -----------------------------------------------------------------------------
# Stage 3: Production PHP-FPM Image
# -----------------------------------------------------------------------------
FROM php:8.4-fpm-alpine AS app

# Install system dependencies
RUN apk add --no-cache \
    libpq-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    freetype-dev \
    zip \
    unzip \
    git \
    curl \
    icu-dev \
    oniguruma-dev \
    linux-headers

# Configure and install PHP extensions
RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
    --with-webp

RUN docker-php-ext-install \
    pdo \
    pdo_pgsql \
    pgsql \
    gd \
    bcmath \
    intl \
    mbstring \
    opcache \
    pcntl \
    sockets

# Install Redis extension
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del .build-deps

# Copy PHP configuration
COPY docker/php/php.ini /usr/local/etc/php/conf.d/99-custom.ini
COPY docker/php/php-fpm.conf /usr/local/etc/php-fpm.d/zz-custom.conf

# Set working directory
WORKDIR /var/www/html

# Create storage directories
RUN mkdir -p storage/framework/{sessions,views,cache} \
    && mkdir -p storage/logs \
    && mkdir -p bootstrap/cache

# Copy application from composer stage
COPY --from=composer-builder /build/vendor ./vendor
COPY --from=composer-builder /build .

# Copy built assets from node stage
COPY --from=node-builder /build/public/build ./public/build

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 storage bootstrap/cache

# Create non-root user for running the application
USER www-data

# Expose PHP-FPM port
EXPOSE 9000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD php-fpm -t || exit 1

CMD ["php-fpm"]

# -----------------------------------------------------------------------------
# Stage 4: Development Image (optional, for local development)
# -----------------------------------------------------------------------------
FROM app AS dev

USER root

# Install development tools
RUN apk add --no-cache \
    vim \
    nano

# Install Xdebug for development
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && apk del .build-deps

# Copy development PHP configuration
COPY docker/php/php-dev.ini /usr/local/etc/php/conf.d/99-dev.ini

USER www-data

CMD ["php-fpm"]

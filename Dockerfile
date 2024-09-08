FROM php:8.1-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Accept build arguments for user and group
ARG USER_ID
ARG GROUP_ID

ARG USER_NAME
ARG GROUP_NAME

# Create a non-root user and group with the specified IDs
RUN groupadd -g ${GROUP_ID} ${GROUP_NAME} && \
    useradd -u ${USER_ID} -g ${GROUP_NAME} -m -d /home/${USER_NAME} -s /bin/bash ${USER_NAME}

# Set working directory
WORKDIR /var/www/html

# Copy composer files and install dependencies
COPY composer.json composer.lock ./
RUN composer install --no-scripts --no-autoloader

# Install Node.js and npm
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Copy existing application directory contents
COPY . /var/www/html

# Change ownership to the non-root user and group
RUN chown -R ${USER_NAME}:${GROUP_NAME} /var/www/html

# Switch to the non-root user
USER ${USER_NAME}


# Install node dependencies
RUN npm install
# Expose port 9000 and start php-fpm server
EXPOSE 9000
CMD ["php-fpm"]
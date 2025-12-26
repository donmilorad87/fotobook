/**
 * Google Drive Image Loader
 * Fetches images through backend proxy to avoid CORS issues.
 * Loads images asynchronously without blocking.
 */

class GoogleImageLoader {
    constructor(options = {}) {
        this.selector = options.selector || '.gallery-item-image[data-google-image-id]';
        this.concurrency = options.concurrency || 6;
        this.retryAttempts = options.retryAttempts || 3;
        this.retryDelay = options.retryDelay || 1000;
        this.queue = [];
        this.activeRequests = 0;
        this.loadedImages = new Map(); // Cache loaded blob URLs
    }

    init() {
        const images = document.querySelectorAll(this.selector);
        if (images.length === 0) return;

        images.forEach(img => {
            const imageId = img.dataset.googleImageId;
            if (imageId) {
                img.classList.add('google-loading-image');
                this.queue.push({ img, imageId, attempts: 0 });
            }
        });

        this.processQueue();
    }

    async processQueue() {
        while (this.queue.length > 0 && this.activeRequests < this.concurrency) {
            const item = this.queue.shift();
            if (item) {
                this.activeRequests++;
                this.loadImage(item).finally(() => {
                    this.activeRequests--;
                    this.processQueue();
                });
            }
        }
    }

    async loadImage(item) {
        const { img, imageId } = item;
        
        // Check if already loaded (cached)
        if (this.loadedImages.has(imageId)) {
            img.src = this.loadedImages.get(imageId);
            img.classList.remove('google-loading-image');
            img.classList.add('google-loaded-image');
            return;
        }

        try {
            // Use backend proxy to avoid CORS issues
            const url = `/image/${imageId}`;

            const response = await fetch(url);

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}`);
            }

            const blob = await response.blob();
            const objectUrl = URL.createObjectURL(blob);

            // Cache the blob URL
            this.loadedImages.set(imageId, objectUrl);

            img.src = objectUrl;
            img.classList.remove('google-loading-image');
            img.classList.add('google-loaded-image');

            // Dispatch event for other components (like lightbox)
            img.dispatchEvent(new CustomEvent('google-image-loaded', {
                bubbles: true,
                detail: { imageId, objectUrl }
            }));

        } catch (error) {
            item.attempts++;

            if (item.attempts < this.retryAttempts) {
                await this.delay(this.retryDelay * item.attempts);
                this.queue.push(item);
            } else {
                console.warn(`Failed to load image after ${this.retryAttempts} attempts:`, imageId, error);
                img.classList.remove('google-loading-image');
                img.classList.add('google-error-image');
            }
        }
    }

    // Get cached URL for an image ID
    getCachedUrl(imageId) {
        return this.loadedImages.get(imageId) || null;
    }

    // Load a single image by ID (for lightbox)
    async loadSingleImage(imageId) {
        if (this.loadedImages.has(imageId)) {
            return this.loadedImages.get(imageId);
        }

        try {
            // Use backend proxy to avoid CORS issues
            const url = `/image/${imageId}`;
            const response = await fetch(url);

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}`);
            }

            const blob = await response.blob();
            const objectUrl = URL.createObjectURL(blob);
            this.loadedImages.set(imageId, objectUrl);

            return objectUrl;
        } catch (error) {
            console.error('Failed to load single image:', imageId, error);
            return null;
        }
    }

    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}

// Global instance
let googleImageLoader = null;

// Auto-initialize on DOM ready
document.addEventListener('DOMContentLoaded', () => {
    googleImageLoader = new GoogleImageLoader({
        selector: '.gallery-item-image[data-google-image-id]',
        concurrency: 6,
        retryAttempts: 3,
    });
    googleImageLoader.init();
});

// Export for other scripts
window.GoogleImageLoader = GoogleImageLoader;
window.getGoogleImageLoader = () => googleImageLoader;

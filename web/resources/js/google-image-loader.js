/**
 * Google Drive Image Loader
 * Fetches images through backend proxy to avoid CORS issues.
 * Uses IndexedDB for persistent caching across sessions.
 * Uses memory cache for fast access within session.
 */

class GoogleImageLoader {
    constructor(options = {}) {
        this.selector = options.selector || '.gallery-item-image[data-google-image-id]';
        this.concurrency = options.concurrency || 6;
        this.retryAttempts = options.retryAttempts || 3;
        this.retryDelay = options.retryDelay || 1000;
        this.queue = [];
        this.activeRequests = 0;
        this.loadedImages = new Map(); // Memory cache for blob URLs
        this.cacheService = window.imageCacheService || null;
    }

    init() {
        const images = document.querySelectorAll(this.selector);
        if (images.length === 0) return;

        const imageCount = images.length;
        for (let i = 0; i < imageCount; i++) {
            const img = images[i];
            const imageId = img.dataset.googleImageId;
            if (imageId) {
                img.classList.add('google-loading-image');
                this.queue.push({ img, imageId, attempts: 0 });
            }
        }

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

        // 1. Check memory cache first (fastest)
        if (this.loadedImages.has(imageId)) {
            this.applyImageToElement(img, this.loadedImages.get(imageId), imageId);
            return;
        }

        // 2. Check IndexedDB cache
        const cachedImage = await this.getFromIndexedDB(imageId);
        if (cachedImage) {
            const blobUrl = ImageCacheService.base64ToBlobUrl(
                cachedImage.data,
                cachedImage.contentType
            );
            this.loadedImages.set(imageId, blobUrl);
            this.applyImageToElement(img, blobUrl, imageId);
            return;
        }

        // 3. Fetch from backend API
        await this.fetchFromApi(item);
    }

    async getFromIndexedDB(imageId) {
        if (!this.cacheService) return null;

        try {
            return await this.cacheService.get(imageId);
        } catch (error) {
            return null;
        }
    }

    async saveToIndexedDB(imageId, base64Data, contentType) {
        if (!this.cacheService) return;

        try {
            await this.cacheService.set(imageId, base64Data, contentType);
        } catch (error) {
            // Silent fail - caching is optional
        }
    }

    async fetchFromApi(item) {
        const { img, imageId } = item;

        try {
            const url = `/image/${imageId}`;
            const response = await fetch(url);

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}`);
            }

            const contentType = response.headers.get('Content-Type') || 'image/jpeg';
            const blob = await response.blob();

            // Convert to base64 for IndexedDB storage
            const base64Data = await ImageCacheService.blobToBase64(blob);

            // Save to IndexedDB cache
            await this.saveToIndexedDB(imageId, base64Data, contentType);

            // Create blob URL for display
            const blobUrl = URL.createObjectURL(blob);
            this.loadedImages.set(imageId, blobUrl);

            this.applyImageToElement(img, blobUrl, imageId);

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

    applyImageToElement(img, blobUrl, imageId) {
        img.src = blobUrl;
        img.classList.remove('google-loading-image');
        img.classList.add('google-loaded-image');

        img.dispatchEvent(new CustomEvent('google-image-loaded', {
            bubbles: true,
            detail: { imageId, objectUrl: blobUrl }
        }));
    }

    // Get cached URL for an image ID (memory only)
    getCachedUrl(imageId) {
        return this.loadedImages.get(imageId) || null;
    }

    // Load a single image by ID (for lightbox)
    async loadSingleImage(imageId) {
        // 1. Check memory cache
        if (this.loadedImages.has(imageId)) {
            return this.loadedImages.get(imageId);
        }

        // 2. Check IndexedDB cache
        const cachedImage = await this.getFromIndexedDB(imageId);
        if (cachedImage) {
            const blobUrl = ImageCacheService.base64ToBlobUrl(
                cachedImage.data,
                cachedImage.contentType
            );
            this.loadedImages.set(imageId, blobUrl);
            return blobUrl;
        }

        // 3. Fetch from API
        try {
            const url = `/image/${imageId}`;
            const response = await fetch(url);

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}`);
            }

            const contentType = response.headers.get('Content-Type') || 'image/jpeg';
            const blob = await response.blob();

            // Convert to base64 for IndexedDB storage
            const base64Data = await ImageCacheService.blobToBase64(blob);

            // Save to IndexedDB cache
            await this.saveToIndexedDB(imageId, base64Data, contentType);

            // Create blob URL for display
            const blobUrl = URL.createObjectURL(blob);
            this.loadedImages.set(imageId, blobUrl);

            return blobUrl;
        } catch (error) {
            console.error('Failed to load single image:', imageId, error);
            return null;
        }
    }

    // Get cache statistics
    async getCacheStats() {
        const memoryCount = this.loadedImages.size;
        let indexedDbStats = { count: 0 };

        if (this.cacheService) {
            try {
                indexedDbStats = await this.cacheService.getStats();
            } catch (error) {
                // Ignore
            }
        }

        return {
            memory: memoryCount,
            indexedDb: indexedDbStats.count
        };
    }

    // Clear all caches
    async clearCache() {
        // Clear memory cache
        this.loadedImages.forEach(url => URL.revokeObjectURL(url));
        this.loadedImages.clear();

        // Clear IndexedDB cache
        if (this.cacheService) {
            try {
                await this.cacheService.clearAll();
            } catch (error) {
                // Ignore
            }
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

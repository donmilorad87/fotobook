/**
 * IndexedDB Image Cache Service
 * Caches images locally in the browser for fast retrieval.
 */

class ImageCacheService {
    constructor(options = {}) {
        this.dbName = options.dbName || 'fotobook_image_cache';
        this.storeName = options.storeName || 'images';
        this.dbVersion = options.dbVersion || 1;
        this.maxAge = options.maxAge || 7 * 24 * 60 * 60 * 1000; // 7 days default
        this.db = null;
        this.initPromise = null;
    }

    /**
     * Initialize the IndexedDB database.
     */
    init() {
        if (this.initPromise) {
            return this.initPromise;
        }

        this.initPromise = new Promise((resolve, reject) => {
            if (!window.indexedDB) {
                reject(new Error('IndexedDB not supported'));
                return;
            }

            const request = indexedDB.open(this.dbName, this.dbVersion);

            request.onerror = () => {
                reject(request.error);
            };

            request.onsuccess = () => {
                this.db = request.result;
                resolve(this.db);
            };

            request.onupgradeneeded = (event) => {
                const db = event.target.result;

                if (!db.objectStoreNames.contains(this.storeName)) {
                    const store = db.createObjectStore(this.storeName, { keyPath: 'id' });
                    store.createIndex('timestamp', 'timestamp', { unique: false });
                }
            };
        });

        return this.initPromise;
    }

    /**
     * Get cached image by ID.
     * Returns null if not found or expired.
     */
    async get(imageId) {
        await this.init();

        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([this.storeName], 'readonly');
            const store = transaction.objectStore(this.storeName);
            const request = store.get(imageId);

            request.onerror = () => {
                reject(request.error);
            };

            request.onsuccess = () => {
                const result = request.result;

                if (!result) {
                    resolve(null);
                    return;
                }

                const now = Date.now();
                if (now - result.timestamp > this.maxAge) {
                    this.delete(imageId).catch(() => {});
                    resolve(null);
                    return;
                }

                resolve(result);
            };
        });
    }

    /**
     * Store image in cache.
     */
    async set(imageId, base64Data, contentType) {
        await this.init();

        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([this.storeName], 'readwrite');
            const store = transaction.objectStore(this.storeName);

            const record = {
                id: imageId,
                data: base64Data,
                contentType: contentType || 'image/jpeg',
                timestamp: Date.now()
            };

            const request = store.put(record);

            request.onerror = () => {
                reject(request.error);
            };

            request.onsuccess = () => {
                resolve(record);
            };
        });
    }

    /**
     * Delete image from cache.
     */
    async delete(imageId) {
        await this.init();

        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([this.storeName], 'readwrite');
            const store = transaction.objectStore(this.storeName);
            const request = store.delete(imageId);

            request.onerror = () => {
                reject(request.error);
            };

            request.onsuccess = () => {
                resolve();
            };
        });
    }

    /**
     * Clear all expired entries.
     */
    async clearExpired() {
        await this.init();

        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([this.storeName], 'readwrite');
            const store = transaction.objectStore(this.storeName);
            const index = store.index('timestamp');
            const cutoff = Date.now() - this.maxAge;
            const range = IDBKeyRange.upperBound(cutoff);
            const request = index.openCursor(range);
            let deleted = 0;

            request.onerror = () => {
                reject(request.error);
            };

            request.onsuccess = (event) => {
                const cursor = event.target.result;
                if (cursor) {
                    cursor.delete();
                    deleted++;
                    cursor.continue();
                } else {
                    resolve(deleted);
                }
            };
        });
    }

    /**
     * Delete multiple images from cache.
     */
    async deleteMultiple(imageIds) {
        await this.init();

        const count = imageIds.length;
        const promises = [];

        for (let i = 0; i < count; i++) {
            promises.push(this.delete(imageIds[i]));
        }

        await Promise.all(promises);
        return count;
    }

    /**
     * Clear entire cache.
     */
    async clearAll() {
        await this.init();

        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([this.storeName], 'readwrite');
            const store = transaction.objectStore(this.storeName);
            const request = store.clear();

            request.onerror = () => {
                reject(request.error);
            };

            request.onsuccess = () => {
                resolve();
            };
        });
    }

    /**
     * Get cache statistics.
     */
    async getStats() {
        await this.init();

        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([this.storeName], 'readonly');
            const store = transaction.objectStore(this.storeName);
            const countRequest = store.count();

            countRequest.onerror = () => {
                reject(countRequest.error);
            };

            countRequest.onsuccess = () => {
                resolve({
                    count: countRequest.result,
                    dbName: this.dbName,
                    maxAge: this.maxAge
                });
            };
        });
    }

    /**
     * Convert blob to base64.
     */
    static blobToBase64(blob) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onloadend = () => {
                const base64 = reader.result.split(',')[1];
                resolve(base64);
            };
            reader.onerror = reject;
            reader.readAsDataURL(blob);
        });
    }

    /**
     * Convert base64 to blob URL.
     */
    static base64ToBlobUrl(base64, contentType) {
        const byteChars = atob(base64);
        const byteNumbers = new Array(byteChars.length);
        const len = byteChars.length;

        for (let i = 0; i < len; i++) {
            byteNumbers[i] = byteChars.charCodeAt(i);
        }

        const byteArray = new Uint8Array(byteNumbers);
        const blob = new Blob([byteArray], { type: contentType });

        return URL.createObjectURL(blob);
    }
}

// Global instance
window.ImageCacheService = ImageCacheService;
window.imageCacheService = new ImageCacheService({
    maxAge: 365 * 24 * 60 * 60 * 1000 // 1 year
});

// Clear expired entries on page load
document.addEventListener('DOMContentLoaded', () => {
    window.imageCacheService.clearExpired().catch(() => {});
});

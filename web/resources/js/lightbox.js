/**
 * Fotobook - Lightbox Component
 * Full-screen image viewer with keyboard navigation and selection
 * Uses GoogleImageLoader for async image loading
 */

class Lightbox {
    constructor(options = {}) {
        this.images = options.images || [];
        this.currentIndex = 0;
        this.isOpen = false;
        this.element = null;
        this.isLoading = false;

        this.init();
    }

    init() {
        this.createElement();
        this.bindEvents();
    }

    createElement() {
        this.element = document.createElement('div');
        this.element.className = 'lightbox';
        this.element.innerHTML = `
            <div class="lightbox-header">
                <div class="lightbox-counter">
                    <span class="lightbox-current">1</span> / <span class="lightbox-total">${this.images.length}</span>
                </div>
                <div class="lightbox-actions">
                    <button class="lightbox-btn lightbox-select-btn" aria-label="Select photo">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                        </svg>
                    </button>
                    <button class="lightbox-btn lightbox-close" aria-label="Close">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>
            </div>
            <div class="lightbox-content">
                <button class="lightbox-nav lightbox-nav--prev" aria-label="Previous">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" />
                    </svg>
                </button>
                <div class="lightbox-image-wrapper">
                    <div class="lightbox-loader" style="display: none;">
                        <div class="lightbox-spinner"></div>
                    </div>
                    <img class="lightbox-image" src="" alt="">
                </div>
                <button class="lightbox-nav lightbox-nav--next" aria-label="Next">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7" />
                    </svg>
                </button>
            </div>
            <div class="lightbox-footer">
                <div class="lightbox-info">
                    <h3 class="lightbox-filename"></h3>
                    <p class="lightbox-meta"></p>
                </div>
                <button class="lightbox-select">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                    </svg>
                    <span>Select</span>
                </button>
            </div>
            <div class="lightbox-hints">
                <span><kbd>←</kbd> <kbd>→</kbd> Navigate</span>
                <span><kbd>Space</kbd> Select</span>
                <span><kbd>Esc</kbd> Close</span>
            </div>
        `;
        document.body.appendChild(this.element);
    }

    bindEvents() {
        // Close button
        this.element.querySelector('.lightbox-close').addEventListener('click', () => this.close());

        // Navigation
        this.element.querySelector('.lightbox-nav--prev').addEventListener('click', () => this.prev());
        this.element.querySelector('.lightbox-nav--next').addEventListener('click', () => this.next());

        // Select buttons
        this.element.querySelector('.lightbox-select').addEventListener('click', () => this.toggleSelect());
        this.element.querySelector('.lightbox-select-btn').addEventListener('click', () => this.toggleSelect());

        // Keyboard navigation
        document.addEventListener('keydown', (e) => {
            if (!this.isOpen) return;

            switch (e.key) {
                case 'Escape':
                    this.close();
                    break;
                case 'ArrowLeft':
                    this.prev();
                    break;
                case 'ArrowRight':
                    this.next();
                    break;
                case ' ':
                    e.preventDefault();
                    this.toggleSelect();
                    break;
            }
        });

        // Click outside to close
        this.element.querySelector('.lightbox-content').addEventListener('click', (e) => {
            if (e.target.classList.contains('lightbox-content')) {
                this.close();
            }
        });
    }

    setImages(images) {
        this.images = images;
        this.element.querySelector('.lightbox-total').textContent = images.length;
    }

    open(index = 0) {
        this.currentIndex = index;
        this.isOpen = true;
        this.element.classList.add('is-open');
        document.body.style.overflow = 'hidden';
        this.updateDisplay();
    }

    close() {
        this.isOpen = false;
        this.element.classList.remove('is-open');
        document.body.style.overflow = '';
    }

    prev() {
        if (this.currentIndex > 0 && !this.isLoading) {
            this.currentIndex--;
            this.updateDisplay();
        }
    }

    next() {
        if (this.currentIndex < this.images.length - 1 && !this.isLoading) {
            this.currentIndex++;
            this.updateDisplay();
        }
    }

    async updateDisplay() {
        const image = this.images[this.currentIndex];
        if (!image) return;

        const imgEl = this.element.querySelector('.lightbox-image');
        const loader = this.element.querySelector('.lightbox-loader');

        // Update text content immediately
        this.element.querySelector('.lightbox-current').textContent = this.currentIndex + 1;
        this.element.querySelector('.lightbox-filename').textContent = image.filename || '';
        this.element.querySelector('.lightbox-meta').textContent = `Photo ${this.currentIndex + 1} of ${this.images.length}`;

        // Update navigation buttons
        const prevBtn = this.element.querySelector('.lightbox-nav--prev');
        const nextBtn = this.element.querySelector('.lightbox-nav--next');
        prevBtn.disabled = this.currentIndex === 0;
        nextBtn.disabled = this.currentIndex === this.images.length - 1;

        // Update selection state
        this.updateSelectionState();

        // Load image
        if (image.googleImageId) {
            this.isLoading = true;
            loader.style.display = 'flex';
            imgEl.style.opacity = '0.3';

            const googleLoader = window.getGoogleImageLoader?.();
            if (googleLoader) {
                const url = await googleLoader.loadSingleImage(image.googleImageId);
                if (url) {
                    imgEl.src = url;
                }
            }

            loader.style.display = 'none';
            imgEl.style.opacity = '1';
            this.isLoading = false;
        } else if (image.url) {
            imgEl.src = image.url;
        }

        imgEl.alt = image.filename || '';
    }

    updateSelectionState() {
        const image = this.images[this.currentIndex];
        const isSelected = window.gallerySelection?.isSelected(image.id);

        const selectBtn = this.element.querySelector('.lightbox-select');
        const selectBtnHeader = this.element.querySelector('.lightbox-select-btn');

        if (isSelected) {
            selectBtn.classList.add('is-selected');
            selectBtn.querySelector('span').textContent = 'Selected';
            selectBtnHeader.classList.add('is-selected');
        } else {
            selectBtn.classList.remove('is-selected');
            selectBtn.querySelector('span').textContent = 'Select';
            selectBtnHeader.classList.remove('is-selected');
        }
    }

    toggleSelect() {
        const image = this.images[this.currentIndex];
        if (!image || !window.gallerySelection) return;

        if (window.gallerySelection.isSelected(image.id)) {
            window.gallerySelection.deselectPicture(image.id);
        } else {
            window.gallerySelection.selectPicture(image.id);
        }

        this.updateSelectionState();
    }

    syncSelection(pictureId, isSelected) {
        // Called from GallerySelection when selection changes externally
        if (this.images[this.currentIndex]?.id === pictureId) {
            this.updateSelectionState();
        }
    }
}

// Initialize lightbox on DOM ready
document.addEventListener('DOMContentLoaded', () => {
    const galleryContainer = document.querySelector('.gallery-grid[data-gallery-slug]');
    if (galleryContainer) {
        // Collect image data from the grid
        const images = [];
        galleryContainer.querySelectorAll('.gallery-item').forEach((item, index) => {
            images.push({
                id: parseInt(item.querySelector('.gallery-item-checkbox')?.dataset.pictureId),
                googleImageId: item.dataset.googleImageId,
                filename: item.dataset.filename || `Photo ${index + 1}`,
            });
        });

        window.lightbox = new Lightbox();
        window.lightbox.setImages(images);
    }
});

// Export for manual use
window.Lightbox = Lightbox;

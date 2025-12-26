/**
 * Fotobook - Gallery Selection Handler
 * Handles photo selection on the public gallery page
 */

class GallerySelection {
    constructor(container) {
        this.container = container;
        this.selectedIds = new Set();
        this.selectionBar = document.querySelector('.selection-bar');
        this.selectionCount = document.querySelector('.selection-count span');
        this.submitBtn = document.querySelector('.selection-submit');
        this.clearBtn = document.querySelector('.selection-clear');

        this.init();
    }

    init() {
        // Bind checkbox clicks
        this.container.addEventListener('click', (e) => {
            const checkbox = e.target.closest('.gallery-item-checkbox');
            if (checkbox) {
                e.stopPropagation();
                const pictureId = parseInt(checkbox.dataset.pictureId);
                this.toggleSelection(pictureId, checkbox);
            }
        });

        // Bind item clicks to open lightbox
        this.container.addEventListener('click', (e) => {
            const item = e.target.closest('.gallery-item');
            if (item && !e.target.closest('.gallery-item-checkbox')) {
                const index = parseInt(item.dataset.index);
                window.lightbox?.open(index);
            }
        });

        // Bind clear selection
        this.clearBtn?.addEventListener('click', () => {
            this.clearSelection();
        });

        // Bind submit
        this.submitBtn?.addEventListener('click', () => {
            this.showSubmitModal();
        });

        // Load saved selection from sessionStorage
        this.loadSavedSelection();
    }

    toggleSelection(pictureId, checkbox) {
        if (this.selectedIds.has(pictureId)) {
            this.selectedIds.delete(pictureId);
            checkbox.classList.remove('is-selected');
        } else {
            this.selectedIds.add(pictureId);
            checkbox.classList.add('is-selected');
        }

        this.updateUI();
        this.saveSelection();

        // Sync with lightbox if open
        window.lightbox?.syncSelection(pictureId, this.selectedIds.has(pictureId));
    }

    selectPicture(pictureId) {
        this.selectedIds.add(pictureId);
        const checkbox = this.container.querySelector(`[data-picture-id="${pictureId}"]`);
        checkbox?.classList.add('is-selected');
        this.updateUI();
        this.saveSelection();
    }

    deselectPicture(pictureId) {
        this.selectedIds.delete(pictureId);
        const checkbox = this.container.querySelector(`[data-picture-id="${pictureId}"]`);
        checkbox?.classList.remove('is-selected');
        this.updateUI();
        this.saveSelection();
    }

    isSelected(pictureId) {
        return this.selectedIds.has(pictureId);
    }

    clearSelection() {
        this.selectedIds.clear();
        this.container.querySelectorAll('.gallery-item-checkbox').forEach(checkbox => {
            checkbox.classList.remove('is-selected');
        });
        this.updateUI();
        this.saveSelection();
    }

    updateUI() {
        const count = this.selectedIds.size;

        if (this.selectionCount) {
            this.selectionCount.textContent = count;
        }

        if (this.selectionBar) {
            if (count > 0) {
                this.selectionBar.classList.add('is-visible');
            } else {
                this.selectionBar.classList.remove('is-visible');
            }
        }
    }

    saveSelection() {
        const gallerySlug = this.container.dataset.gallerySlug;
        if (gallerySlug) {
            sessionStorage.setItem(`fotobook_selection_${gallerySlug}`, JSON.stringify([...this.selectedIds]));
        }
    }

    loadSavedSelection() {
        const gallerySlug = this.container.dataset.gallerySlug;
        if (gallerySlug) {
            const saved = sessionStorage.getItem(`fotobook_selection_${gallerySlug}`);
            if (saved) {
                try {
                    const ids = JSON.parse(saved);
                    ids.forEach(id => {
                        this.selectedIds.add(id);
                        const checkbox = this.container.querySelector(`[data-picture-id="${id}"]`);
                        checkbox?.classList.add('is-selected');
                    });
                    this.updateUI();
                } catch (e) {
                    console.error('Failed to load saved selection:', e);
                }
            }
        }
    }

    getSelectedIds() {
        return [...this.selectedIds];
    }

    showSubmitModal() {
        const modal = document.querySelector('.submit-modal');
        if (modal) {
            modal.classList.add('is-open');
            document.body.style.overflow = 'hidden';
        }
    }

    async submitSelection(clientName, clientEmail) {
        const gallerySlug = this.container.dataset.gallerySlug;
        const selectedIds = this.getSelectedIds();

        if (selectedIds.length === 0) {
            alert('Please select at least one photo.');
            return false;
        }

        try {
            const response = await fetch(`/gallery/${gallerySlug}/order`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.content,
                },
                body: JSON.stringify({
                    client_name: clientName,
                    client_email: clientEmail,
                    selected_picture_ids: selectedIds,
                }),
            });

            if (response.ok) {
                // Clear selection after successful submit
                sessionStorage.removeItem(`fotobook_selection_${gallerySlug}`);
                return true;
            } else {
                const data = await response.json();
                alert(data.message || 'Failed to submit selection.');
                return false;
            }
        } catch (error) {
            console.error('Submit error:', error);
            alert('An error occurred. Please try again.');
            return false;
        }
    }
}

// Initialize on DOM ready
document.addEventListener('DOMContentLoaded', () => {
    const galleryContainer = document.querySelector('.gallery-grid[data-gallery-slug]');
    if (galleryContainer) {
        window.gallerySelection = new GallerySelection(galleryContainer);
    }
});

// Handle submit form
document.addEventListener('DOMContentLoaded', () => {
    const submitForm = document.querySelector('.submit-form');
    const submitModal = document.querySelector('.submit-modal');
    const closeModal = document.querySelector('.submit-modal-close');

    closeModal?.addEventListener('click', () => {
        submitModal?.classList.remove('is-open');
        document.body.style.overflow = '';
    });

    submitForm?.addEventListener('submit', async (e) => {
        e.preventDefault();

        const clientName = submitForm.querySelector('[name="client_name"]').value.trim();
        const clientEmail = submitForm.querySelector('[name="client_email"]').value.trim();

        if (!clientName || !clientEmail) {
            alert('Please fill in all fields.');
            return;
        }

        const submitBtn = submitForm.querySelector('button[type="submit"]');
        submitBtn.disabled = true;
        submitBtn.textContent = 'Submitting...';

        const success = await window.gallerySelection.submitSelection(clientName, clientEmail);

        if (success) {
            submitModal?.classList.remove('is-open');
            document.body.style.overflow = '';

            // Show success message
            const successMessage = document.createElement('div');
            successMessage.className = 'alert alert-success';
            successMessage.innerHTML = `
                <strong>Success!</strong> Your selection has been submitted.
                The photographer will contact you soon.
            `;
            document.querySelector('.public-content')?.prepend(successMessage);

            // Reload page after delay
            setTimeout(() => window.location.reload(), 3000);
        } else {
            submitBtn.disabled = false;
            submitBtn.textContent = 'Submit Selection';
        }
    });
});

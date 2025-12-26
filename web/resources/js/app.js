/**
 * Fotobook - Main Application JavaScript
 */

// Flash message auto-dismiss
document.addEventListener('DOMContentLoaded', () => {
    const alerts = document.querySelectorAll('.alert[data-auto-dismiss]');
    alerts.forEach(alert => {
        const timeout = parseInt(alert.dataset.autoDismiss) || 5000;
        setTimeout(() => {
            alert.style.opacity = '0';
            alert.style.transition = 'opacity 0.3s ease';
            setTimeout(() => alert.remove(), 300);
        }, timeout);
    });
});

// Mobile sidebar toggle
document.addEventListener('DOMContentLoaded', () => {
    const toggle = document.querySelector('.sidebar-toggle');
    const sidebar = document.querySelector('.app-sidebar');
    const overlay = document.querySelector('.sidebar-overlay');

    if (toggle && sidebar) {
        toggle.addEventListener('click', () => {
            sidebar.classList.toggle('is-open');
            overlay?.classList.toggle('is-visible');
        });

        overlay?.addEventListener('click', () => {
            sidebar.classList.remove('is-open');
            overlay.classList.remove('is-visible');
        });
    }
});

// Copy to clipboard utility
window.copyToClipboard = async (text, button) => {
    try {
        await navigator.clipboard.writeText(text);
        const originalText = button.textContent;
        button.textContent = 'Copied!';
        button.classList.add('btn-success');
        setTimeout(() => {
            button.textContent = originalText;
            button.classList.remove('btn-success');
        }, 2000);
    } catch (err) {
        console.error('Failed to copy:', err);
    }
};

// Confirm dialog utility
window.confirmAction = (message, callback) => {
    if (confirm(message)) {
        callback();
    }
};

// Form validation helper
window.validateForm = (form) => {
    const inputs = form.querySelectorAll('[required]');
    let isValid = true;

    inputs.forEach(input => {
        if (!input.value.trim()) {
            isValid = false;
            input.classList.add('is-invalid');
        } else {
            input.classList.remove('is-invalid');
        }
    });

    return isValid;
};

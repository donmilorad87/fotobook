@extends('layouts.public')

@section('title', $gallery->name)

@section('content')
<header class="public-header">
    <div class="public-logo">Fotobook</div>
    <div class="public-gallery-info">
        <h1>{{ $gallery->name }}</h1>
        <p>by {{ $gallery->user->name }} &bull; {{ $gallery->pictures->count() }} photos</p>
    </div>
</header>

<main class="public-content">
    <div class="gallery-grid" data-gallery-slug="{{ $gallery->slug }}">
        @foreach($gallery->pictures as $index => $picture)
            <div class="gallery-item" data-index="{{ $index }}" data-filename="{{ $picture->original_filename }}" data-google-image-id="{{ $picture->file_id }}">
                <img src="/images/placeholder.svg" alt="{{ $picture->original_filename }}" class="gallery-item-image" data-google-image-id="{{ $picture->file_id }}" loading="lazy">
                <div class="gallery-item-checkbox" data-picture-id="{{ $picture->id }}">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                    </svg>
                </div>
                <div class="gallery-item-index">{{ $index + 1 }}</div>
            </div>
        @endforeach
    </div>
</main>

<div class="selection-bar">
    <div class="selection-count">
        <span>0</span> photos selected
    </div>
    <div class="selection-actions">
        <button type="button" class="btn btn-secondary selection-clear">Clear Selection</button>
        <button type="button" class="btn btn-primary selection-submit">Submit Selection</button>
    </div>
</div>

<!-- Submit Modal -->
<div class="submit-modal" style="display: none; position: fixed; inset: 0; z-index: 1000; background: rgba(0,0,0,0.5);">
    <div style="position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); background: white; border-radius: 12px; padding: 32px; width: 100%; max-width: 400px;">
        <button type="button" class="submit-modal-close" style="position: absolute; top: 16px; right: 16px; background: none; border: none; cursor: pointer;">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" style="width: 24px; height: 24px;">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
        </button>

        <h2 style="margin-bottom: 8px;">Submit Your Selection</h2>
        <p style="color: #64748b; margin-bottom: 24px;">Enter your details to complete your photo selection.</p>

        <form class="submit-form">
            <div class="form-group">
                <label for="client_name" class="form-label">Your Name</label>
                <input type="text" name="client_name" id="client_name" class="form-input" required>
            </div>
            <div class="form-group">
                <label for="client_email" class="form-label">Your Email</label>
                <input type="email" name="client_email" id="client_email" class="form-input" required>
            </div>
            <button type="submit" class="btn btn-primary" style="width: 100%;">Submit Selection</button>
        </form>
    </div>
</div>

<style>
    .submit-modal.is-open {
        display: block !important;
    }
</style>
@endsection

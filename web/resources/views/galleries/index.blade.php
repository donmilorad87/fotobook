@extends('layouts.app')

@section('title', 'Galleries')
@section('page-title', 'Galleries')

@section('content')
<div class="page-header">
    <h1 class="page-title">Your Galleries</h1>
    <div class="page-actions">
        <a href="{{ route('download') }}" class="btn btn-primary">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" style="width: 18px; height: 18px; margin-right: 6px;">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
            </svg>
            Upload New Gallery
        </a>
    </div>
</div>

@if($galleries->isEmpty())
    <div class="empty-state">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1">
            <path stroke-linecap="round" stroke-linejoin="round" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
        </svg>
        <h3>No galleries yet</h3>
        <p>Upload your first gallery using the desktop app.</p>
        <a href="{{ route('download') }}" class="btn btn-primary">Download Desktop App</a>
    </div>
@else
    <div class="galleries-grid">
        @foreach($galleries as $gallery)
            <div class="gallery-card">
                <div class="gallery-card-image">
                    @if($gallery->cover_file_id)
                        <img src="/images/placeholder.svg" alt="{{ $gallery->name }}" class="gallery-item-image" data-google-image-id="{{ $gallery->cover_file_id }}">
                    @else
                        <div style="display: flex; align-items: center; justify-content: center; height: 100%; background: #f1f5f9;">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1" style="width: 48px; height: 48px; color: #cbd5e1;">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                            </svg>
                        </div>
                    @endif
                </div>
                <div class="gallery-card-body">
                    <h3 class="gallery-card-title">{{ $gallery->name }}</h3>
                    <div class="gallery-card-meta">
                        <span>{{ $gallery->pictures_count }} photos</span>
                        <span>{{ $gallery->orders_count }} orders</span>
                    </div>
                </div>
                <div class="gallery-card-actions">
                    <a href="{{ $gallery->public_url }}" target="_blank" class="btn btn-sm btn-secondary">Share</a>
                    <a href="{{ route('galleries.show', $gallery) }}" class="btn btn-sm btn-primary">Manage</a>
                </div>
            </div>
        @endforeach
    </div>

    <div class="mt-6">
        {{ $galleries->links() }}
    </div>
@endif
@endsection

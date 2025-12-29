@extends('layouts.app')

@section('title', $gallery->name)
@section('page-title', 'Gallery Details')

@section('content')
<div class="gallery-detail-header">
    <div class="gallery-detail-info">
        <h1>{{ $gallery->name }}</h1>
        <div class="gallery-detail-meta">
            <span>
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" style="width: 16px; height: 16px;">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
                {{ $gallery->pictures->count() }} photos
            </span>
            <span>
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" style="width: 16px; height: 16px;">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                </svg>
                {{ $gallery->orders->count() }} orders
            </span>
            <span>
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" style="width: 16px; height: 16px;">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
                {{ $gallery->created_at->format('M j, Y') }}
            </span>
        </div>
    </div>
    <div class="gallery-detail-actions">
        <a href="{{ $gallery->public_url }}" target="_blank" class="btn btn-secondary">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" style="width: 16px; height: 16px; margin-right: 6px;">
                <path stroke-linecap="round" stroke-linejoin="round" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
            </svg>
            Open Gallery
        </a>
        <form action="{{ route('galleries.destroy', $gallery) }}" method="POST" style="display: inline;" onsubmit="return confirm('Are you sure you want to delete this gallery? This cannot be undone.');">
            @csrf
            @method('DELETE')
            <button type="submit" class="btn btn-danger">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" style="width: 16px; height: 16px; margin-right: 6px;">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
                Delete
            </button>
        </form>
    </div>
</div>

<div class="gallery-url-box">
    <div style="flex: 1;">
        <div class="gallery-url-label">Share this link with your clients:</div>
        <div class="gallery-url-input">
            <input type="text" value="{{ $gallery->public_url }}" readonly id="gallery-url">
            <button type="button" class="btn btn-primary" onclick="copyToClipboard('{{ $gallery->public_url }}', this)">
                Copy Link
            </button>
        </div>
    </div>
</div>

@if($gallery->pictures->isNotEmpty())
    <div class="card">
        <div class="card-header">
            <h3 style="margin: 0;">Photos ({{ $gallery->pictures->count() }})</h3>
        </div>
        <div class="card-body">
            <div class="gallery-grid" style="grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 12px;">
                @foreach($gallery->pictures as $picture)
                    <div class="gallery-item" style="aspect-ratio: 1; border-radius: 8px; overflow: hidden; background: #f1f5f9;">
                        <img src="/images/placeholder.svg" alt="{{ $picture->original_filename }}" class="gallery-item-image" data-google-image-id="{{ $picture->file_id }}" loading="lazy">
                    </div>
                @endforeach
            </div>
        </div>
    </div>
@endif

@if($gallery->orders->isNotEmpty())
    <div class="card mt-6">
        <div class="card-header">
            <h3 style="margin: 0;">Orders ({{ $gallery->orders->count() }})</h3>
        </div>
        <div class="card-body" style="padding: 0;">
            <table class="orders-table">
                <thead>
                    <tr>
                        <th>Client</th>
                        <th>Selected Photos</th>
                        <th>Date</th>
                        <th></th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($gallery->orders as $order)
                        <tr>
                            <td>
                                <div class="font-medium">{{ $order->client_name }}</div>
                                <div class="text-sm text-muted">{{ $order->client_email }}</div>
                            </td>
                            <td>{{ $order->selected_count }}</td>
                            <td>{{ $order->created_at->format('M j, Y H:i') }}</td>
                            <td>
                                <a href="{{ route('orders.show', $order) }}" class="btn btn-sm btn-secondary">View</a>
                                <a href="{{ route('orders.export', $order) }}" class="btn btn-sm btn-primary">Export</a>
                            </td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>
@endif
@endsection

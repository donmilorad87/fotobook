@extends('layouts.app')

@section('title', 'Order #' . $order->id)
@section('page-title', 'Order Details')

@section('content')
<div class="page-header">
    <h1 class="page-title">Order #{{ $order->id }}</h1>
    <div class="page-actions">
        <a href="{{ route('orders.export', $order) }}" class="btn btn-primary">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" style="width: 18px; height: 18px; margin-right: 6px;">
                <path stroke-linecap="round" stroke-linejoin="round" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
            </svg>
            Export JSON
        </a>
    </div>
</div>

<div class="order-detail">
    <div class="order-detail-main">
        <div class="order-pictures-header">
            <h2 class="order-pictures-title">Selected Photos ({{ $order->selected_count }})</h2>
        </div>

        <div class="order-pictures-grid">
            @foreach($order->selectedPictures as $picture)
                <div class="order-picture-item">
                    <img src="" alt="{{ $picture->original_filename }}" class="gallery-item-image" data-google-image-id="{{ $picture->file_id }}" loading="lazy">
                </div>
            @endforeach
        </div>
    </div>

    <div class="order-detail-sidebar">
        <div class="card">
            <div class="card-header">
                <h3 style="margin: 0;">Order Information</h3>
            </div>
            <div class="card-body" style="padding: 0;">
                <div class="order-info-row" style="padding: 12px 16px; border-bottom: 1px solid #e2e8f0;">
                    <span class="order-info-label">Client Name</span>
                    <span class="order-info-value">{{ $order->client_name }}</span>
                </div>
                <div class="order-info-row" style="padding: 12px 16px; border-bottom: 1px solid #e2e8f0;">
                    <span class="order-info-label">Client Email</span>
                    <span class="order-info-value">{{ $order->client_email }}</span>
                </div>
                <div class="order-info-row" style="padding: 12px 16px; border-bottom: 1px solid #e2e8f0;">
                    <span class="order-info-label">Gallery</span>
                    <span class="order-info-value">
                        <a href="{{ route('galleries.show', $order->gallery) }}">{{ $order->gallery->name }}</a>
                    </span>
                </div>
                <div class="order-info-row" style="padding: 12px 16px; border-bottom: 1px solid #e2e8f0;">
                    <span class="order-info-label">Selected Photos</span>
                    <span class="order-info-value">{{ $order->selected_count }}</span>
                </div>
                <div class="order-info-row" style="padding: 12px 16px;">
                    <span class="order-info-label">Submitted</span>
                    <span class="order-info-value">{{ $order->created_at->format('M j, Y H:i') }}</span>
                </div>
            </div>
        </div>

        <div class="card mt-4">
            <div class="card-header">
                <h3 style="margin: 0;">Selected Filenames</h3>
            </div>
            <div class="card-body">
                <ul style="font-size: 0.875rem; color: #64748b;">
                    @foreach($order->selectedPictures as $picture)
                        <li style="padding: 4px 0;">{{ $picture->original_filename }}</li>
                    @endforeach
                </ul>
            </div>
        </div>
    </div>
</div>
@endsection

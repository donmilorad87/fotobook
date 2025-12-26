@extends('layouts.app')

@section('title', 'Dashboard')
@section('page-title', 'Dashboard')

@section('content')
<div class="dashboard-stats">
    <div class="stat-card">
        <div class="stat-card-icon stat-card-icon--primary">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
        </div>
        <div class="stat-card-value">{{ $galleryCount }}</div>
        <div class="stat-card-label">Galleries</div>
    </div>

    <div class="stat-card">
        <div class="stat-card-icon stat-card-icon--success">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
            </svg>
        </div>
        <div class="stat-card-value">{{ $orderCount }}</div>
        <div class="stat-card-label">Orders</div>
    </div>

    <div class="stat-card">
        <div class="stat-card-icon stat-card-icon--warning">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
        </div>
        <div class="stat-card-value">{{ $pictureCount }}</div>
        <div class="stat-card-label">Photos</div>
    </div>
</div>

<div class="dashboard-section">
    <div class="dashboard-section-header">
        <h2 class="dashboard-section-title">Recent Galleries</h2>
        <a href="{{ route('galleries.index') }}" class="btn btn-secondary btn-sm">View All</a>
    </div>

    @if($recentGalleries->isEmpty())
        <div class="empty-state">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1">
                <path stroke-linecap="round" stroke-linejoin="round" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
            <h3>No galleries yet</h3>
            <p>Upload your first gallery using the desktop app.</p>
            <a href="{{ route('download') }}" class="btn btn-primary">Download Desktop App</a>
        </div>
    @else
        <div class="galleries-grid" style="grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));">
            @foreach($recentGalleries as $gallery)
                <div class="gallery-card">
                    <div class="gallery-card-image">
                        @if($gallery->cover_image)
                            <img src="{{ $gallery->cover_image }}" alt="{{ $gallery->name }}">
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
                        <a href="{{ $gallery->public_url }}" target="_blank" class="btn btn-sm btn-secondary">View Gallery</a>
                        <a href="{{ route('galleries.show', $gallery) }}" class="btn btn-sm btn-primary">Manage</a>
                    </div>
                </div>
            @endforeach
        </div>
    @endif
</div>

@if($recentOrders->isNotEmpty())
<div class="dashboard-section">
    <div class="dashboard-section-header">
        <h2 class="dashboard-section-title">Recent Orders</h2>
        <a href="{{ route('orders.index') }}" class="btn btn-secondary btn-sm">View All</a>
    </div>

    <div class="recent-orders-table">
        <table>
            <thead>
                <tr>
                    <th>Client</th>
                    <th>Gallery</th>
                    <th>Photos</th>
                    <th>Date</th>
                    <th></th>
                </tr>
            </thead>
            <tbody>
                @foreach($recentOrders as $order)
                    <tr>
                        <td>
                            <div class="font-medium">{{ $order->client_name }}</div>
                            <div class="text-sm text-muted">{{ $order->client_email }}</div>
                        </td>
                        <td>{{ $order->gallery->name }}</td>
                        <td>{{ $order->selected_count }}</td>
                        <td>{{ $order->created_at->format('M j, Y') }}</td>
                        <td>
                            <a href="{{ route('orders.show', $order) }}" class="btn btn-sm btn-secondary">View</a>
                        </td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    </div>
</div>
@endif
@endsection

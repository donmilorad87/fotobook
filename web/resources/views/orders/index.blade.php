@extends('layouts.app')

@section('title', 'Orders')
@section('page-title', 'Orders')

@section('content')
<div class="page-header">
    <h1 class="page-title">Client Orders</h1>
</div>

@if($orders->isEmpty())
    <div class="empty-state">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1">
            <path stroke-linecap="round" stroke-linejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
        </svg>
        <h3>No orders yet</h3>
        <p>When clients select photos from your galleries, their orders will appear here.</p>
    </div>
@else
    <div class="orders-list">
        <table class="orders-table">
            <thead>
                <tr>
                    <th>Client</th>
                    <th>Gallery</th>
                    <th>Selected Photos</th>
                    <th>Date</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                @foreach($orders as $order)
                    <tr>
                        <td>
                            <div class="font-medium">{{ $order->client_name }}</div>
                            <div class="text-sm text-muted">{{ $order->client_email }}</div>
                        </td>
                        <td>
                            <a href="{{ route('galleries.show', $order->gallery) }}">{{ $order->gallery->name }}</a>
                        </td>
                        <td>
                            <span class="badge badge-primary">{{ $order->selected_count }} photos</span>
                        </td>
                        <td>{{ $order->created_at->format('M j, Y H:i') }}</td>
                        <td>
                            <a href="{{ route('orders.show', $order) }}" class="btn btn-sm btn-secondary">View</a>
                            <a href="{{ route('orders.export', $order) }}" class="btn btn-sm btn-primary">Export JSON</a>
                        </td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    </div>

    <div class="mt-6">
        {{ $orders->links() }}
    </div>
@endif
@endsection

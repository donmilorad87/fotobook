<?php

namespace App\Http\Controllers;

use App\Models\Order;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\View;

class OrderController extends Controller
{
    /**
     * List all orders for the authenticated user's galleries.
     */
    public function index(): View
    {
        $orders = Order::whereHas('gallery', function ($query) {
            $query->where('user_id', Auth::id());
        })
            ->with('gallery')
            ->latest()
            ->paginate(15);

        return view('orders.index', [
            'orders' => $orders,
        ]);
    }

    /**
     * Show a single order.
     */
    public function show(Order $order): View
    {
        // Ensure user owns the gallery this order belongs to
        $this->authorize('view', $order);

        $order->load(['gallery', 'gallery.pictures']);

        return view('orders.show', [
            'order' => $order,
        ]);
    }

    /**
     * Export order as JSON file for desktop app.
     */
    public function exportJson(Order $order): Response
    {
        // Ensure user owns the gallery this order belongs to
        $this->authorize('view', $order);

        $filename = 'order-' . $order->id . '-' . now()->format('Y-m-d') . '.json';

        return response($order->toExportJson(), 200, [
            'Content-Type' => 'application/json',
            'Content-Disposition' => 'attachment; filename="' . $filename . '"',
        ]);
    }
}

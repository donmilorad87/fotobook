<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OrderController extends Controller
{
    /**
     * List orders for the authenticated user's galleries.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $orders = Order::whereHas('gallery', function ($query) use ($user) {
            $query->where('user_id', $user->id);
        })
            ->with('gallery')
            ->latest()
            ->get();

        return response()->json([
            'orders' => $orders->map(fn ($order) => $order->toExportArray())->toArray(),
        ]);
    }
}

<?php

namespace App\Http\Controllers;

use App\Models\Order;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\View;

class DashboardController extends Controller
{
    /**
     * Show the dashboard.
     */
    public function index(): View
    {
        $user = Auth::user();

        $galleryCount = $user->galleries()->count();

        $orderCount = Order::whereHas('gallery', function ($query) use ($user) {
            $query->where('user_id', $user->id);
        })->count();

        $pictureCount = $user->galleries()
            ->withCount('pictures')
            ->get()
            ->sum('pictures_count');

        $recentOrders = Order::whereHas('gallery', function ($query) use ($user) {
            $query->where('user_id', $user->id);
        })
            ->with('gallery')
            ->latest()
            ->limit(5)
            ->get();

        $recentGalleries = $user->galleries()
            ->withCount(['pictures', 'orders'])
            ->latest()
            ->limit(4)
            ->get();

        return view('dashboard.index', [
            'galleryCount' => $galleryCount,
            'orderCount' => $orderCount,
            'pictureCount' => $pictureCount,
            'recentOrders' => $recentOrders,
            'recentGalleries' => $recentGalleries,
        ]);
    }
}

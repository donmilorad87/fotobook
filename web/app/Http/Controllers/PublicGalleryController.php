<?php

namespace App\Http\Controllers;

use App\Models\Gallery;
use App\Models\Order;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class PublicGalleryController extends Controller
{
    /**
     * Show the public gallery page for clients.
     */
    public function show(string $slug): View
    {
        $gallery = Gallery::where('slug', $slug)
            ->with(['pictures', 'user'])
            ->firstOrFail();

        return view('public.gallery', [
            'gallery' => $gallery,
        ]);
    }

    /**
     * Handle client photo selection submission.
     */
    public function submitSelection(Request $request, string $slug): JsonResponse
    {
        $gallery = Gallery::where('slug', $slug)->firstOrFail();

        $validated = $request->validate([
            'client_name' => ['required', 'string', 'max:255'],
            'client_email' => ['required', 'email', 'max:255'],
            'selected_picture_ids' => ['required', 'array', 'min:1'],
            'selected_picture_ids.*' => ['integer', 'exists:pictures,id'],
        ]);

        // Verify all selected pictures belong to this gallery
        $validPictureIds = $gallery->pictures()
            ->whereIn('id', $validated['selected_picture_ids'])
            ->pluck('id')
            ->toArray();

        if (count($validPictureIds) !== count($validated['selected_picture_ids'])) {
            return response()->json([
                'message' => 'Some selected pictures do not belong to this gallery.',
            ], 422);
        }

        // Create the order
        $order = Order::create([
            'gallery_id' => $gallery->id,
            'client_name' => $validated['client_name'],
            'client_email' => $validated['client_email'],
            'selected_picture_ids' => $validPictureIds,
        ]);

        return response()->json([
            'message' => 'Selection submitted successfully.',
            'order_id' => $order->id,
        ]);
    }
}

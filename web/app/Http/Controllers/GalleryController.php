<?php

namespace App\Http\Controllers;

use App\Models\Gallery;
use App\Services\GalleryService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\View;

class GalleryController extends Controller
{
    public function __construct(
        private GalleryService $galleryService
    ) {}
    /**
     * List all galleries for the authenticated user.
     */
    public function index(): View
    {
        $galleries = Auth::user()
            ->galleries()
            ->withCount(['pictures', 'orders'])
            ->latest()
            ->paginate(12);

        return view('galleries.index', [
            'galleries' => $galleries,
        ]);
    }

    /**
     * Show a single gallery.
     */
    public function show(Gallery $gallery): View
    {
        // Ensure user owns this gallery
        $this->authorize('view', $gallery);

        $gallery->load(['pictures', 'orders']);

        return view('galleries.show', [
            'gallery' => $gallery,
        ]);
    }

    /**
     * Delete a gallery.
     */
    public function destroy(Gallery $gallery): RedirectResponse
    {
        // Ensure user owns this gallery
        $this->authorize('delete', $gallery);

        $galleryName = $gallery->name;

        // Delete from database AND Google Drive, get invalidated cache IDs
        $invalidatedIds = $this->galleryService->deleteGallery($gallery, Auth::user());

        return redirect()->route('galleries.index')
            ->with('success', "Gallery \"{$galleryName}\" deleted successfully.")
            ->with('invalidate_cache', $invalidatedIds);
    }
}

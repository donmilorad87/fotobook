<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Gallery;
use App\Models\Picture;
use App\Services\GoogleDriveService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GalleryController extends Controller
{
    /**
     * Get all galleries for the authenticated user.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $galleries = $user->galleries()
            ->select(['id', 'name', 'slug', 'google_drive_folder_id', 'created_at'])
            ->withCount('pictures')
            ->get();

        return response()->json([
            'galleries' => $galleries->map(fn ($g) => [
                'id' => $g->id,
                'name' => $g->name,
                'slug' => $g->slug,
                'google_drive_folder_id' => $g->google_drive_folder_id,
                'picture_count' => $g->pictures_count,
                'created_at' => $g->created_at->toIso8601String(),
            ])->toArray(),
        ]);
    }

    /**
     * Create a new gallery (without images).
     * Returns gallery_id and folder_id for subsequent image uploads.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'total_images' => ['required', 'integer', 'min:1'],
        ]);

        $user = $request->user();

        try {
            // Create gallery record
            $gallery = Gallery::create([
                'user_id' => $user->id,
                'name' => $validated['name'],
            ]);

            // Create Google Drive folder
            $driveService = new GoogleDriveService($user);
            $folderId = $driveService->createGalleryFolder($gallery->name);

            $gallery->update(['google_drive_folder_id' => $folderId]);

            return response()->json([
                'gallery_id' => $gallery->id,
                'folder_id' => $folderId,
                'slug' => $gallery->slug,
                'total_images' => $validated['total_images'],
                'uploaded' => 0,
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to create gallery',
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Upload a single image to an existing gallery.
     * Returns progress information.
     */
    public function uploadImage(Request $request, Gallery $gallery): JsonResponse
    {
        $user = $request->user();

        // Verify ownership
        if ($gallery->user_id !== $user->id) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'image' => ['required', 'file', 'image', 'max:20480'],
            'total_images' => ['required', 'integer', 'min:1'],
            'image_index' => ['required', 'integer', 'min:0'],
        ]);

        try {
            $file = $request->file('image');
            $filename = $file->getClientOriginalName();
            $fileData = $file->get();

            // Upload to Google Drive
            $driveService = new GoogleDriveService($user);
            $uploadResult = $driveService->uploadFile(
                base64_encode($fileData),
                $filename,
                $gallery->google_drive_folder_id
            );

            // Create picture record
            $picture = Picture::create([
                'gallery_id' => $gallery->id,
                'original_filename' => $filename,
                'google_drive_url' => $uploadResult['url'],
                'google_drive_file_id' => $uploadResult['file_id'],
                'order_index' => $validated['image_index'],
            ]);

            $uploaded = $gallery->pictures()->count();
            $total = $validated['total_images'];

            return response()->json([
                'success' => true,
                'picture_id' => $picture->id,
                'filename' => $filename,
                'uploaded' => $uploaded,
                'total' => $total,
                'progress' => "{$uploaded} of {$total}",
                'completed' => $uploaded >= $total,
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to upload image',
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Finalize gallery upload and get full gallery info.
     */
    public function finalize(Request $request, Gallery $gallery): JsonResponse
    {
        $user = $request->user();

        if ($gallery->user_id !== $user->id) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $gallery->load('pictures');

        return response()->json([
            'gallery_id' => $gallery->id,
            'slug' => $gallery->slug,
            'public_url' => $gallery->public_url,
            'picture_count' => $gallery->pictures->count(),
            'pictures' => $gallery->pictures->map(fn ($p) => [
                'id' => $p->id,
                'filename' => $p->original_filename,
            ])->toArray(),
        ]);
    }
}

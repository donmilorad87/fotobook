<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Gallery;
use App\Models\Picture;
use App\Services\GoogleDriveService;
use App\Services\RabbitMQService;
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
            ->select(['id', 'name', 'slug', 'google_drive_folder_id', 'local_gallery_id', 'created_at'])
            ->withCount('pictures')
            ->get();

        return response()->json([
            'galleries' => $galleries->map(fn ($g) => [
                'id' => $g->id,
                'name' => $g->name,
                'slug' => $g->slug,
                'google_drive_folder_id' => $g->google_drive_folder_id,
                'local_gallery_id' => $g->local_gallery_id,
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
            'local_gallery_id' => ['nullable', 'integer'],
        ]);

        $user = $request->user();

        try {
            // Create gallery record
            $gallery = Gallery::create([
                'user_id' => $user->id,
                'name' => $validated['name'],
                'local_gallery_id' => $validated['local_gallery_id'] ?? null,
            ]);

            // Create Google Drive folder
            $driveService = new GoogleDriveService($user);
            $folderId = $driveService->createGalleryFolder($gallery->name);

            $gallery->update(['google_drive_folder_id' => $folderId]);

            return response()->json([
                'gallery_id' => $gallery->id,
                'folder_id' => $folderId,
                'slug' => $gallery->slug,
                'local_gallery_id' => $gallery->local_gallery_id,
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
     * Uses RabbitMQ for async processing.
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
            $fileData = base64_encode($file->get());

            // Send upload request via RabbitMQ
            $rabbitMQ = new RabbitMQService();
            $result = $rabbitMQ->rpcImageUpload([
                'user_id' => $user->id,
                'gallery_id' => $gallery->id,
                'filename' => $filename,
                'file_data' => $fileData,
                'folder_id' => $gallery->google_drive_folder_id,
                'image_index' => $validated['image_index'],
            ]);

            if ($result === null) {
                return response()->json([
                    'error' => 'Upload timeout',
                    'message' => 'Image upload request timed out',
                ], 504);
            }

            if (!($result['success'] ?? false)) {
                return response()->json([
                    'error' => 'Failed to upload image',
                    'message' => $result['error'] ?? 'Unknown error',
                ], 500);
            }

            $uploaded = $gallery->pictures()->count();
            $total = $validated['total_images'];

            return response()->json([
                'success' => true,
                'picture_id' => $result['picture_id'],
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
            'local_gallery_id' => $gallery->local_gallery_id,
            'public_url' => $gallery->public_url,
            'picture_count' => $gallery->pictures->count(),
            'pictures' => $gallery->pictures->map(fn ($p) => [
                'id' => $p->id,
                'filename' => $p->original_filename,
            ])->toArray(),
        ]);
    }
}

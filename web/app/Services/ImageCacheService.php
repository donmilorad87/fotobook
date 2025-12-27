<?php

namespace App\Services;

use App\Models\Gallery;
use Illuminate\Support\Facades\Cache;

class ImageCacheService
{
    /**
     * Invalidate Redis cache for all images in a gallery.
     * Returns array of invalidated image IDs for frontend cache invalidation.
     */
    public function invalidateGalleryCache(Gallery $gallery): array
    {
        $imageIds = [];

        $gallery->loadMissing('pictures');

        foreach ($gallery->pictures as $picture) {
            $fileId = $picture->file_id;

            if ($fileId === null) {
                continue;
            }

            $imageIds[] = $fileId;

            $cacheKey = "gdrive_image_{$fileId}";
            Cache::forget($cacheKey);
        }

        return $imageIds;
    }

    /**
     * Invalidate Redis cache for a single image.
     */
    public function invalidateImageCache(string $fileId): void
    {
        $cacheKey = "gdrive_image_{$fileId}";
        Cache::forget($cacheKey);
    }

    /**
     * Invalidate Redis cache for multiple images.
     */
    public function invalidateMultipleImageCache(array $fileIds): void
    {
        $count = count($fileIds);

        for ($i = 0; $i < $count; $i++) {
            $cacheKey = "gdrive_image_{$fileIds[$i]}";
            Cache::forget($cacheKey);
        }
    }
}

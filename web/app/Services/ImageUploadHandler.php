<?php

namespace App\Services;

use App\Models\Gallery;
use App\Models\Picture;
use App\Models\User;
use Illuminate\Support\Facades\Log;

class ImageUploadHandler
{
    /**
     * Upload an image to Google Drive and create picture record.
     *
     * @param array $payload {
     *     user_id: int,
     *     gallery_id: int,
     *     filename: string,
     *     file_data: string (base64),
     *     folder_id: string,
     *     image_index: int
     * }
     * @return array{success: bool, picture_id?: int, filename?: string, error?: string}
     */
    public function handle(array $payload): array
    {
        $userId = $payload['user_id'] ?? null;
        $galleryId = $payload['gallery_id'] ?? null;
        $filename = $payload['filename'] ?? null;
        $fileData = $payload['file_data'] ?? null;
        $folderId = $payload['folder_id'] ?? null;
        $imageIndex = $payload['image_index'] ?? 0;

        if ($userId === null || $galleryId === null || $filename === null || $fileData === null || $folderId === null) {
            return [
                'success' => false,
                'error' => 'Missing required fields',
            ];
        }

        $user = User::find($userId);
        if ($user === null) {
            return [
                'success' => false,
                'error' => 'User not found',
            ];
        }

        $gallery = Gallery::find($galleryId);
        if ($gallery === null) {
            return [
                'success' => false,
                'error' => 'Gallery not found',
            ];
        }

        if ($gallery->user_id !== $user->id) {
            return [
                'success' => false,
                'error' => 'Unauthorized',
            ];
        }

        try {
            $driveService = new GoogleDriveService($user);
            $uploadResult = $driveService->uploadFile(
                $fileData,
                $filename,
                $folderId
            );

            $picture = Picture::create([
                'gallery_id' => $gallery->id,
                'original_filename' => $filename,
                'google_drive_url' => $uploadResult['url'],
                'google_drive_file_id' => $uploadResult['file_id'],
                'order_index' => $imageIndex,
            ]);

            Log::info("Image uploaded via RabbitMQ: {$filename} -> {$uploadResult['file_id']}");

            return [
                'success' => true,
                'picture_id' => $picture->id,
                'filename' => $filename,
                'file_id' => $uploadResult['file_id'],
            ];
        } catch (\Exception $e) {
            Log::error("Image upload failed: {$e->getMessage()}");

            return [
                'success' => false,
                'error' => $e->getMessage(),
            ];
        }
    }
}

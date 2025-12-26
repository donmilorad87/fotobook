<?php

namespace App\Services;

use App\Models\Gallery;
use App\Models\Picture;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;

class GalleryService
{
    /**
     * Create a gallery with images uploaded from desktop app.
     *
     * @param User $user The photographer
     * @param string $name Gallery name
     * @param array<UploadedFile> $images Array of uploaded files
     * @return Gallery
     */
    public function createGalleryWithImages(User $user, string $name, array $images): Gallery
    {
        return DB::transaction(function () use ($user, $name, $images) {
            // Create the gallery
            $gallery = Gallery::create([
                'user_id' => $user->id,
                'name' => $name,
            ]);

            // Initialize Google Drive service with user's OAuth tokens
            $driveService = new GoogleDriveService($user);

            // Create gallery folder inside fotobook root folder
            $folderId = $driveService->createGalleryFolder($gallery->name);

            // Store folder ID in gallery
            $gallery->update(['google_drive_folder_id' => $folderId]);

            // Process each image
            foreach ($images as $index => $file) {
                /** @var UploadedFile $file */
                $filename = $file->getClientOriginalName();
                $fileData = $file->get();

                // Upload to Google Drive (automatically made public)
                $uploadResult = $driveService->uploadFile(
                    base64_encode($fileData),
                    $filename,
                    $folderId
                );

                // Create picture record
                Picture::create([
                    'gallery_id' => $gallery->id,
                    'original_filename' => $filename,
                    'google_drive_url' => $uploadResult['url'],
                    'google_drive_file_id' => $uploadResult['file_id'],
                    'order_index' => $index,
                ]);
            }

            // Reload with pictures
            $gallery->load('pictures');

            return $gallery;
        });
    }

    /**
     * Delete a gallery from database AND Google Drive.
     * The Flutter app will sync and remove local copies when it detects
     * the gallery no longer exists on the server.
     *
     * @param Gallery $gallery
     * @param User $user The gallery owner (for Google Drive access)
     * @return void
     */
    public function deleteGallery(Gallery $gallery, User $user): void
    {
        // Delete folder from Google Drive (includes all files)
        if ($gallery->google_drive_folder_id !== null && $user->isGoogleConnected()) {
            try {
                $driveService = new GoogleDriveService($user);
                $driveService->deleteFolder($gallery->google_drive_folder_id);
            } catch (\Exception $e) {
                // Log error but continue with local deletion
                \Log::warning('Failed to delete Google Drive folder: ' . $e->getMessage());
            }
        }

        // Delete from database (cascades to pictures and orders)
        $gallery->delete();
    }
}

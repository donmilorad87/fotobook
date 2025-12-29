<?php

namespace App\Services;

use App\Models\User;
use Google\Client as GoogleClient;
use Google\Service\Drive as GoogleDrive;
use Google\Service\Drive\DriveFile;
use Google\Service\Drive\Permission;

/**
 * Google Drive Service using user OAuth tokens.
 *
 * Each user uploads files to their own Google Drive.
 */
class GoogleDriveService
{
    private GoogleClient $client;
    private GoogleDrive $driveService;
    private User $user;
    private const ROOT_FOLDER_NAME = 'fotobook';

    public function __construct(User $user)
    {
        if (!$user->isGoogleConnected()) {
            throw new \RuntimeException('User has not connected Google account');
        }

        $this->user = $user;
        $this->client = $this->createGoogleClient();
        $this->driveService = new GoogleDrive($this->client);
    }

    private function createGoogleClient(): GoogleClient
    {
        $client = new GoogleClient();
        $client->setClientId(config('services.google.client_id'));
        $client->setClientSecret(config('services.google.client_secret'));
        $client->addScope(GoogleDrive::DRIVE);

        $client->setAccessToken([
            'access_token' => $this->user->google_access_token,
            'refresh_token' => $this->user->google_refresh_token,
            'expires_in' => $this->user->google_token_expires_at
                ? $this->user->google_token_expires_at->diffInSeconds(now())
                : 0,
        ]);

        if ($client->isAccessTokenExpired()) {
            $this->refreshAccessToken($client);
        }

        return $client;
    }

    private function refreshAccessToken(GoogleClient $client): void
    {
        if (empty($this->user->google_refresh_token)) {
            throw new \RuntimeException('No refresh token available. User must reconnect Google account.');
        }

        $client->fetchAccessTokenWithRefreshToken($this->user->google_refresh_token);
        $newToken = $client->getAccessToken();

        $this->user->update([
            'google_access_token' => $newToken['access_token'],
            'google_token_expires_at' => now()->addSeconds($newToken['expires_in']),
        ]);
    }

    /**
     * Get or create the root "fotobook" folder in user's Drive.
     */
    public function getOrCreateRootFolder(): string
    {
        $existingFolder = $this->findFolderByName(self::ROOT_FOLDER_NAME);

        if ($existingFolder !== null) {
            return $existingFolder;
        }

        return $this->createFolder(self::ROOT_FOLDER_NAME);
    }

    /**
     * Create a gallery folder inside the fotobook root folder.
     */
    public function createGalleryFolder(string $galleryName): string
    {
        $rootFolderId = $this->getOrCreateRootFolder();

        return $this->createFolder($galleryName, $rootFolderId);
    }

    /**
     * Find a folder by name in root or parent folder.
     */
    private function findFolderByName(string $name, ?string $parentId = null): ?string
    {
        $query = sprintf(
            "name = '%s' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
            addslashes($name)
        );

        if ($parentId !== null) {
            $query .= sprintf(" and '%s' in parents", $parentId);
        }

        $results = $this->driveService->files->listFiles([
            'q' => $query,
            'spaces' => 'drive',
            'fields' => 'files(id, name)',
            'pageSize' => 1,
        ]);

        $files = $results->getFiles();

        if (count($files) > 0) {
            return $files[0]->getId();
        }

        return null;
    }

    /**
     * Create a folder in Google Drive.
     */
    public function createFolder(string $name, ?string $parentId = null): string
    {
        $fileMetadata = new DriveFile([
            'name' => $name,
            'mimeType' => 'application/vnd.google-apps.folder',
        ]);

        if ($parentId !== null) {
            $fileMetadata->setParents([$parentId]);
        }

        $folder = $this->driveService->files->create($fileMetadata, [
            'fields' => 'id',
        ]);

        return $folder->getId();
    }

    /**
     * Upload a file to Google Drive.
     *
     * @param string $fileData Base64 encoded file data or file path
     * @param string $filename Original filename
     * @param string|null $folderId Parent folder ID
     * @return array{file_id: string, url: string}
     */
    public function uploadFile(string $fileData, string $filename, ?string $folderId = null): array
    {
        $isBase64 = !file_exists($fileData);

        if ($isBase64) {
            $content = base64_decode($fileData);
        } else {
            $content = file_get_contents($fileData);
        }

        if ($content === false) {
            throw new \RuntimeException('Failed to read file data');
        }

        $mimeType = $this->getMimeType($filename);

        $fileMetadata = new DriveFile([
            'name' => $filename,
        ]);

        if ($folderId !== null) {
            $fileMetadata->setParents([$folderId]);
        }

        $file = $this->driveService->files->create($fileMetadata, [
            'data' => $content,
            'mimeType' => $mimeType,
            'uploadType' => 'multipart',
            'fields' => 'id, webViewLink, webContentLink',
        ]);

        // Make file publicly viewable
        $this->makeFilePublic($file->getId());

        return [
            'file_id' => $file->getId(),
            'url' => 'https://drive.usercontent.google.com/download?id=' . $file->getId() . '&export=view&authuser=0',
        ];
    }

    /**
     * Make a file publicly accessible.
     */
    public function makeFilePublic(string $fileId): bool
    {
        $permission = new Permission([
            'type' => 'anyone',
            'role' => 'reader',
        ]);

        $this->driveService->permissions->create($fileId, $permission);

        return true;
    }

    /**
     * Delete a file from Google Drive.
     */
    public function deleteFile(string $fileId): bool
    {
        $this->driveService->files->delete($fileId);

        return true;
    }

    /**
     * Delete a folder and all its contents.
     */
    public function deleteFolder(string $folderId): bool
    {
        return $this->deleteFile($folderId);
    }

    /**
     * Get MIME type from filename.
     */
    private function getMimeType(string $filename): string
    {
        $extension = strtolower(pathinfo($filename, PATHINFO_EXTENSION));

        $mimeTypes = [
            'jpg' => 'image/jpeg',
            'jpeg' => 'image/jpeg',
            'png' => 'image/png',
            'gif' => 'image/gif',
            'webp' => 'image/webp',
            'bmp' => 'image/bmp',
            'tiff' => 'image/tiff',
            'tif' => 'image/tiff',
        ];

        return $mimeTypes[$extension] ?? 'application/octet-stream';
    }
}

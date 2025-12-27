<?php

namespace App\Http\Controllers;

use App\Services\RabbitMQService;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class ImageProxyController extends Controller
{
    private RabbitMQService $rabbitMQ;

    public function __construct(RabbitMQService $rabbitMQ)
    {
        $this->rabbitMQ = $rabbitMQ;
    }

    /**
     * Proxy Google Drive images to avoid CORS issues.
     * Uses RabbitMQ RPC pattern for image fetching.
     * Caches images for 1 hour to reduce API calls.
     */
    public function show(string $fileId): Response
    {
        $cacheKey = "gdrive_image_{$fileId}";

        $imageData = Cache::get($cacheKey);

        if ($imageData !== null && isset($imageData['success']) && $imageData['success']) {
            return $this->buildImageResponse($imageData);
        }

        $imageData = $this->fetchViaRabbitMQ($fileId);

        if ($imageData === null || !isset($imageData['success']) || !$imageData['success']) {
            Log::warning("Image fetch failed for: {$fileId}");
            abort(404, 'Image not found');
        }

        Cache::put($cacheKey, $imageData, 31536000); // 1 year

        return $this->buildImageResponse($imageData);
    }

    /**
     * Fetch image via RabbitMQ RPC.
     */
    private function fetchViaRabbitMQ(string $fileId): ?array
    {
        return $this->rabbitMQ->rpcImageFetch($fileId);
    }

    /**
     * Build the HTTP response for an image.
     */
    private function buildImageResponse(array $imageData): Response
    {
        return response(base64_decode($imageData['body']))
            ->header('Content-Type', $imageData['content_type'])
            ->header('Cache-Control', 'public, max-age=86400');
    }
}
